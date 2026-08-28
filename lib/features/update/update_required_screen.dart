import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredScreen extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String updateUrl;

  const UpdateRequiredScreen({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateUrl,
  });

  Future<void> _launchUpdateUrl(BuildContext context) async {
    if (updateUrl.isEmpty) {
      _showError(context, 'Update link is currently unavailable.');
      return;
    }

    final Uri url = Uri.parse(updateUrl);
    try {
      final canLaunch = await canLaunchUrl(url);
      if (canLaunch) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) _showError(context, 'Could not open update link.');
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Something went wrong while opening the link.');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SpotifyColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PopScope ensures the user CANNOT dismiss this screen using Android Back button
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SpotifyColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                
                // RYVO App Icon (Same exactly as Welcome Screen)
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
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
                
                const SizedBox(height: 40),

                Text(
                  'Update Required',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: SpotifyColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  "You're using an older version of RYVO. Please update to continue enjoying the app.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: SpotifyColors.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),
                
                // Version Info Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: SpotifyColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Current Version: $currentVersion',
                        style: GoogleFonts.plusJakartaSans(
                          color: SpotifyColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Latest Version: $latestVersion',
                        style: GoogleFonts.plusJakartaSans(
                          color: SpotifyColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Update Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _launchUpdateUrl(context),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: SpotifyColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'UPDATE NOW',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}