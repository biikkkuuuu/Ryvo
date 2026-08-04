import 'package:flutter/material.dart';
import 'package:music_app/features/splash/splash_screen.dart';
class RyvoApp extends StatelessWidget {
  const RyvoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}