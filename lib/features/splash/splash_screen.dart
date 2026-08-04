import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.graphic_eq_rounded,
              size: 90,
              color: Color(0xFF8B5CF6),
            )
                .animate()
                .fadeIn(duration: 700.ms)
                .scale(),

            const SizedBox(height: 24),

            Text(
              "RYVO",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.4),

            const SizedBox(height: 10),

            Text(
              "Music Reimagined",
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 16,
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}