import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'languages.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale;

  // Ak sa neodovzdá žiaden jazyk, predvolená bude angličtina 'en'
  LocaleProvider([String initialLocale = 'en']) : _locale = initialLocale;

  String get locale => _locale;

  // Rýchly getter, ktorý vráti správny slovník
  AppTexts get t => _locale == 'sk' ? textsSk : textsEn;

  Future<void> setLocale(String languageCode) async {
    if (_locale == languageCode) return;
    _locale = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
    notifyListeners(); // Prekreslí UI pri zmene
  }
}