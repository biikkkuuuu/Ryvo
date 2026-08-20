import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RyvoThemeController extends ChangeNotifier {
  RyvoThemeController._();

  static final RyvoThemeController instance =
  RyvoThemeController._();

  static const String _themeKey =
      'ryvo_selected_theme';

  int _selectedTheme = 0;

  int get selectedTheme => _selectedTheme;

  Future<void> load() async {
    final prefs =
    await SharedPreferences.getInstance();

    final saved = prefs.getInt(_themeKey);

    if (saved != null &&
        saved >= 0 &&
        saved < themes.length) {
      _selectedTheme = saved;
      notifyListeners();
    }
  }

  Future<void> setTheme(int index) async {
    if (index < 0 || index >= themes.length) {
      return;
    }

    _selectedTheme = index;
    notifyListeners();

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setInt(
      _themeKey,
      index,
    );
  }

  static const List<RyvoThemeData> themes = [
    RyvoThemeData(
      name: 'Spotify Green',
      subtitle: 'Classic Emerald',
      primary: Color(0xff1ED760),
      primaryLight: Color(0xff1DB954),
      primaryDark: Color(0xff0e682e),
    ),
    RyvoThemeData(
      name: 'Aurora',
      subtitle: 'RYVO Purple',
      primary: Color(0xff8B5CF6),
      primaryLight: Color(0xffA78BFA),
      primaryDark: Color(0xff5B21B6),
    ),
    RyvoThemeData(
      name: 'Ocean',
      subtitle: 'Cool Blue',
      primary: Color(0xff0EA5E9),
      primaryLight: Color(0xff38BDF8),
      primaryDark: Color(0xff0369A1),
    ),
    RyvoThemeData(
      name: 'Sunset',
      subtitle: 'Warm Orange',
      primary: Color(0xffF97316),
      primaryLight: Color(0xffFB923C),
      primaryDark: Color(0xffC2410C),
    ),
  ];
}

class RyvoThemeData {
  final String name;
  final String subtitle;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  const RyvoThemeData({
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
  });
}