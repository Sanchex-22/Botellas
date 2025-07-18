// for_yous_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:botellas/models/firestore_models.dart'; // Asegúrate de que esta ruta sea correcta

class ForYousScreen extends StatefulWidget {
  const ForYousScreen({super.key});

  @override
  State<ForYousScreen> createState() => _ForYousScreenState();
}

class _ForYousScreenState extends State<ForYousScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PageController _pageController = PageController();

  List<Botella> _bottles = [];
  List<OceanoMetadata> _oceans = [];
  String? _selectedFilterOceanId; // 'Todos' o un ID de océano
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  Set<String> _seenBottleIds =
      {}; // IDs de botellas vistas por el usuario actual
  bool _hasMoreBottles =
      true; // Nuevo: Para saber si hay más botellas disponibles

  DocumentSnapshot? _lastDocument; // Para paginación

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Carga inicial de datos (vistas y océanos)
    _pageController.addListener(() {
      // Cargar más botellas cuando el usuario llega al final de la lista actual
      // Solo cargar más si no está cargando y si hay más botellas disponibles
      if (_pageController.position.pixels ==
              _pageController.position.maxScrollExtent &&
          !_isLoadingMore &&
          _hasMoreBottles) {
        _loadMoreBottles();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Carga los datos iniciales: botellas vistas por el usuario y metadatos de los océanos.
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null; // Reiniciar mensaje de error en carga inicial
      _hasMoreBottles =
          true; // Reiniciar estado de "hay más botellas" al iniciar una nueva carga
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'Usuario no autenticado.';
        if (mounted) {
          // Asegúrate de que el widget sigue montado antes de llamar a setState
          setState(() {
            _isLoadingInitial = false;
          });
        }
        debugPrint('ForYousScreen: Usuario es null, no se puede cargar datos.');
        return;
      }
      debugPrint(
          'ForYousScreen: Usuario autenticado con UID: ${user.uid}'); // Para depuración

      // Cargar botellas vistas por el usuario actual
      // Acceso a la colección 'usuarios' y su subcolección 'seenBottles'
      final seenSnapshot = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('seenBottles')
          .get();
      _seenBottleIds = seenSnapshot.docs.map((doc) => doc.id).toSet();
      debugPrint('Cargadas ${_seenBottleIds.length} botellas vistas.');

      // Cargar metadatos de los océanos para el filtro
      // Acceso a la colección 'metadata_oceanos'
      final oceansSnapshot =
          await _firestore.collection('metadata_oceanos').get();
      _oceans = oceansSnapshot.docs
          .map((doc) => OceanoMetadata.fromFirestore(doc))
          .toList();
      _oceans.insert(
          0,
          OceanoMetadata(
              id: 'Todos',
              name: 'Todos',
              isPremium: false,
              emojiIcon: '🌍')); // Añadir opción 'Todos'
      _selectedFilterOceanId = 'Todos'; // Por defecto, seleccionar 'Todos'

      await _fetchBottles(); // Obtener el conjunto inicial de botellas
    } catch (e) {
      _errorMessage = 'Error al cargar datos iniciales: $e';
      print('Error al cargar datos iniciales: $e');
    } finally {
      if (mounted) {
        // Asegúrate de que el widget sigue montado antes de llamar a setState
        setState(() {
          _isLoadingInitial = false;
        });
      }
    }
  }

  /// Obtiene botellas de Firestore, priorizando las no vistas y aplicando filtros.
  Future<void> _fetchBottles({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (mounted) {
        setState(() {
          _isLoadingMore = true;
        });
      }
    } else {
      _bottles.clear(); // Limpia las botellas si no es una carga adicional
      _lastDocument = null; // Reinicia el último documento para paginación
      _errorMessage = null; // Reiniciar mensaje de error en carga inicial
      _hasMoreBottles = true; // Reiniciar estado de "hay más botellas"
    }

    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'Usuario no autenticado.';
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
          _isLoadingMore = false;
        });
      }
      return;
    }

    // Acceso a la colección 'botellas'
    Query<Map<String, dynamic>> baseQuery = _firestore.collection('botellas');

    // Aplicar filtro por océano
    if (_selectedFilterOceanId != null && _selectedFilterOceanId != 'Todos') {
      baseQuery = baseQuery.where('ocean', isEqualTo: _selectedFilterOceanId);
    }

    try {
      List<Botella> fetchedAndFilteredBottles = [];
      const int limit =
          25; // Número de botellas a intentar cargar por lote para mostrar
      const int firestoreBatchLimit =
          50; // Cuántos documentos pedir a Firestore en cada iteración (más del doble del límite para el filtrado en cliente)
      bool stillFetchingFromFirestore = true;

      while (fetchedAndFilteredBottles.length < limit &&
          stillFetchingFromFirestore) {
        QuerySnapshot<Map<String, dynamic>> snapshot;
        Query<Map<String, dynamic>> query =
            baseQuery.limit(firestoreBatchLimit);

        if (_lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }

        snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          stillFetchingFromFirestore = false; // No más documentos en Firestore
          _hasMoreBottles = false; // No más botellas para cargar
          break; // Salir del bucle
        }

        // Actualizar _lastDocument para la próxima potencial iteración
        _lastDocument = snapshot.docs.last;

        for (var doc in snapshot.docs) {
          final bottle = Botella.fromFirestore(doc);
          // Filtrado en el cliente: Excluir las botellas del usuario actual
          if (bottle.userId != user.uid) {
            fetchedAndFilteredBottles.add(bottle);
            if (fetchedAndFilteredBottles.length >= limit) {
              break; // Tenemos suficientes botellas que no son del usuario para este lote
            }
          }
        }

        // Si el snapshot en sí mismo fue menor que el límite del lote de Firestore,
        // significa que Firestore ya no tiene más documentos para devolver.
        if (snapshot.docs.length < firestoreBatchLimit) {
          stillFetchingFromFirestore = false;
          _hasMoreBottles = false;
        }
      }

      // Ahora, usar fetchedAndFilteredBottles para poblar _bottles
      if (!isLoadMore) {
        _bottles
            .clear(); // Limpiar solo si no es una operación de carga adicional
      }

      // Añadir las botellas recién obtenidas y filtradas a la lista principal
      _bottles.addAll(fetchedAndFilteredBottles);

      // Si después de todos los intentos, todavía no pudimos llenar el 'limit'
      // o si Firestore se quedó sin documentos, y _hasMoreBottles sigue siendo true,
      // significa que no hay más botellas que cumplan los criterios.
      if (fetchedAndFilteredBottles.length < limit && _hasMoreBottles) {
        _hasMoreBottles = false;
      }

      if (_bottles.isEmpty && !isLoadMore) {
        // Solo para el estado inicial vacío
        _errorMessage =
            'No hay botellas disponibles para mostrar en este momento.';
        _hasMoreBottles = false;
      } else {
        _errorMessage = null; // Limpiar el error si se cargan botellas
      }
    } catch (e) {
      // Solo establecer mensaje de error para excepciones reales
      _errorMessage = 'Error al obtener botellas: $e';
      print('Error fetching bottles: $e');
      if (mounted) {
        setState(() {
          _hasMoreBottles =
              false; // En caso de error, asumimos que no hay más para cargar
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  /// Carga más botellas cuando el usuario se desplaza.
  Future<void> _loadMoreBottles() async {
    if (_isLoadingMore) return; // Evita múltiples cargas simultáneas
    await _fetchBottles(isLoadMore: true);
  }

  /// Marca una botella como vista en Firestore para el usuario actual y actualiza el contador de vistas global.
  Future<void> _markBottleAsSeen(String bottleId) async {
    if (_auth.currentUser == null || _seenBottleIds.contains(bottleId)) return;

    try {
      // 1. Marcar la botella como vista para el usuario actual
      await _firestore
          .collection('usuarios')
          .doc(_auth.currentUser!.uid)
          .collection('seenBottles')
          .doc(bottleId)
          .set({'timestamp': FieldValue.serverTimestamp()});
      _seenBottleIds
          .add(bottleId); // Añadir al conjunto local para evitar re-marcar
      debugPrint('Botella $bottleId marcada como vista para el usuario.');

      // 2. Incrementar el contador de vistas global de la botella
      await _firestore
          .collection('botellas')
          .doc(bottleId)
          .update({'views': FieldValue.increment(1)});
      debugPrint('Contador de vistas de la botella $bottleId incrementado.');

      // Opcional: Actualizar el estado local de la botella para reflejar la nueva vista inmediatamente
      final index = _bottles.indexWhere((b) => b.id == bottleId);
      if (index != -1 && mounted) {
        setState(() {
          _bottles[index] =
              _bottles[index].copyWith(views: _bottles[index].views + 1);
        });
      }
    } catch (e) {
      print('Error al marcar botella como vista o incrementar vistas: $e');
    }
  }

  /// Maneja el "Me gusta" de una botella.
  Future<void> _toggleLike(String bottleId, bool currentlyLiked) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para dar "Me gusta".')),
        );
      }
      return;
    }

    final likeDocRef = _firestore
        .collection('botellas')
        .doc(bottleId)
        .collection('likes')
        .doc(user.uid);
    final bottleDocRef = _firestore.collection('botellas').doc(bottleId);

    try {
      if (currentlyLiked) {
        // Quitar "Me gusta"
        await likeDocRef.delete();
        // Solo decrementar si el contador es mayor que 0 para evitar negativos visuales
        if (_bottles.firstWhere((b) => b.id == bottleId).likes > 0) {
          await bottleDocRef.update({'likes': FieldValue.increment(-1)});
        }
        debugPrint('Unlike: $bottleId');
      } else {
        // Dar "Me gusta"
        await likeDocRef.set({'timestamp': FieldValue.serverTimestamp()});
        await bottleDocRef.update({'likes': FieldValue.increment(1)});
        debugPrint('Like: $bottleId');
      }
      // Actualizar el estado local para reflejar el cambio inmediatamente
      final index = _bottles.indexWhere((b) => b.id == bottleId);
      if (index != -1 && mounted) {
        setState(() {
          if (currentlyLiked) {
            _bottles[index] = _bottles[index].copyWith(
                likes: (_bottles[index].likes > 0)
                    ? _bottles[index].likes - 1
                    : 0);
          } else {
            _bottles[index] =
                _bottles[index].copyWith(likes: _bottles[index].likes + 1);
          }
        });
      }
    } catch (e) {
      print('Error al dar/quitar "Me gusta": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al dar/quitar "Me gusta": $e')),
        );
      }
    }
  }

  // Widget para mostrar una botella individual (similar a un TikTok card)
  Widget _buildBottleCard(Botella bottle) {
    // Acceso a la colección 'usuarios' para obtener el perfil del remitente
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('usuarios').doc(bottle.userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          // Manejar caso donde el perfil de usuario no se encuentra o hay error
          return _buildBottleContent(bottle, 'Usuario Desconocido', '❓',
              false); // Pasa isLiked como false por defecto
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userName = userData['name'] as String? ?? 'Usuario Desconocido';
        final userAvatarEmoji = userData['avatarEmoji'] as String? ?? '❓';

        // Obtener el estado de "Me gusta" para la botella actual
        final user = _auth.currentUser;
        return FutureBuilder<DocumentSnapshot>(
          future: user != null
              ? _firestore
                  .collection('botellas')
                  .doc(bottle.id)
                  .collection('likes')
                  .doc(user.uid)
                  .get()
              : Future.value(null),
          builder: (context, likeSnapshot) {
            final bool isLiked =
                likeSnapshot.hasData && likeSnapshot.data!.exists;
            return _buildBottleContent(
                bottle, userName, userAvatarEmoji, isLiked);
          },
        );
      },
    );
  }

  // Contenido de la tarjeta de botella
// Contenido de la tarjeta de botella
Widget _buildBottleContent(
    Botella bottle, String userName, String userAvatarEmoji, bool isLiked) {
  return Container(
    // Fondo con gradiente suave para un efecto de "pensamiento"
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color.fromARGB(255, 255, 255, 255), // Blanco puro (sin gradiente real)
          Color.fromARGB(255, 255, 255, 255),
          Color.fromARGB(255, 255, 255, 255),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          userAvatarEmoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '@$userName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded( // Para evitar overflow en mensajes largos
                        child: Text(
                          bottle.message, // Mensaje de la botella
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 80, // Ajustar para no superponerse con la BottomAppBar
          child: Column(
            children: [
              // Vistas (ahora aquí)
              _buildInteractionButton(Icons.remove_red_eye, bottle.views, () {
                /* Lógica de Vistas (pasiva) */
              }, false),
              // Botón de Like con estado dinámico
              _buildInteractionButton(
                isLiked ? Icons.favorite : Icons.favorite_border,
                bottle.likes,
                () => _toggleLike(bottle.id, isLiked),
                isLiked,
              ),
              _buildInteractionButton(
                Icons.comment_outlined,
                bottle.repliesCount,
                () {
                  /* Lógica de Comentario */
                },
                false,
              ),
              _buildInteractionButton(Icons.share, 0, () {
                /* Lógica de Compartir */
              }, false),
              _buildInteractionButton(Icons.bookmark_border, 0, () {
                /* Lógica de Guardar */
              }, false),
            ],
          ),
        ),
        // Hora de la botella
        Positioned(
          bottom: 20,
          left: 20,
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.black54),
              const SizedBox(width: 5),
              Text(
                _formatTimestamp(bottle.timestamp),
                style:
                    const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  // Widget auxiliar para los botones de interacción
  Widget _buildInteractionButton(
      IconData icon, int count, VoidCallback onPressed, bool isHeartLiked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white
                  .withOpacity(0.4), // Fondo semi-transparente para el botón
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                icon,
                color: isHeartLiked
                    ? Colors.red
                    : Colors.black, // Color condicional para el corazón
                size: 28,
              ),
              onPressed: onPressed,
            ),
          ),
          Text(
            _formatNumber(count),
            style: const TextStyle(
                fontSize: 12, color: Colors.black), // Texto negro
          ),
        ],
      ),
    );
  }

  // Función auxiliar para formatear números grandes (ej. 1500 -> 1.5K)
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // Función para formatear el timestamp a un formato legible
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final Duration diff = DateTime.now().difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}a';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}m';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}min';
    } else {
      return 'Ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 1,
        // Barra de filtros de océano
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(10.0), // Altura de la barra de filtros
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _oceans.map((ocean) {
                  final bool isSelected = _selectedFilterOceanId == ocean.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: ChoiceChip(
                      label: Text(
                        '${ocean.emojiIcon ?? ''} ${ocean.name}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      backgroundColor: Colors.grey[200],
                      onSelected: (selected) {
                        if (selected) {
                          if (mounted) {
                            // Asegúrate de que el widget sigue montado
                            setState(() {
                              _selectedFilterOceanId = ocean.id;
                              _fetchBottles(); // Recargar botellas con el nuevo filtro
                            });
                          }
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: _isLoadingInitial
          ? const Center(
              child: CircularProgressIndicator()) // Indicador de carga inicial
          : _errorMessage != null
              ? Center(
                  // Mensaje de error si falla la carga inicial
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 50),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadInitialData, // Botón para reintentar
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _bottles.isEmpty &&
                      !_hasMoreBottles // Si no hay botellas y no hay más para cargar
                  ? const Center(
                      child: Text('No hay botellas disponibles para mostrar.'))
                  : PageView.builder(
                      controller: _pageController,
                      scrollDirection:
                          Axis.vertical, // Desplazamiento vertical como TikTok
                      itemCount: _bottles.length +
                          (_hasMoreBottles
                              ? 1
                              : 0), // Añadir 1 para el indicador de carga/mensaje final
                      onPageChanged: (index) {
                        // Marcar la botella como vista cuando se desplaza a ella
                        if (index < _bottles.length) {
                          _markBottleAsSeen(_bottles[index].id);
                        }
                      },
                      itemBuilder: (context, index) {
                        if (index == _bottles.length) {
                          // Este es el último elemento para el indicador de carga o el mensaje de fin
                          if (_isLoadingMore) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (!_hasMoreBottles) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'Upps, ya has visto todo.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black54),
                                ),
                              ),
                            );
                          }
                          return const SizedBox
                              .shrink(); // En caso de que no haya más botellas y no esté cargando
                        }
                        final bottle = _bottles[index];
                        return _buildBottleCard(
                            bottle); // Construye la tarjeta de botella
                      },
                    ),
    );
  }
}
