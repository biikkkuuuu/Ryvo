import 'package:flutter/material.dart';
import 'package:music_app/features/splash/splash_screen.dart';


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.graphic_eq_rounded,
                size: 90,
                color: Color(0xFF8B5CF6),
              ),
              SizedBox(height: 24),
              Text(
                'RYVO',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Music Reimagined',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}