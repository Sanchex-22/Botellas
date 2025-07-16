// main.dart
import 'package:botellas/adds/ad_manager.dart';
import 'package:botellas/class/environment.dart';
import 'package:botellas/screens/home_screen.dart';
import 'package:botellas/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import for Google Mobile Ads
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  await dotenv.load(fileName: Environment.fileName); 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Google Mobile Ads SDK only if not running on web.
  // This should be done once globally.
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  late AdManager _adManager; // Declare an instance of AdManager

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add this state as an observer
    _adManager = AdManager(); // Initialize the AdManager
    // Call the public method to load and show the interstitial ad
    _adManager.loadAndShowInterstitialAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove the observer
    _adManager.dispose(); // Dispose of ad resources when the state is disposed
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Delegate the app lifecycle state change handling to the AdManager
    _adManager.handleAppLifecycleStateChange(state);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Botellas",
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity),
      // Use StreamBuilder with firebase_auth.User?
      home: StreamBuilder<User?>( // <--- CAMBIO AQUÍ: Usar User? de firebase_auth
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Muestra un indicador de carga mientras se verifica la autenticación
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // Si hay un usuario logueado (un objeto User de Firebase), ve al HomeScreen
            return HomeScreen();
          } else {
            // Si no hay usuario logueado, ve a la pantalla de Login
            return LoginScreen();
          }
        },
      ),
      routes: {'/home': (context) => HomeScreen()},
    );
  }
}
