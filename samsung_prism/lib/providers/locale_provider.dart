import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale? _locale;
  final String _prefKey = 'languageCode';

  Locale? get locale => _locale;

  // List of supported locales
  final List<Locale> supportedLocales = const [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('bn'), // Bengali
    Locale('te'), // Telugu
    Locale('ta'), // Tamil
    Locale('kn'), // Kannada
    Locale('ml'), // Malayalam
    Locale('mr'), // Marathi
    Locale('gu'), // Gujarati
    Locale('pa'), // Punjabi
    Locale('or'), // Odia
    Locale('ur'), // Urdu
  ];

  // Map of language codes to their display names
  final Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'bn': 'বাংলা',
    'te': 'తెలుగు',
    'ta': 'தமிழ்',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
    'mr': 'मराठी',
    'gu': 'ગુજરાતી',
    'pa': 'ਪੰਜਾਬੀ',
    'or': 'ଓଡ଼ିଆ',
    'ur': 'اردو',
  };

  // Initialize the locale from shared preferences
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      // Default to device locale if available, otherwise English
      final deviceLocale = WidgetsBinding.instance.window.locale;
      _locale = supportedLocales.contains(deviceLocale) 
          ? deviceLocale 
          : const Locale('en');
      await prefs.setString(_prefKey, _locale!.languageCode);
    }
    notifyListeners();
  }

  // Change the app's locale
  Future<void> setLocale(Locale newLocale) async {
    if (!supportedLocales.contains(newLocale)) {
      return;
    }
    
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
    notifyListeners();
  }

  // Toggle between languages
  Future<void> toggleLanguage() async {
    if (_locale?.languageCode == 'en') {
      await setLocale(const Locale('hi'));
    } else {
      await setLocale(const Locale('en'));
    }
  }
}
