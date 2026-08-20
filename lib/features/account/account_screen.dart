import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/app/theme_controller.dart';
import 'package:music_app/features/welcome/welcome_screen.dart';
import 'package:music_app/theme/app_theme.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get _user => _auth.currentUser;

  bool get _isGuest {
    final user = _user;
    if (user == null) return true;
    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    if (isGoogle) return false;
    return user.isAnonymous;
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final displayName = _isGuest
        ? 'Guest User'
        : (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'RYVO Listener');

    final email = _isGuest
        ? 'Signed in as guest'
        : (user?.email?.trim().isNotEmpty == true
            ? user!.email!.trim()
            : 'Premium Member');

    final currentThemeIndex = RyvoThemeController.instance.selectedTheme;
    final currentTheme = RyvoThemeController.themes[currentThemeIndex];

    return Scaffold(
      backgroundColor: SpotifyColors.background,
      appBar: AppBar(
        backgroundColor: SpotifyColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account & Settings',
          style: GoogleFonts.plusJakartaSans(
            color: SpotifyColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Profile Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SpotifyColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: currentTheme.primaryDark,
                  backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: (user?.photoURL == null || user!.photoURL!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white, size: 36)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.plusJakartaSans(
                          color: SpotifyColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: GoogleFonts.plusJakartaSans(
                          color: SpotifyColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: currentTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isGuest ? 'GUEST' : 'FREE PLAN',
                          style: GoogleFonts.plusJakartaSans(
                            color: currentTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 1: Appearance & Accent Colors
          Text(
            'Theme Accent',
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SpotifyColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: List.generate(RyvoThemeController.themes.length, (index) {
                final theme = RyvoThemeController.themes[index];
                final isSelected = currentThemeIndex == index;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    RyvoThemeController.instance.setTheme(index);
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primary,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                theme.name,
                                style: GoogleFonts.plusJakartaSans(
                                  color: SpotifyColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                theme.subtitle,
                                style: GoogleFonts.plusJakartaSans(
                                  color: SpotifyColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: theme.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 28),

          // Section 2: Audio & Playback
          Text(
            'Playback Settings',
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: SpotifyColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.high_quality_rounded, color: SpotifyColors.textPrimary),
                  title: Text(
                    'Audio Quality',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'High (320 kbps streaming)',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: SpotifyColors.textSecondary),
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: SpotifyColors.textPrimary),
                  title: Text(
                    'Clear Cache',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Free up storage space',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared successfully!')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Sign out / Account Action
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                _isGuest ? 'Back to Login' : 'Log Out',
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              'RYVO Music • Version 1.0.0',
              style: GoogleFonts.plusJakartaSans(
                color: SpotifyColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
