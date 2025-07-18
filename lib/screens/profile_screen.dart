// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:botellas/screens/login_screen.dart'; // Importa la pantalla de login
import 'package:botellas/models/firestore_models.dart'; // Importa tu modelo Usuario

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Instancia de Firestore

  Usuario? _userProfile;
  List<Botella> _userBottles = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndBottles(); // Cargar perfil y botellas
  }

  /// Maneja la lógica para cerrar la sesión del usuario.
  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      // Navegar de vuelta a la pantalla de login y remover todas las rutas anteriores
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false, // Elimina todas las rutas de la pila
      );
    } catch (e) {
      print('Error al cerrar sesión: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  /// Carga el perfil del usuario y sus botellas desde Firestore.
  Future<void> _loadUserProfileAndBottles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'No hay usuario autenticado.';
          _isLoading = false;
        });
        return;
      }

      // 1. Cargar el perfil del usuario
      final userDoc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (userDoc.exists) {
        _userProfile = Usuario.fromFirestore(userDoc);
      } else {
        // Si el perfil no existe, crea uno básico
        _errorMessage = 'Perfil de usuario no encontrado. Creando uno básico...';
        _userProfile = Usuario(
          id: user.uid,
          name: user.isAnonymous ? 'Invitado-${user.uid.substring(0, 4)}' : (user.email?.split('@')[0] ?? 'Nuevo Usuario'),
          avatarEmoji: '⚓', // Emoji por defecto
          isPremiumSubscriber: false,
          premiumCrown: false,
          lastActivity: Timestamp.now(),
        );
        await _firestore.collection('usuarios').doc(user.uid).set(_userProfile!.toFirestore());
        _errorMessage = ''; // Limpia el mensaje de error si se creó con éxito
      }

      // 2. Cargar las botellas del usuario
      final bottlesSnapshot = await _firestore
          .collection('botellas')
          .where('userId', isEqualTo: user.uid)
          .get();

      _userBottles = bottlesSnapshot.docs
          .map((doc) => Botella.fromFirestore(doc))
          .toList();

      // Ordenar las botellas por timestamp de forma descendente (más recientes primero)
      _userBottles.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    } catch (e) {
      _errorMessage = 'Error al cargar los datos: $e';
      print('Error al cargar datos del perfil: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  // Widget auxiliar para las columnas de estadísticas
  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Widget auxiliar para los iconos de estadísticas de la botella
  Widget _buildStatIcon(IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 5),
          Text(
            _formatNumber(count),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando Perfil...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error en Perfil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadUserProfileAndBottles, // Reintentar cargar perfil y botellas
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si no hay perfil de usuario (ej. error inesperado o no se pudo crear)
    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil No Disponible')),
        body: const Center(
          child: Text('No se pudo cargar la información del perfil.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Fondo transparente para AppBar
        elevation: 0, // Sin sombra
        actions: [
          // Botón de cerrar sesión en la AppBar
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      extendBodyBehindAppBar: true, // Extiende el body detrás de la AppBar
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sección superior del perfil
            Container(
              padding: const EdgeInsets.only(top: 80.0, bottom: 20.0), // Ajustar padding superior para no chocar con AppBar
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      _userProfile!.avatarEmoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userProfile!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Navegando océanos de emociones', // Descripción fija o de un campo del modelo
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Muestra el correo del usuario (o "Usuario Invitado") debajo del nombre/descripción
                  Text(
                    _auth.currentUser?.email ?? 'Usuario Invitado',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Estadísticas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                      _formatNumber(_userProfile!.bottlesSent), 'Botellas'),
                  _buildStatColumn(
                      _formatNumber(_userProfile!.heartsReceived), 'Corazones'),
                  _buildStatColumn(
                      _formatNumber(_userProfile!.followingCount), 'Siguiendo'),
                  _buildStatColumn(
                      _formatNumber(_userProfile!.followersCount), 'Seguidores'),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Sección Hazte Premium
            if (!_userProfile!.isPremiumSubscriber) // Solo muestra si no es premium
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Hazte Premium',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Navega océanos exclusivos',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            print('Botón Mejorar presionado');
                            // Aquí iría la lógica para la suscripción premium
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange, // Color naranja para el botón
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('Mejorar', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 30),

            // Pestañas Mis Botellas / Estadísticas
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blueAccent,
                    tabs: const [
                      Tab(icon: Icon(Icons.message), text: 'Mis Botellas'),
                      Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5, // Ajusta la altura según sea necesario
                    child: TabBarView(
                      children: [
                        // Contenido de Mis Botellas
                        _userBottles.isEmpty
                            ? const Center(child: Text('Aún no has enviado ninguna botella.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: _userBottles.length,
                                itemBuilder: (context, index) {
                                  final bottle = _userBottles[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 15),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.waves, color: Colors.blueAccent, size: 18),
                                              const SizedBox(width: 5),
                                              Text(
                                                bottle.ocean,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                _formatTimestamp(bottle.timestamp),
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            bottle.message,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              _buildStatIcon(Icons.favorite_border, bottle.likes),
                                              _buildStatIcon(Icons.chat_bubble_outline, bottle.repliesCount),
                                              _buildStatIcon(Icons.remove_red_eye, bottle.views),
                                              _buildStatIcon(Icons.share, 0), // No hay campo para compartir en el modelo
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        // Contenido de Estadísticas
                        const Center(child: Text('Aquí irían las estadísticas detalladas del usuario.')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
