import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kulineran/auth_gate.dart';
import 'package:kulineran/components/screens/splash_screen.dart';
import 'package:kulineran/components/screens/onboarding_screen.dart';
import 'package:kulineran/components/screens/login_screen.dart';
import 'package:kulineran/components/screens/register_screen.dart';
import 'package:kulineran/components/screens/main_navigation_screen.dart';
import 'package:kulineran/components/screens/add_post_screen.dart';
import 'package:kulineran/components/screens/search_screen.dart';
import 'package:kulineran/components/screens/favorites_screen.dart';
import 'package:kulineran/components/screens/profile_screen.dart';
import 'package:kulineran/services/user_service.dart';
import 'package:kulineran/styles/theme_data.dart';

class KulineranApp extends StatelessWidget {
  const KulineranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) {
          return _buildApp(ThemeMode.light);
        }

        return StreamBuilder<Map<String, dynamic>?>(
          stream: UserService().getUserStream(user.uid),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data;
            final darkMode = userData?['darkMode'] ?? false;
            return _buildApp(darkMode ? ThemeMode.dark : ThemeMode.light);
          },
        );
      },
    );
  }

  Widget _buildApp(ThemeMode themeMode) {
    return MaterialApp(
      title: 'Kulineran',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
      routes: {
        "/auth": (context) => const AuthGate(),
        "/onboarding": (context) => const OnboardingScreen(),
        "/login": (context) => const LoginScreen(),
        "/register": (context) => const RegisterScreen(),
        "/home": (context) => const MainNavigationScreen(),
        "/add-post": (context) => const AddPostScreen(),
        "/search": (context) => const SearchScreen(),
        "/favorites": (context) => const FavoritesScreen(),
        "/profile": (context) => const ProfileScreen(),
      },
    );
  }
}
