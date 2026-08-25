import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static const String _keyGraceCount = 'grace_count';
  static const String _keyLastDate = 'last_date';

  // Vráti číslo od 0 do 3 (koľko pokusov zostáva)
  static Future<int> getRemainingGraceAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final lastDate = prefs.getString(_keyLastDate) ?? '';

    if (lastDate != today) {
      await prefs.setString(_keyLastDate, today);
      await prefs.setInt(_keyGraceCount, 0);
      return 3;
    }

    int usedCount = prefs.getInt(_keyGraceCount) ?? 0;
    return 3 - usedCount;
  }

  // Ak zostávajú pokusy, jeden odpočíta
  static Future<bool> useGraceAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    int remaining = await getRemainingGraceAttempts();
    
    if (remaining > 0) {
      int usedCount = prefs.getInt(_keyGraceCount) ?? 0;
      await prefs.setInt(_keyGraceCount, usedCount + 1);
      return true;
    }
    return false;
  }

  static String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }
}