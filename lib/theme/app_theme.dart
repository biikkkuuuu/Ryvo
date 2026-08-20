import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpotifyColors {
  SpotifyColors._();

  // Core Spotify Palette
  static const Color green = Color(0xFF1ED760);
  static const Color greenDark = Color(0xFF1DB954);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF181818);
  static const Color surfaceElevated = Color(0xFF242424);
  static const Color surfaceHighlight = Color(0xFF2A2A2A);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF727272);

  // Accent Colors for Categories
  static const List<Color> categoryGradients = [
    Color(0xFFE91429), // Red
    Color(0xFF1E3264), // Blue
    Color(0xFFE8115B), // Pink
    Color(0xFF8D67AB), // Purple
    Color(0xFF006450), // Teal
    Color(0xFFBA5D07), // Orange
    Color(0xFF477D95), // Slate
    Color(0xFF503750), // Maroon
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme({Color primary = SpotifyColors.green}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SpotifyColors.background,
      primaryColor: primary,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primary.withValues(alpha: 0.8),
        surface: SpotifyColors.surface,
        surfaceContainerHighest: SpotifyColors.surfaceElevated,
        onPrimary: Colors.black,
        onSurface: SpotifyColors.textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: SpotifyColors.textPrimary,
        displayColor: SpotifyColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SpotifyColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: SpotifyColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: SpotifyColors.textPrimary,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: Colors.white24,
        thumbColor: SpotifyColors.textPrimary,
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      cardTheme: CardThemeData(
        color: SpotifyColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
