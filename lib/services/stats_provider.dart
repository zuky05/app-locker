import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class StatsProvider extends ChangeNotifier {
  bool isLoading = true;
  int _currentStreak = 0;

  static Map<String, dynamic> _defaultStats(bool isEn) => {
        'cards': 0,
        'earnedSeconds': 0,
        'time': 0,
        'timeMinutes': 0,
        'accuracy': 0,
        'sessions': 0,
        'favoriteDeck': isEn ? 'None' : 'Žiadny',
        'nemesisPrompt': isEn ? 'None' : 'Žiadna',
        'nemesisAnswer': '',
      };

  Map<String, dynamic> _todayStats = _defaultStats(false);
  Map<String, dynamic> _weekStats = _defaultStats(false);
  Map<String, dynamic> _lifetimeStats = _defaultStats(false);

  int get currentStreak => _currentStreak;
  Map<String, dynamic> get todayStats => _todayStats;
  Map<String, dynamic> get weekStats => _weekStats;
  Map<String, dynamic> get lifetimeStats => _lifetimeStats;

  StatsProvider() {
    refreshStats();
  }

  Future<void> loadTodayStats() => refreshStats();

  Future<void> refreshStats() async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'en';
    final bool isEn = lang == 'en';

    _currentStreak = await DatabaseHelper.instance.getCurrentStreak();

    _todayStats = await _fetchPeriodData(0, isEn);
    _weekStats = await _fetchPeriodData(1, isEn);
    _lifetimeStats = await _fetchPeriodData(2, isEn);

    isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _fetchPeriodData(int filterIndex, bool isEn) async {
    final baseStats = await DatabaseHelper.instance.getAggregatedStats(filterIndex);
    final favDeck = await DatabaseHelper.instance.getFavoriteDeckName(filterIndex);
    final nemesisDetails = await DatabaseHelper.instance.getNemesisCardDetails();

    return {
      ...baseStats,
      'time': baseStats['earnedSeconds'] ?? 0,
      'favoriteDeck': favDeck ?? (isEn ? 'None' : 'Žiadny'),
      'nemesisPrompt': nemesisDetails?['prompt'] ?? (isEn ? 'None' : 'Žiadna'),
      'nemesisAnswer': nemesisDetails?['correct_answer'] ?? '',
    };
  }

  Map<String, dynamic> getStatsForPeriod(int filterIndex) {
    switch (filterIndex) {
      case 0:
        return _todayStats;
      case 1:
        return _weekStats;
      case 2:
        return _lifetimeStats;
      default:
        return _todayStats;
    }
  }
}