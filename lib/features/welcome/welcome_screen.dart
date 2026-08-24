import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/features/onboarding/music_preferences_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:music_app/features/home/home_screen.dart';
import 'package:music_app/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '479625784257-m4515prj3c949i5r2mb6locuoljvao9e.apps.googleusercontent.com',
      );

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!context.mounted) return;

      _goToHome(context);
    } on GoogleSignInException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google sign-in failed: ${e.description ?? e.code.name}',
          ),
          backgroundColor: SpotifyColors.surfaceElevated,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Authentication failed: ${e.message ?? e.code}',
          ),
          backgroundColor: SpotifyColors.surfaceElevated,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: $e'),
          backgroundColor: SpotifyColors.surfaceElevated,
        ),
      );
    }
  }

  Future<void> _goToHome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final completed =
        prefs.getBool('ryvo_music_preferences_completed') ?? false;

    if (!context.mounted) return;

    if (!completed) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MusicPreferencesScreen(),
        ),
      );

      if (!context.mounted) return;

      if (result == true) {
        _openHome(context);
      }

      return;
    }

    _openHome(context);
  }

  void _openHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpotifyColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Centered App Icon with Halo Glow & Premium Border
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. The Glowing Halo behind the icon
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            SpotifyColors.green.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0.1, 1.0],
                        ),
                      ),
                    ),
                    
                    // 2. The App Icon with sleek border and shadow
                    Hero(
                      tag: 'ryvo_logo',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1), // Subtle glassy border
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 24,
                              spreadRadius: 4,
                              offset: const Offset(0, 8), // Drop shadow for depth
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: const Image(
                            image: AssetImage('assets/icon/ryvo_icon.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'RYVO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: SpotifyColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Music Reimagined.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(flex: 3),

              // Google Sign In Pill Button (Spotify Green)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _signInWithGoogle(context),
                  icon: const Icon(
                    Icons.g_mobiledata,
                    size: 32,
                    color: Colors.black,
                  ),
                  label: Text(
                    'Continue with Google',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: SpotifyColors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Guest Button (Clean Outline Pill)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _goToHome(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.white24,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'By continuing you agree to RYVO Terms & Privacy Policy',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textMuted,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}