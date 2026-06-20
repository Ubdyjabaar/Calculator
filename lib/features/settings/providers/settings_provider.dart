import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _hapticFeedback = true;
  int _precision = 10;
  Color _seedColor = const Color(0xFF7C4DFF);

  ThemeMode get themeMode => _themeMode;
  bool get hapticFeedback => _hapticFeedback;
  int get precision => _precision;
  Color get seedColor => _seedColor;
  bool get isDark => _themeMode == ThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        (prefs.getBool('isDark') ?? true) ? ThemeMode.dark : ThemeMode.light;
    _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
    _precision = prefs.getInt('precision') ?? 10;
    final seed = prefs.getInt('seedColor');
    if (seed != null) _seedColor = Color(seed);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', mode == ThemeMode.dark);
  }

  Future<void> toggleTheme() async {
    await setThemeMode(
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticFeedback', value);
  }

  Future<void> setPrecision(int value) async {
    _precision = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('precision', value);
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', color.toARGB32());
  }

  void trigger() => notifyListeners();
}
