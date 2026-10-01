import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance =
      ThemeService._internal();

  factory ThemeService() => _instance;

  ThemeService._internal();

  static const String _themeKey =
      'app_theme_mode';

  ThemeMode _themeMode =
      ThemeMode.light;

  ThemeMode get themeMode =>
      _themeMode;

  bool get isDarkMode =>
      _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedTheme =
        prefs.getString(_themeKey);

    _themeMode =
        savedTheme == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  Future<void> setDarkMode(
    bool isDark,
  ) async {
    final nextMode =
        isDark
            ? ThemeMode.dark
            : ThemeMode.light;

    if (_themeMode == nextMode) {
      return;
    }

    _themeMode = nextMode;
    notifyListeners();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _themeKey,
      isDark
          ? 'dark'
          : 'light',
    );
  }

  Future<void> toggleTheme() async {
    await setDarkMode(
      !isDarkMode,
    );
  }
}
