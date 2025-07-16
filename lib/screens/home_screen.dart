// home_screen.dart
import 'package:flutter/material.dart';
import 'package:botellas/adds/ad_banner.dart'; // Importa tu clase AdBanner

class HomeScreen extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  late AdBanner _adBanner;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // Inicializa AdBanner y pasa callbacks para actualizar el estado de _isBannerAdLoaded
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: const Center(
        child: Text('Welcome to the Home Screen!'),
      ),
      // Muestra el banner ad en la parte inferior de la pantalla
      bottomNavigationBar: _isBannerAdLoaded && _adBanner.getBannerAdWidget() != null && _adBanner.adSize != null
          ? Container(
              alignment: Alignment.center,
              // Accede al tamaño directamente desde _adBanner.adSize
              width: _adBanner.adSize!.width.toDouble(),
              height: _adBanner.adSize!.height.toDouble(),
              child: _adBanner.getBannerAdWidget(),
            )
          : null, // No muestra nada si el banner no está cargado o su tamaño no está disponible
    );
  }
}
