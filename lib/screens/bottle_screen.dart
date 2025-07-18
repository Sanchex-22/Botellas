// create_bottle_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:botellas/models/firestore_models.dart'; // Asegúrate de que esta ruta sea correcta

class CreateBottleScreen extends StatefulWidget {
  const CreateBottleScreen({super.key});

  @override
  State<CreateBottleScreen> createState() => _CreateBottleScreenState();
}

class _CreateBottleScreenState extends State<CreateBottleScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedOceanId; // Usaremos el ID del océano (que es su nombre)
  List<OceanoMetadata> _oceans = []; // Lista de océanos disponibles
  bool _isLoading = false;
  String? _errorMessage;
  int _messageCharCount = 0; // Contador de caracteres del mensaje
  final int _maxMessageLength = 500; // Límite de caracteres del mensaje

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadOceans(); // Cargar la lista de océanos al iniciar la pantalla
    _messageController.addListener(_updateMessageCharCount);
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateMessageCharCount);
    _messageController.dispose();
    super.dispose();
  }

  void _updateMessageCharCount() {
    setState(() {
      _messageCharCount = _messageController.text.length;
    });
  }

  /// Carga los metadatos de los océanos desde Firestore.
  Future<void> _loadOceans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final oceansSnapshot = await _firestore.collection('metadata_oceanos').get();
      _oceans = oceansSnapshot.docs
          .map((doc) => OceanoMetadata.fromFirestore(doc))
          .toList();

      // MODIFICACIÓN: Seleccionar el primer océano por defecto si hay alguno
      if (_oceans.isNotEmpty) {
        _selectedOceanId = _oceans.first.id;
        debugPrint('Océanos cargados: ${_oceans.length}. Primer océano seleccionado: $_selectedOceanId');
      } else {
        debugPrint('No se encontraron océanos en Firestore.');
        _errorMessage = 'No se encontraron océanos disponibles. Asegúrate de que la colección "metadata_oceanos" existe y tiene datos.';
      }
    } catch (e) {
      _errorMessage = 'Error al cargar los océanos: $e';
      print('Error loading oceans: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Guarda la nueva botella en Firestore.
  Future<void> _saveBottle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Debes iniciar sesión para enviar una botella.';
        _isLoading = false;
      });
      return;
    }

    if (_messageController.text.trim().isEmpty ||
        _selectedOceanId == null) {
      setState(() {
        _errorMessage = 'Por favor, completa todos los campos.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Obtener el perfil del usuario para determinar si es premium
      Usuario? userProfile;
      final userDoc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (userDoc.exists) {
        userProfile = Usuario.fromFirestore(userDoc);
      }

      final newBottle = Botella(
        id: '', // Firestore generará el ID
        message: _messageController.text.trim(),
        emoji: '📝', // MODIFICACIÓN: Usamos un emoji por defecto si no se selecciona uno
        ocean: _selectedOceanId!,
        timestamp: Timestamp.now(),
        userId: user.uid,
        likes: 0,
        views: 0,
        repliesCount: 0,
        isPremium: userProfile?.isPremiumSubscriber ?? false, // Usa el estado premium del perfil
        specialEffects: null, // Puedes añadir lógica para esto más tarde
      );

      // Guarda la botella en Firestore
      await _firestore.collection('botellas').add(newBottle.toFirestore());

      // INCREMENTA EL CONTADOR DE BOTELLAS ENVIADAS EN EL PERFIL DEL USUARIO
      await _firestore.collection('usuarios').doc(user.uid).update({
        'bottlesSent': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Botella enviada exitosamente!')),
      );
      Navigator.pop(context); // Regresar a la pantalla anterior (HomeScreen)
    } on FirebaseException catch (e) {
      _errorMessage = 'Error de Firebase: ${e.message}';
      print('Firebase error saving bottle: $e');
    } catch (e) {
      _errorMessage = 'Error al enviar la botella: $e';
      print('Error saving bottle: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lanzar Botella'),
        centerTitle: true,
        backgroundColor: Colors.white, // Fondo blanco para la AppBar
        elevation: 1, // Sombra ligera
        iconTheme: const IconThemeData(color: Colors.black), // Color de los iconos de la AppBar
      ),
      body: _isLoading && _oceans.isEmpty // Mostrar indicador de carga solo si los océanos no están cargados
          ? const Center(child: CircularProgressIndicator())
          : _oceans.isEmpty && !_isLoading // MODIFICACIÓN: Mensaje específico si no hay océanos
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 50),
                        const SizedBox(height: 20),
                        const Text(
                          'No se encontraron océanos disponibles.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Por favor, asegúrate de tener documentos en la colección "metadata_oceanos" en Firestore y que tus reglas de seguridad permitan la lectura pública.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadOceans,
                          child: const Text('Reintentar Cargar Océanos'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0), // Padding general
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección superior de "Lanzar Botella"
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.blueAccent, Colors.purpleAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.3),
                                    spreadRadius: 3,
                                    blurRadius: 7,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Lanzar Botella',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Envía tu mensaje al océano infinito',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Océano destino
                      const Text(
                        'Océano destino',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Lista de botones de océano
                      Column(
                        children: _oceans.map((ocean) {
                          final bool isSelected = _selectedOceanId == ocean.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedOceanId = ocean.id;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.blueAccent : Colors.grey[200],
                                foregroundColor: isSelected ? Colors.white : Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected ? Colors.blueAccent : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                elevation: isSelected ? 4 : 1,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                minimumSize: const Size(double.infinity, 0), // Ancho completo
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    ocean.emojiIcon ?? '',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    ocean.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (ocean.isPremium)
                                    const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),

                      // Escribe tu mensaje
                      const Text(
                        'Escribe tu mensaje para el océano...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Que las corrientes lleven tus palabras a quien las necesite ✨',
                                border: InputBorder.none, // Eliminar el borde del TextField
                                isDense: true, // Hacerlo más compacto
                                contentPadding: EdgeInsets.zero, // Eliminar padding interno
                              ),
                              maxLines: 5,
                              minLines: 3,
                              maxLength: _maxMessageLength, // Limitar la longitud del mensaje
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              buildCounter: (BuildContext context, {required int currentLength, required int? maxLength, required bool isFocused}) {
                                return const SizedBox.shrink(); // Oculta el contador por defecto
                              },
                            ),
                            Text(
                              '$_messageCharCount/$_maxMessageLength',
                              style: TextStyle(
                                fontSize: 12,
                                color: _messageCharCount > _maxMessageLength ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Botón "Lanzar al Océano"
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveBottle,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shadowColor: Colors.blueAccent.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.send, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Lanzar al Océano',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20), // Espacio al final
                    ],
                  ),
                ),
    );
  }
}
