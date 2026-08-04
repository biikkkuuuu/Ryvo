import 'package:flutter/material.dart';
import 'package:music_app/features/welcome/welcome_screen.dart';

class RyvoApp extends StatelessWidget {
  const RyvoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "RYVO",
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          surface: Colors.black,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}