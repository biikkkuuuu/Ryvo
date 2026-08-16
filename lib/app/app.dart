import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:music_app/app/theme_controller.dart';
import 'package:music_app/features/home/home_screen.dart';
import 'package:music_app/features/welcome/welcome_screen.dart';

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

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: theme.primary,
        secondary: theme.primaryLight,
        primaryContainer: theme.primaryDark,
        surface: Colors.black,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: theme.primaryLight,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return theme.primaryLight;
            }
            return Colors.white54;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return theme.primaryDark;
            }
            return Colors.white12;
          },
        ),
      ),
    );
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
