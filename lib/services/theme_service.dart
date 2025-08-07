import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeService() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final themeString = _prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere((e) => e.toString().split('.').last == themeString, orElse: () => ThemeMode.system);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await _prefs.setString('themeMode', themeMode.toString().split('.').last);
    notifyListeners();
  }
}
