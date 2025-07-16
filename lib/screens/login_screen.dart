// login_screen.dart
import 'package:botellas/screens/home_screen.dart';
import 'package:flutter/material.dart';

/// Pantalla de inicio de sesión que permite al usuario loguearse o entrar como invitado.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Maneja la lógica para el botón "Login".
  /// Por ahora, es un placeholder. Aquí iría la lógica de autenticación real.
  void _handleLogin() {
    // Implementa tu lógica de inicio de sesión aquí (ej: Firebase Auth)
    final String email = _emailController.text;
    final String password = _passwordController.text;

    debugPrint('Intentando iniciar sesión con: Email: $email, Contraseña: $password');

    // Navega a la HomeScreen después de un inicio de sesión exitoso (simulado)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  /// Maneja la lógica para el botón "Entrar como Invitado".
  /// Navega directamente a la HomeScreen.
  void _handleGuestLogin() {
    debugPrint('Entrando como invitado...');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
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

              // Botón de Login
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // Ancho completo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Iniciar Sesión',
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
                onPressed: _handleGuestLogin,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // Ancho completo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  side: const BorderSide(color: Colors.blueAccent),
                  foregroundColor: Colors.blueAccent,
                ),
                child: const Text(
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
