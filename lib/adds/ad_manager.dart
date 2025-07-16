// ad_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importa flutter_dotenv

/// A class to manage the loading and showing of Google Mobile Ads (Interstitial and App Open).
class AdManager {
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _lastAdShownTime;

  AdManager() {
    // No es necesario cargar el .env aquí, ya se hace en main.dart
  }

  /// Returns the appropriate Interstitial Ad Unit ID from environment variables.
  String get _interstitialAdUnitId {
    // Accede a la variable de entorno
    return dotenv.env['TEST_INTERSTITIAL_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/1033173712';
  }

  /// Returns the appropriate App Open Ad Unit ID based on the platform.
  String get _appOpenAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Accede a la variable de entorno para Android
      return dotenv.env['TEST_APP_OPEN_AD_UNIT_ID_ANDROID'] ?? 'ca-app-pub-2116089172655720/7019833718';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Accede a la variable de entorno para iOS
      return dotenv.env['TEST_APP_OPEN_AD_UNIT_ID_IOS'] ?? 'ca-app-pub-2116089172655720/8336198081';
    }
    return ''; // Return empty if not Android or iOS
  }

  /// Loads an Interstitial Ad.
  void _loadInterstitialAd() {
    if (kIsWeb) {
      debugPrint('Interstitial ads are not supported on web.');
      return;
    }

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId, // Usa el getter para obtener el ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('$ad loaded.');
          _interstitialAd = ad;
          _showInterstitialAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Shows the loaded Interstitial Ad.
  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      debugPrint('Warning: Interstitial ad is not loaded yet.');
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('$ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _interstitialAd = null;
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _interstitialAd = null;
      },
    );
    _interstitialAd!.show();
  }

  /// Public method to trigger the loading and showing of an Interstitial Ad.
  void loadAndShowInterstitialAd() {
    _loadInterstitialAd();
  }

  /// Loads an App Open Ad.
  void _loadAppOpenAd() {
    if (kIsWeb) {
      debugPrint('App Open ads are not supported on web.');
      return;
    }

    if (_appOpenAdUnitId.isEmpty) {
      print(
          'AppOpenAd: ID de unidad de anuncio no configurado para la plataforma actual.');
      return;
    }

    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          print('AppOpenAd cargado exitosamente.');
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd falló al cargar: $error');
          _appOpenAd = null;
        },
      ),
    );
  }

  /// Shows the loaded App Open Ad.
  void _showAppOpenAd() {
    if (_appOpenAd == null) {
      print('AppOpenAd: No hay anuncio cargado para mostrar.');
      _loadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        _lastAdShownTime = DateTime.now();
        print('AppOpenAd mostrado en pantalla completa.');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
        print('AppOpenAd cerrado.');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
        print('AppOpenAd falló al mostrar: $error');
      },
    );
    _appOpenAd!.show();
  }

  /// Handles changes in the app's lifecycle state, specifically for App Open Ads.
  void handleAppLifecycleStateChange(AppLifecycleState state) {
    if (kIsWeb) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_appOpenAd != null && !_isShowingAd) {
        if (_lastAdShownTime == null ||
            DateTime.now().difference(_lastAdShownTime!).inMinutes >= 1) {
          _showAppOpenAd();
        } else {
          print('AppOpenAd: Demasiado pronto para mostrar otro anuncio.');
        }
      } else if (_appOpenAd == null) {
        _loadAppOpenAd();
      }
    }
  }

  /// Disposes of all loaded ad resources.
  void dispose() {
    _interstitialAd?.dispose();
    _appOpenAd?.dispose();
  }
}
