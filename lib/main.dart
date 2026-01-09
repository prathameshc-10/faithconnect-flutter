import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/leaders_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/posts_provider.dart';
import 'views/screens/splash_screen.dart';

/// FaithConnect App
/// Main entry point for the mobile application
/// Uses Provider for state management
void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
        // Navigation state provider (bottom navigation bar)
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        // Global app state provider (auth + role)
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        // Content/posts provider (shared between worshipers and leaders)
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        // Feed state provider (Explore/Following tabs)
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        // Leaders state provider (My Leaders/Explore tabs)
        ChangeNotifierProvider(create: (_) => LeadersProvider()),
        // Messages state provider (mocked, UI-only)
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
        // Main entry point: Splash screen which routes into auth/role flows
        home: const SplashScreen(),
      ),
    );
  }
}
