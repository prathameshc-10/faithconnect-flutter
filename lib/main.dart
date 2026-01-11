import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// ❌ REMOVED: import 'providers/navigation_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/leaders_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/posts_provider.dart';
import 'views/screens/splash_screen.dart';

/// FaithConnect App
/// Main entry point for the mobile application
/// Uses Provider for state management
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAY3P3-Zbrt4CtKz3r1IuN7Dky8vYIwHKM",
      appId: "1:813260181154:android:cb43e6fa6561deba2d11fb",
      messagingSenderId: "813260181154",
      projectId: "faithconnect-9746b",
      storageBucket: "faithconnect-9746b.firebasestorage.app",
    ),
  );

  // Set system UI overlay style for mobile-only layout
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Force portrait orientation for mobile-only app
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const FaithConnectApp());
  });
}

/// Root MaterialApp widget
/// Configured for mobile-only layout with Material Design
/// Wrapped with Provider for state management
class FaithConnectApp extends StatelessWidget {
  const FaithConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ❌ REMOVED: NavigationProvider (each navigation shell creates its own)
        
        // ✅ Global app state provider (auth + role)
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
        ),
        
        // ✅ Content/posts provider (shared between worshipers and leaders)
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        
        // ✅ Feed state provider (Explore/Following tabs)
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        
        // ✅ Leaders state provider (My Leaders/Explore tabs)
        ChangeNotifierProvider(create: (_) => LeadersProvider()),
        
        // ✅ Messages state provider (mocked, UI-only)
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
      ],
      child: MaterialApp(
        title: 'FaithConnect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Material 3 design with clean white background
          useMaterial3: true,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        // ✅ Main entry point: Splash screen which routes to AuthGate
        home: const SplashScreen(),
      ),
    );
  }
}