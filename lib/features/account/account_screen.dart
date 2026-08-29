import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/app/theme_controller.dart';
import 'package:music_app/features/welcome/welcome_screen.dart';
import 'package:music_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SpotifyColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Log Out?',
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textSecondary,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: SpotifyColors.green,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Log Out',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _signOut();
    }
  }

  Future<void> _signOut() async {
    // Only sign out from Firebase. Do NOT clear SharedPreferences here.
    // The LibraryService will handle fetching the correct data for the new/guest user.
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SpotifyColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                color: SpotifyColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open link.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: SpotifyColors.surfaceElevated,
        ),
      );
    }
  }

  void _showContactBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SpotifyColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Contact / Feedback',
                  style: GoogleFonts.plusJakartaSans(
                    color: SpotifyColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: SpotifyColors.textPrimary),
                  title: Text(
                    'Instagram',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '@biikkkuuuu',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    _launchURL('https://instagram.com/biikkkuuuu');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.telegram, color: SpotifyColors.textPrimary),
                  title: Text(
                    'Telegram',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '@biikkkuuuuu',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    _launchURL('https://t.me/biikkkuuuuu');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code_rounded, color: SpotifyColors.textPrimary),
                  title: Text(
                    'GitHub',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'biikkkuuuu/Ryvo',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    _launchURL('https://github.com/biikkkuuuu/Ryvo');
                  },
                ),
              ],
            ),
          ),
        );
      },
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 1: Playback Settings
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
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cache cleared successfully!',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white),
                        ),
                        backgroundColor: SpotifyColors.green.withValues(alpha: 0.8),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 2: About RYVO
          Text(
            'About RYVO',
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
                  leading: const Icon(Icons.music_note_rounded, color: SpotifyColors.textPrimary),
                  title: Text(
                    'RYVO — Music Reimagined',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    _showInfoDialog(
                      'RYVO',
                      'Music Reimagined. Built to provide a premium, uninterrupted ad-free music listening experience.',
                    );
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: SpotifyColors.textPrimary),
                  title: Text(
                    'Version 1.0.0',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: SpotifyColors.textPrimary),
                  title: Text(
                    'Terms & Conditions',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: SpotifyColors.textSecondary),
                  onTap: () {
                    _showInfoDialog(
                      'Terms & Conditions',
                      'By using RYVO, you agree to our standard terms of service. This app is for personal, non-commercial use only. Audio content is provided via third-party APIs.',
                    );
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: SpotifyColors.textPrimary),
                  title: Text(
                    'Privacy Policy',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: SpotifyColors.textSecondary),
                  onTap: () {
                    _showInfoDialog(
                      'Privacy Policy',
                      'RYVO values your privacy. We do not sell your personal data. Firebase Authentication is used solely for syncing your library and preferences securely.',
                    );
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.code_rounded, color: SpotifyColors.textPrimary),
                  title: Text(
                    'Open Source Licenses',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: SpotifyColors.textSecondary),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'RYVO',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded, color: SpotifyColors.textPrimary),
                  title: Text(
                    'Contact / Feedback',
                    style: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: SpotifyColors.textSecondary),
                  onTap: _showContactBottomSheet,
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
              onPressed: _confirmSignOut,
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

          const SizedBox(height: 40),

          Center(
            child: Text(
              'BUILT BY RANA',
              style: GoogleFonts.plusJakartaSans(
                color: SpotifyColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}