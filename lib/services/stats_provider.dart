import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class StatsProvider extends ChangeNotifier {
  bool isLoading = true;

  int _currentStreak = 0;
  Map<String, dynamic> _todayStats = {'cards': 0, 'timeMinutes': 0, 'accuracy': 0};
  Map<String, dynamic> _weekStats = {'cards': 0, 'timeMinutes': 0, 'accuracy': 0};
  Map<String, dynamic> _lifetimeStats = {'cards': 0, 'timeMinutes': 0, 'accuracy': 0};

  int get currentStreak => _currentStreak;
  Map<String, dynamic> get todayStats => _todayStats;
  Map<String, dynamic> get weekStats => _weekStats;
  Map<String, dynamic> get lifetimeStats => _lifetimeStats;

  StatsProvider() {
    refreshStats();
  }

  Future<void> refreshStats() async {
    isLoading = true;
    notifyListeners();

    _currentStreak = await DatabaseHelper.instance.getCurrentStreak();
    _todayStats = await DatabaseHelper.instance.getAggregatedStats(0);
    _weekStats = await DatabaseHelper.instance.getAggregatedStats(1);
    _lifetimeStats = await DatabaseHelper.instance.getAggregatedStats(2);

    isLoading = false;
    notifyListeners();
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