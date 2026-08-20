import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:music_app/app/theme_controller.dart';
import 'package:music_app/features/home/home_screen.dart';
import 'package:music_app/features/welcome/welcome_screen.dart';
import 'package:music_app/theme/app_theme.dart';

class RyvoApp extends StatefulWidget {
  const RyvoApp({super.key});

  @override
  State<RyvoApp> createState() => _RyvoAppState();
}

class _RyvoAppState extends State<RyvoApp> {
  final RyvoThemeController _themeController =
      RyvoThemeController.instance;

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onThemeChanged);
    _themeController.load();
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  ThemeData _buildTheme() {
    final theme =
    RyvoThemeController.themes[_themeController.selectedTheme];

    return AppTheme.buildTheme(primary: theme.primary);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RYVO',
      theme: _buildTheme(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(
                  color: RyvoThemeController
                      .themes[_themeController.selectedTheme]
                      .primaryLight,
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const WelcomeScreen();
        },
      ),
    );
  }
}
