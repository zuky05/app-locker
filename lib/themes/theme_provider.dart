import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

class ThemeProvider extends ChangeNotifier {
  // Statické zistenie ID bezplatnej témy (Clean Minimal)
  static int get _defaultThemeId => AppThemes.availableThemes.firstWhere(
        (t) => !t.isPremium,
        orElse: () => AppThemes.availableThemes[0],
      ).id;

  // Hneď pri vytvorení nastavené na Clean Minimal namiesto 0
  int _currentThemeId = _defaultThemeId;

  AppThemeData get currentThemeData => AppThemes.availableThemes.firstWhere(
        (t) => t.id == _currentThemeId,
        orElse: () => AppThemes.availableThemes.firstWhere(
          (t) => !t.isPremium,
          orElse: () => AppThemes.availableThemes[0],
        ),
      );

  ThemeData get theme => currentThemeData.theme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentThemeId = prefs.getInt('selected_theme_id') ?? _defaultThemeId;
    notifyListeners();
  }

  Future<void> setTheme(int themeId) async {
    _currentThemeId = themeId;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_theme_id', themeId);
  }
}