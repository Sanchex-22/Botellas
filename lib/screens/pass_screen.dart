import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// Pantalla de placeholder para la sección Premium
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sección Premium'),
      ),
      body: const Center(
        child: Text('Contenido exclusivo para usuarios Premium.'),
      ),
    );
  }
}