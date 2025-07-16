// ad_banner.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // Necesario para AdWidget
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Una clase para gestionar la carga y disposición de un BannerAd.
class AdBanner {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  AdSize? _adSize; // Añadido para almacenar el tamaño del anuncio

  // Callbacks para notificar a la UI cuando el banner se carga o falla
  final VoidCallback? onAdLoadedCallback;
  final VoidCallback? onAdFailedToLoadCallback;

  AdBanner({this.onAdLoadedCallback, this.onAdFailedToLoadCallback});

  /// Retorna el ID de la unidad de anuncio banner apropiado según la plataforma.
  String get _getBannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Accede a la variable de entorno para Android
      return dotenv.env['TEST_BANNER_AD_UNIT_ID_ANDROID'] ?? 'ca-app-pub-3940256099942544/9214589741';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Accede a la variable de entorno para iOS
      return dotenv.env['TEST_BANNER_AD_UNIT_ID_IOS'] ?? 'ca-app-pub-3940256099942544/2435281174';
    }
    return ''; // Retorna vacío si no es Android ni iOS
  }

  /// Carga el BannerAd.
  void loadBannerAd() {
    // Solo carga si no está en la web.
    if (kIsWeb) {
      debugPrint('Los anuncios de banner no son compatibles con la web.');
      return;
    }

    // Si ya hay un anuncio cargado o en proceso de carga, no hacemos nada.
    if (_bannerAd != null && _isBannerAdLoaded) {
      return;
    }

    final String adUnitId = _getBannerAdUnitId;
    if (adUnitId.isEmpty) {
      print('No se pudo determinar el ID de la unidad de anuncios para la plataforma actual.');
      onAdFailedToLoadCallback?.call(); // Notifica que falló la carga
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner, // Usamos un tamaño fijo de banner
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          _adSize = _bannerAd!.size; // Almacena el tamaño del anuncio
          print('BannerAd cargado.');
          onAdLoadedCallback?.call(); // Notifica que el banner se cargó
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose(); // Dispone el anuncio que falló
          _isBannerAdLoaded = false;
          _bannerAd = null; // Limpia la referencia
          _adSize = null; // Limpia el tamaño
          print('BannerAd falló al cargar: $error');
          onAdFailedToLoadCallback?.call(); // Notifica que falló la carga
        },
        onAdOpened: (ad) => print('BannerAd abierto.'),
        onAdClosed: (ad) => print('BannerAd cerrado.'),
        onAdImpression: (ad) => print('BannerAd impresión.'),
      ),
    )..load(); // Inicia la carga del anuncio
  }

  /// Retorna el widget del BannerAd si está cargado, de lo contrario, retorna null.
  Widget? getBannerAdWidget() {
    if (_isBannerAdLoaded && _bannerAd != null) {
      return AdWidget(ad: _bannerAd!);
    }
    return null;
  }

  /// Retorna el tamaño del BannerAd si está cargado, de lo contrario, retorna null.
  AdSize? get adSize => _adSize;

  /// Dispone del BannerAd cuando ya no es necesario.
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
    _adSize = null;
  }
}
