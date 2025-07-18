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
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Reducido de 12.0 a 4.0
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20, // reduce ligeramente el tamaño si deseas
              color: isSelected ? Colors.blueAccent : Colors.black54,
            ),
            SizedBox(
              width: double.infinity, // asegura ancho completo dentro de Expanded
              child: Text(
                label,
                overflow: TextOverflow.ellipsis, // añade ellipsis si no cabe
                softWrap: false, // no hace wrap
                textAlign: TextAlign.center, // centra el texto
                style: TextStyle(
                  color: isSelected ? Colors.blueAccent : Colors.black54,
                  fontSize: 10, // reduce ligeramente para caber
                ),
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
      body: _widgetOptions[_selectedIndex], // Usa solo el contenido como body
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Banner Ad
            if (_isBannerAdLoaded &&
                _adBanner.getBannerAdWidget() != null &&
                _adBanner.adSize != null)
              Container(
                alignment: Alignment.center,
                width: _adBanner.adSize!.width.toDouble(),
                height: _adBanner.adSize!.height.toDouble(),
                child: _adBanner.getBannerAdWidget(),
              ),
            // BottomAppBar
            BottomAppBar(
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(child: _buildNavItem(Icons.waves, 'Océano', 0)),
                    Expanded(
                        child: _buildNavItem(Icons.mail_outline, 'Recibir', 1)),
                    SizedBox(
                      width: 56.0,
                      height: 56.0,
                      child: RawMaterialButton(
                        onPressed: _onFabPressed,
                        elevation: 2.0,
                        fillColor: Colors.blueAccent,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 24.0),
                      ),
                    ),
                    Expanded(
                        child: _buildNavItem(Icons.star_outline, 'Premium', 2)),
                    Expanded(
                        child:
                            _buildNavItem(Icons.person_outline, 'Perfil', 3)),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
