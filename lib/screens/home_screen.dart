// home_screen.dart
import 'package:botellas/screens/bottle_screen.dart';
import 'package:botellas/screens/foryou_screen.dart';
import 'package:botellas/screens/pass_screen.dart';
import 'package:botellas/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:botellas/adds/ad_banner.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  late AdBanner _adBanner;
  bool _isBannerAdLoaded = false;
  int _selectedIndex = 0; // Para controlar la pestaña seleccionada

  // Lista de widgets para cada pestaña de navegación
  static final List<Widget> _widgetOptions = <Widget>[
    const ForYousScreen(),
    const Center(child: Text('Pantalla de Recibir')),
    const PremiumScreen(), // Nueva pantalla Premium
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onFabPressed() {
    // Acción para el botón central de añadir
    print('Botón de añadir presionado!');
    // Navegar a una nueva pantalla para crear una botella
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateBottleScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _adBanner = AdBanner(
      onAdLoadedCallback: () {
        setState(() {
          _isBannerAdLoaded = true;
        });
      },
      onAdFailedToLoadCallback: () {
        setState(() {
          _isBannerAdLoaded = false;
        });
      },
    );
    _adBanner.loadBannerAd(); // Inicia la carga del banner
  }

  @override
  void dispose() {
    _adBanner.dispose(); // Dispone el banner cuando la pantalla se cierra
    super.dispose();
  }

  // Widget auxiliar para construir los elementos de la barra de navegación inferior
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return Material( // Usar Material para el efecto de "splash" al tocar
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blueAccent : Colors.black54, // Colores según el diseño
              ),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blueAccent : Colors.black54, // Colores según el diseño
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column( // Usamos Column para apilar el contenido principal y el banner
        children: [
          Expanded(
            child: _widgetOptions[_selectedIndex], // Muestra el contenido de la pestaña seleccionada
          ),
          // Muestra el banner ad aquí, encima de la barra de navegación inferior
          if (_isBannerAdLoaded && _adBanner.getBannerAdWidget() != null && _adBanner.adSize != null)
            Container(
              alignment: Alignment.center,
              width: _adBanner.adSize!.width.toDouble(),
              height: _adBanner.adSize!.height.toDouble(),
              child: _adBanner.getBannerAdWidget(),
            ),
        ],
      ),
      // El FloatingActionButton y floatingActionButtonLocation se eliminan porque el botón '+' ahora está dentro del BottomAppBar
      bottomNavigationBar: BottomAppBar(
        // Se eliminan shape y notchMargin ya que el FAB está integrado en el Row
        color: Colors.white, // Fondo blanco para la barra de navegación
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(child: _buildNavItem(Icons.waves, 'Océano', 0)),
            Expanded(child: _buildNavItem(Icons.mail_outline, 'Recibir', 1)),
            // Botón central de añadir (simulando un FAB)
            Expanded(
              child: Center(
                child: SizedBox( // Usamos SizedBox para controlar el tamaño del "FAB" integrado
                  width: 56.0, // Tamaño estándar de un FAB
                  height: 56.0,
                  child: RawMaterialButton( // Usamos RawMaterialButton para mayor control de estilo
                    onPressed: _onFabPressed,
                    elevation: 2.0, // Elevación para simular el FAB
                    fillColor: Colors.blueAccent, // Color de fondo
                    shape: const CircleBorder(), // Forma circular
                    child: const Icon(Icons.add, color: Colors.white, size: 24.0),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildNavItem(Icons.star_outline, 'Premium', 2)), // Nuevo item para Premium
            Expanded(child: _buildNavItem(Icons.person_outline, 'Perfil', 3)),
          ],
        ),
      ),
    );
  }
}
