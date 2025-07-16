// ad_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb and defaultTargetPlatform
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import for Google Mobile Ads

/// Define a test ad unit ID for Interstitial Ads.
/// You should replace this with your actual ad unit ID.
/// For iOS, use 'ca-app-pub-3940256099942544/4414707907'
const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

/// A class to manage the loading and showing of Google Mobile Ads (Interstitial and App Open).
class AdManager {
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _lastAdShownTime;

  /// Constructor for AdManager.
  /// No need to initialize MobileAds.instance here, as it's done globally in main.dart.
  AdManager() {
    // Optionally load an App Open Ad on initialization if desired,
    // but the original logic loads it on app resume if not already loaded.
    // _loadAppOpenAd();
  }

  /// Returns the appropriate App Open Ad Unit ID based on the platform.
  String get _appOpenAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-2116089172655720/7019833718'; // Android test ID
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-2116089172655720/8336198081'; // iOS test ID
    }
    return ''; // Return empty if not Android or iOS
  }

  /// Loads an Interstitial Ad.
  void _loadInterstitialAd() {
    // Only load if not on web, as MobileAds is not initialized for web.
    if (kIsWeb) {
      debugPrint('Interstitial ads are not supported on web.');
      return;
    }

    InterstitialAd.load(
      adUnitId: testInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('$ad loaded.');
          _interstitialAd = ad;
          _showInterstitialAd(); // Show immediately after loading, as per original logic
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
        ad.dispose(); // Dispose the ad after it's dismissed
        _interstitialAd = null; // Clear the reference
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose(); // Dispose the ad if it fails to show
        _interstitialAd = null; // Clear the reference
      },
    );
    _interstitialAd!.show(); // Show the ad
  }

  /// Public method to trigger the loading and showing of an Interstitial Ad.
  void loadAndShowInterstitialAd() {
    _loadInterstitialAd();
  }

  /// Loads an App Open Ad.
  void _loadAppOpenAd() {
    // Only load if not on web.
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
          _appOpenAd = null; // Ensure the ad is cleaned if load fails
        },
      ),
    );
  }

  /// Shows the loaded App Open Ad.
  void _showAppOpenAd() {
    if (_appOpenAd == null) {
      print('AppOpenAd: No hay anuncio cargado para mostrar.');
      _loadAppOpenAd(); // Try to load a new one
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        _lastAdShownTime =
            DateTime.now(); // Record the time the ad was shown
        print('AppOpenAd mostrado en pantalla completa.');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose(); // Release resources of the shown ad
        _appOpenAd = null; // Clear the reference
        _loadAppOpenAd(); // Load the next ad for the next time
        print('AppOpenAd cerrado.');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose(); // Release resources of the failed ad
        _appOpenAd = null; // Clear the reference
        _loadAppOpenAd(); // Try to load the next ad
        print('AppOpenAd falló al mostrar: $error');
      },
    );
    _appOpenAd!.show(); // Show the ad
  }

  /// Handles changes in the app's lifecycle state, specifically for App Open Ads.
  void handleAppLifecycleStateChange(AppLifecycleState state) {
    // Only handle if not on web.
    if (kIsWeb) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // If the app comes back to the foreground
      if (_appOpenAd != null && !_isShowingAd) {
        // Only show the ad if enough time has passed since the last one was shown
        if (_lastAdShownTime == null ||
            DateTime.now().difference(_lastAdShownTime!).inMinutes >= 1) {
          // Show every 1 minute
          _showAppOpenAd();
        } else {
          print('AppOpenAd: Demasiado pronto para mostrar otro anuncio.');
        }
      } else if (_appOpenAd == null) {
        // If no ad is loaded, try to load one
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
