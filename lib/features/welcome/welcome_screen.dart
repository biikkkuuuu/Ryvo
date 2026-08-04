import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [

              const Spacer(),

              const Icon(
                Icons.graphic_eq_rounded,
                size: 90,
                color: Color(0xff8B5CF6),
              ),

              const SizedBox(height: 30),

              Text(
                "RYVO",
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Music Reimagined",
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 16,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("Continue with Google"),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text("Continue as Guest"),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "Terms • Privacy",
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}