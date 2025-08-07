import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('fr'); // Français par défaut

  Locale get currentLocale => _currentLocale;

  LanguageService() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'fr';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> changeLanguage(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
    notifyListeners();
  }

  List<Map<String, dynamic>> get supportedLanguages => [
        {
          'code': 'fr',
          'name': 'Français',
          'flag': '🇫🇷',
          'locale': const Locale('fr'),
        },
        {
          'code': 'en',
          'name': 'English',
          'flag': '🇺🇸',
          'locale': const Locale('en'),
        },
      ];
}
