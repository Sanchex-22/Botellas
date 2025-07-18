// login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore
import 'package:botellas/screens/home_screen.dart'; // Importa tu HomeScreen
import 'package:botellas/models/firestore_models.dart'; // Importa tu modelo Usuario

/// Pantalla de inicio de sesión que permite al usuario loguearse, registrarse o entrar como invitado.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false; // Estado para controlar el indicador de carga

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Muestra un SnackBar con un mensaje de error o éxito.
  void _showSnackBar(String message, {bool isError = false}) {
    // Añadir verificación de mounted antes de mostrar el SnackBar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// Crea o actualiza el perfil de usuario en Firestore.
  Future<void> _createOrUpdateUserProfile(User user) async {
    final userDocRef = _firestore.collection('usuarios').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      // Si el perfil no existe, crea uno nuevo
      final newProfile = Usuario(
        id: user.uid,
        name: user.isAnonymous ? 'Invitado-${user.uid.substring(0, 4)}' : (user.email?.split('@')[0] ?? 'Nuevo Usuario'),
        avatarEmoji: '⚓', // Emoji por defecto
        isPremiumSubscriber: false,
        premiumCrown: false,
        lastActivity: Timestamp.now(),
      );
      await userDocRef.set(newProfile.toFirestore());
      debugPrint('Perfil de usuario creado para: ${user.uid}');
    } else {
      // Si el perfil existe, actualiza la última actividad
      await userDocRef.update({'lastActivity': Timestamp.now()});
      debugPrint('Última actividad del perfil actualizada para: ${user.uid}');
    }
  }

  /// Maneja la lógica para el botón "Iniciar Sesión".
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showSnackBar('Por favor, ingresa tu correo y contraseña.', isError: true);
        // Asegúrate de restablecer _isLoading si la validación falla aquí
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _createOrUpdateUserProfile(userCredential.user!); // Crea/actualiza perfil en Firestore

      _showSnackBar('Inicio de sesión exitoso!');
      // Navega *después* de que todo el proceso se haya completado con éxito
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No se encontró un usuario con ese correo.';
      } else if (e.code == 'wrong-password') {
        message = 'Contraseña incorrecta.';
      } else if (e.code == 'invalid-email') {
        message = 'El formato del correo electrónico es inválido.';
      } else {
        message = 'Error de inicio de sesión: ${e.message}';
      }
      _showSnackBar(message, isError: true);
      debugPrint('Error de inicio de sesión: $e');
    } catch (e) {
      _showSnackBar('Ocurrió un error inesperado: $e', isError: true);
      debugPrint('Error inesperado durante el inicio de sesión: $e');
    } finally {
      // Siempre restablecer _isLoading en el bloque finally
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Maneja la lógica para el botón "Registrarse".
  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showSnackBar('Por favor, ingresa un correo y una contraseña para registrarte.', isError: true);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      if (password.length < 6) {
        _showSnackBar('La contraseña debe tener al menos 6 caracteres.', isError: true);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _createOrUpdateUserProfile(userCredential.user!); // Crea perfil en Firestore para el nuevo usuario

      _showSnackBar('Registro exitoso! Has iniciado sesión.');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        message = 'El correo electrónico ya está en uso.';
      } else if (e.code == 'invalid-email') {
        message = 'El formato del correo electrónico es inválido.';
      } else {
        message = 'Error de registro: ${e.message}';
      }
      _showSnackBar(message, isError: true);
      debugPrint('Error de registro: $e');
    } catch (e) {
      _showSnackBar('Ocurrió un error inesperado: $e', isError: true);
      debugPrint('Error inesperado durante el registro: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Maneja la lógica para el botón "Entrar como Invitado".
  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
    });
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      await _createOrUpdateUserProfile(userCredential.user!); // Crea perfil en Firestore para el invitado

      _showSnackBar('Has entrado como invitado.');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Error al entrar como invitado: ${e.message}', isError: true);
      debugPrint('Error al entrar como invitado: $e');
    } catch (e) {
      _showSnackBar('Ocurrió un error inesperado al entrar como invitado: $e', isError: true);
      debugPrint('Error inesperado al entrar como invitado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido a Botellas'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Título o logo de la aplicación
              const Text(
                'Botellas App',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 40),

              // Campo de entrada para el correo electrónico
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  hintText: 'ejemplo@dominio.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),

              // Campo de entrada para la contraseña
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Ingresa tu contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),

              // Botón de Iniciar Sesión
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin, // Deshabilitar si está cargando
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // Ancho completo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 20),

              // Botón de Registrarse
              OutlinedButton(
                onPressed: _isLoading ? null : _handleRegister, // Deshabilitar si está cargando
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // Ancho completo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  side: const BorderSide(color: Colors.green), // Color diferente para registro
                  foregroundColor: Colors.green,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.green)
                    : const Text(
                        'Registrarse',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 20),

              // Separador o texto "o"
              const Text(
                'O',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Botón para entrar como invitado
              OutlinedButton(
                onPressed: _isLoading ? null : _handleGuestLogin, // Deshabilitar si está cargando
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // Ancho completo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  side: const BorderSide(color: Colors.blueAccent),
                  foregroundColor: Colors.blueAccent,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.blueAccent)
                    : const Text(
                        'Entrar como Invitado',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
