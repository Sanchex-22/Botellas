// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:botellas/screens/login_screen.dart';
import 'package:botellas/models/firestore_models.dart'; // Asegúrate de que esta ruta sea correcta y el modelo Usuario esté actualizado

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Usuario? _userProfile;
  List<Botella> _userBottles = [];

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error al cerrar sesión: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  // Skeleton loading básico
  Widget _buildSkeleton() {
    return Scaffold(
      appBar: AppBar(title: const Text('Cargando Perfil...')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
            const SizedBox(height: 16),
            Container(height: 20, width: 150, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Container(height: 14, width: 200, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) => Container(height: 40, width: 60, color: Colors.grey[300])),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(height: 80, color: Colors.grey[300]),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('No hay usuario autenticado.')),
      );
    }

    // Stream con converter para Usuario
    final userProfileStream = _firestore
        .collection('usuarios')
        .doc(user.uid)
        .withConverter<Usuario>(
          fromFirestore: (snap, _) => Usuario.fromFirestore(snap),
          toFirestore: (usuario, _) => usuario.toFirestore(),
        )
        .snapshots();

    // Stream con converter para Botella
    final userBottlesStream = _firestore
        .collection('botellas')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .withConverter<Botella>(
          fromFirestore: (snap, _) => Botella.fromFirestore(snap),
          toFirestore: (botella, _) => botella.toFirestore(),
        )
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Usuario>>(
      stream: userProfileStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (userSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error en Perfil')),
            body: Center(child: Text('Error: ${userSnapshot.error}')),
          );
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          // Puedes decidir crear perfil básico aquí o mostrar error
          return Scaffold(
            appBar: AppBar(title: const Text('Perfil No Disponible')),
            body: const Center(child: Text('Perfil no encontrado.')),
          );
        }

        _userProfile = userSnapshot.data!.data();

        // Si _userProfile es nulo aquí, algo salió mal en el fromFirestore o el documento no existe.
        // Se añade una comprobación adicional para evitar errores de null safety.
        if (_userProfile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Perfil Vacío')),
            body: const Center(child: Text('Los datos del perfil no se pudieron cargar.')),
          );
        }

        return StreamBuilder<QuerySnapshot<Botella>>(
          stream: userBottlesStream,
          builder: (context, bottlesSnapshot) {
            if (bottlesSnapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeleton();
            }
            if (bottlesSnapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error en Botellas')),
                body: Center(child: Text('Error: ${bottlesSnapshot.error}')),
              );
            }
            _userBottles = bottlesSnapshot.data!.docs.map((doc) => doc.data()).toList();

            // CALCULAR LA SUMA DE LIKES DE TODAS LAS BOTELLAS DEL USUARIO
            final int totalHeartsReceived = _userBottles.fold(0, (sum, bottle) => sum + bottle.likes);

            // UI normal con datos cargados
            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _handleLogout,
                    tooltip: 'Cerrar Sesión',
                  ),
                ],
              ),
              extendBodyBehindAppBar: true,
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 80.0, bottom: 20.0),
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
                            'Navegando océanos de emociones',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user.email ?? 'Usuario Invitado',
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Aquí se usan los campos del modelo Usuario
                          _buildStatColumn(_formatNumber(_userBottles.length), 'Botellas'), // Muestra la cantidad de botellas del usuario
                          _buildStatColumn(_formatNumber(totalHeartsReceived), 'Corazones'), // Usa la suma calculada de likes
                          _buildStatColumn(_formatNumber(_userProfile!.followingCount), 'Siguiendo'),
                          _buildStatColumn(_formatNumber(_userProfile!.followersCount), 'Seguidores'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (!_userProfile!.isPremiumSubscriber)
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
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
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
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: TabBarView(
                              children: [
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
                                                        const Icon(Icons.waves, color: Colors.blueAccent, size: 18),
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
                                                        _buildStatIcon(Icons.share, 0),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
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
          },
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

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
}
