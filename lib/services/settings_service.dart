import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// User preferences. A singleton so services without a BuildContext
/// (notifications, background isolate) read the same values.
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _themeKey = 'app_theme_mode';
  static const _languageKey = 'app_language_code';
  static const _textSizeKey = 'text_size';
  static const _legacyTextScaleKey = 'text_scale';
  static const _simpleModeKey = 'simple_mode';
  static const _persistentAlarmKey = 'persistent_alarm';
  static const _readAloudKey = 'read_aloud';
  static const _userNameKey = 'user_name';
  static const _onboardingKey = 'onboarding_done';

  /// Normal, Large, Extra large. Normal is a bit smaller than the phone's
  /// default (the app's own sizes are already generous); the other two keep
  /// the same steps as before. Saved as the option's index (0-2).
  static const List<double> textScales = [0.88, 1.0, 1.14];

  ThemeMode _themeMode = ThemeMode.light;
  String _languageCode = 'en';
  double _textScale = textScales[0];
  bool _simpleMode = false;
  bool _persistentAlarm = true;
  bool _readAloud = true;
  String _userName = '';
  bool _onboardingDone = false;

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);
  bool get isArabic => _languageCode == 'ar';
  double get textScale => _textScale;
  bool get simpleMode => _simpleMode;
  bool get persistentAlarm => _persistentAlarm;
  bool get readAloud => _readAloud;

  /// Optional first name used in the greeting. Empty when not given.
  String get userName => _userName;
  bool get onboardingDone => _onboardingDone;

  /// Strings for code that has no BuildContext (notifications, PDF).
  AppLocalizations get strings => lookupAppLocalizations(locale);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    _themeMode = switch (prefs.getString(_themeKey)) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };

    final savedLanguage = prefs.getString(_languageKey);
    _languageCode =
        savedLanguage ??
        (PlatformDispatcher.instance.locale.languageCode == 'ar' ? 'ar' : 'en');
    if (_languageCode != 'ar') _languageCode = 'en';

    // Older versions saved the scale itself (1.0 / 1.15 / 1.3).
    final legacy = prefs.getDouble(_legacyTextScaleKey);
    final index =
        prefs.getInt(_textSizeKey) ??
        (legacy == null ? 0 : const [1.0, 1.15, 1.3].indexOf(legacy));
    _textScale = textScales[index.clamp(0, textScales.length - 1)];
    _simpleMode = prefs.getBool(_simpleModeKey) ?? false;
    _persistentAlarm = prefs.getBool(_persistentAlarmKey) ?? true;
    _readAloud = prefs.getBool(_readAloudKey) ?? true;
    _userName = prefs.getString(_userNameKey) ?? '';
    // People who already have medications saved skip the setup screens.
    _onboardingDone =
        prefs.getBool(_onboardingKey) ?? prefs.containsKey('user_pills');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> setLanguageCode(String code) async {
    final normalized = code == 'ar' ? 'ar' : 'en';
    if (_languageCode == normalized) return;
    _languageCode = normalized;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, normalized);
  }

  Future<void> setTextScale(double scale) async {
    if (!textScales.contains(scale) || _textScale == scale) return;
    _textScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_textSizeKey, textScales.indexOf(scale));
    await prefs.remove(_legacyTextScaleKey);
  }

  Future<void> setSimpleMode(bool value) async {
    if (_simpleMode == value) return;
    _simpleMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simpleModeKey, value);
  }

  Future<void> setPersistentAlarm(bool value) async {
    if (_persistentAlarm == value) return;
    _persistentAlarm = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_persistentAlarmKey, value);
  }

  Future<void> setReadAloud(bool value) async {
    if (_readAloud == value) return;
    _readAloud = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_readAloudKey, value);
  }

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    if (_userName == trimmed) return;
    _userName = trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, trimmed);
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
