import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChallengeType {
  completeQuizzes,       // Dokonči X testov
  earnMinutes,           // Získaj X minút času
  learnCards,            // Prejdi X kartičiek v Learning Mode
  perfectQuiz,           // Dokonči 1 test na 100%

  // Samostatné modifikátory
  modifier3Options,      // Test s "3 Možnosti"
  modifierSwapQuestion,  // Test s "Vymeň kartu"
  modifierSecondChance,  // Test s "Druhá šanca"
  modifierConfusion,     // Test s "Confusion"
  modifierBlindTest,     // Test s "Slepý test"
  modifierDoubleTest,    // Test s "Double Test"
  modifierHardcore,      // Test s "Hardcore"

  // Kombinácie a špeciálne výzvy
  atLeast3Modifiers,     // Test s min. 3 modifikátormi naraz
  comboConfusionAndBlind, // Confusion + Slepý test
  comboDoubleAndBlind,   // Double Test + Slepý test
  comboSecondChanceAndSwap, // Druhá šanca + Vymeň kartu
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int target;
  final int bonusSeconds;
  final String iconEmoji;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.bonusSeconds,
    required this.iconEmoji,
  });
}

class DailyChallengeService {
  static const String _prefKeyLastDate = 'dc_last_date';
  static const String _prefKeyProgress = 'dc_progress';
  static const String _prefKeyCompleted = 'dc_completed';
  static const String _prefKeyCurrentStreak = 'dc_current_streak';
  static const String _prefKeyMaxStreak = 'dc_max_streak';
  static const String _prefKeyTotalCompleted = 'dc_total_completed';
  static const String _prefKeyChallengeIndex = 'dc_challenge_index';

  static final List<DailyChallenge> _challengePool = [
    DailyChallenge(
      id: 'quizzes_2',
      title: 'Kvízový maratón',
      description: 'Dokonči úspešne 2 testy',
      type: ChallengeType.completeQuizzes,
      target: 2,
      bonusSeconds: 300,
      iconEmoji: '🎯',
    ),
    DailyChallenge(
      id: 'earn_10_min',
      title: 'Lovca času',
      description: 'Získaj celkovo 10 minút odomknutého času',
      type: ChallengeType.earnMinutes,
      target: 600,
      bonusSeconds: 300,
      iconEmoji: '⏳',
    ),
    DailyChallenge(
      id: 'learn_15_cards',
      title: 'Študijný režim',
      description: 'Prejdi 15 kartičiek v režime učenia (Learning Mode)',
      type: ChallengeType.learnCards,
      target: 15,
      bonusSeconds: 180,
      iconEmoji: '📚',
    ),
    DailyChallenge(
      id: 'perfect_1',
      title: 'Perfektný zásah',
      description: 'Dokonči 1 test s 100% úspešnosťou',
      type: ChallengeType.perfectQuiz,
      target: 1,
      bonusSeconds: 360,
      iconEmoji: '🌟',
    ),
    DailyChallenge(
      id: 'mod_3options',
      title: 'Ľahšia voľba',
      description: 'Zvládni test s modifikátorom "3 Možnosti"',
      type: ChallengeType.modifier3Options,
      target: 1,
      bonusSeconds: 180,
      iconEmoji: '☘️',
    ),
    DailyChallenge(
      id: 'mod_swap',
      title: 'Taktická výmena',
      description: 'Zvládni test s modifikátorom "Vymeň kartu"',
      type: ChallengeType.modifierSwapQuestion,
      target: 1,
      bonusSeconds: 210,
      iconEmoji: '🔄',
    ),
    DailyChallenge(
      id: 'mod_second_chance',
      title: 'Bezpečný návrat',
      description: 'Zvládni test s modifikátorom "Druhá šanca"',
      type: ChallengeType.modifierSecondChance,
      target: 1,
      bonusSeconds: 210,
      iconEmoji: '🛡️',
    ),
    DailyChallenge(
      id: 'mod_confusion',
      title: 'Nenechaj sa zmýliť',
      description: 'Zvládni test s modifikátorom "Confusion"',
      type: ChallengeType.modifierConfusion,
      target: 1,
      bonusSeconds: 300,
      iconEmoji: '❓',
    ),
    DailyChallenge(
      id: 'mod_blind',
      title: 'Viera vo vedomosti',
      description: 'Zvládni test s modifikátorom "Slepý test"',
      type: ChallengeType.modifierBlindTest,
      target: 1,
      bonusSeconds: 360,
      iconEmoji: '🙈',
    ),
    DailyChallenge(
      id: 'mod_double',
      title: 'Dvojitá výzva',
      description: 'Zvládni test s modifikátorom "Double Test"',
      type: ChallengeType.modifierDoubleTest,
      target: 1,
      bonusSeconds: 420,
      iconEmoji: '⚡',
    ),
    DailyChallenge(
      id: 'mod_hardcore',
      title: 'Hardcore majster',
      description: 'Zvládni test v "Hardcore (Write-in)" režime',
      type: ChallengeType.modifierHardcore,
      target: 1,
      bonusSeconds: 480,
      iconEmoji: '💀',
    ),
    DailyChallenge(
      id: 'mod_at_least_3',
      title: 'Kombinačný špecialista',
      description: 'Dokonči test so zapnutými MINIMÁLNE 3 modifikátormi naraz',
      type: ChallengeType.atLeast3Modifiers,
      target: 1,
      bonusSeconds: 500,
      iconEmoji: '🔥',
    ),
    DailyChallenge(
      id: 'combo_confusion_blind',
      title: 'Slepý chaotik',
      description: 'Zvládni test s modifikátormi "Confusion" + "Slepý test"',
      type: ChallengeType.comboConfusionAndBlind,
      target: 1,
      bonusSeconds: 450,
      iconEmoji: '🌀',
    ),
    DailyChallenge(
      id: 'combo_double_blind',
      title: 'Dvojitá tma',
      description: 'Zvládni test s modifikátormi "Double Test" + "Slepý test"',
      type: ChallengeType.comboDoubleAndBlind,
      target: 1,
      bonusSeconds: 540,
      iconEmoji: '🌌',
    ),
    DailyChallenge(
      id: 'combo_second_swap',
      title: 'Maximálna poistka',
      description: 'Zvládni test s modifikátormi "Druhá šanca" + "Vymeň kartu"',
      type: ChallengeType.comboSecondChanceAndSwap,
      target: 1,
      bonusSeconds: 300,
      iconEmoji: '🛟',
    ),
  ];

  static Future<DailyChallenge> getTodayChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final lastDate = prefs.getString(_prefKeyLastDate) ?? '';

    int challengeIndex;

    if (lastDate != today) {
      final seed = DateTime.now().year * 10000 + DateTime.now().month * 100 + DateTime.now().day;
      final rng = Random(seed);
      challengeIndex = rng.nextInt(_challengePool.length);

      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toString().split(' ')[0];
      final lastCompletedDate = prefs.getString('${_prefKeyCompleted}_date') ?? '';
      
      if (lastCompletedDate != yesterday && lastCompletedDate != today) {
        await prefs.setInt(_prefKeyCurrentStreak, 0);
      }

      await prefs.setString(_prefKeyLastDate, today);
      await prefs.setInt(_prefKeyChallengeIndex, challengeIndex);
      await prefs.setInt(_prefKeyProgress, 0);
      await prefs.setBool(_prefKeyCompleted, false);
    } else {
      challengeIndex = prefs.getInt(_prefKeyChallengeIndex) ?? 0;
    }

    return _challengePool[challengeIndex % _challengePool.length];
  }

  static Future<Map<String, dynamic>> getTodayChallengeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final challenge = await getTodayChallenge();

    final progress = prefs.getInt(_prefKeyProgress) ?? 0;
    final isCompleted = prefs.getBool(_prefKeyCompleted) ?? false;
    final currentStreak = prefs.getInt(_prefKeyCurrentStreak) ?? 0;
    final maxStreak = prefs.getInt(_prefKeyMaxStreak) ?? 0;
    final totalCompleted = prefs.getInt(_prefKeyTotalCompleted) ?? 0;

    return {
      'challenge': challenge,
      'progress': progress,
      'isCompleted': isCompleted,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'totalCompleted': totalCompleted,
    };
  }

  static Future<int> reportProgress({
    required ChallengeType type,
    int amount = 1,
    double accuracy = 0.0,
    bool is3Options = false,
    bool isSwapQuestion = false,
    bool isSecondChance = false,
    bool isConfusion = false,
    bool isBlindTest = false,
    bool isDoubleTest = false,
    bool isHardcore = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final status = await getTodayChallengeStatus();
    final challenge = status['challenge'] as DailyChallenge;

    if (status['isCompleted'] == true) return 0;

    int activeModifiersCount = 0;
    if (is3Options) activeModifiersCount++;
    if (isSwapQuestion) activeModifiersCount++;
    if (isSecondChance) activeModifiersCount++;
    if (isConfusion) activeModifiersCount++;
    if (isBlindTest) activeModifiersCount++;
    if (isDoubleTest) activeModifiersCount++;
    if (isHardcore) activeModifiersCount++;

    bool matchesChallenge = false;

    switch (challenge.type) {
      case ChallengeType.completeQuizzes:
      case ChallengeType.earnMinutes:
      case ChallengeType.learnCards:
        matchesChallenge = (type == challenge.type);
        break;

      case ChallengeType.perfectQuiz:
        matchesChallenge = (type == ChallengeType.completeQuizzes && accuracy >= 1.0);
        break;

      case ChallengeType.modifier3Options:
        matchesChallenge = (type == ChallengeType.completeQuizzes && is3Options);
        break;
      case ChallengeType.modifierSwapQuestion:
        matchesChallenge = (type == ChallengeType.completeQuizzes && isSwapQuestion);
        break;
      case ChallengeType.modifierSecondChance:
        matchesChallenge = (type == ChallengeType.completeQuizzes && isSecondChance);
        break;
      case ChallengeType.modifierConfusion:
        matchesChallenge = (type == ChallengeType.completeQuizzes && isConfusion);
        break;
      case ChallengeType.modifierBlindTest:
        matchesChallenge = (type == ChallengeType.completeQuizzes && isBlindTest);
        break;
      case ChallengeType.modifierDoubleTest:
        matchesChallenge = (type == ChallengeType.completeQuizzes && isDoubleTest);
        break;
      case ChallengeType.modifierHardcore:
        matchesChallenge = (type == ChallengeType.completeQuizzes && isHardcore);
        break;

      case ChallengeType.atLeast3Modifiers:
        matchesChallenge = (type == ChallengeType.completeQuizzes && activeModifiersCount >= 3);
        break;
      case ChallengeType.comboConfusionAndBlind:
        matchesChallenge = (type == ChallengeType.completeQuizzes && isConfusion && isBlindTest);
        break;
      case ChallengeType.comboDoubleAndBlind:
        matchesChallenge = (type == ChallengeType.completeQuizzes && isDoubleTest && isBlindTest);
        break;
      case ChallengeType.comboSecondChanceAndSwap:
        matchesChallenge = (type == ChallengeType.completeQuizzes && isSecondChance && isSwapQuestion);
        break;
    }

    if (!matchesChallenge) return 0;

    int currentProgress = status['progress'] as int;
    int newProgress = currentProgress + amount;
    if (newProgress > challenge.target) newProgress = challenge.target;

    await prefs.setInt(_prefKeyProgress, newProgress);

    if (newProgress >= challenge.target) {
      await prefs.setBool(_prefKeyCompleted, true);

      final today = _getTodayString();
      await prefs.setString('${_prefKeyCompleted}_date', today);

      int currentStreak = (status['currentStreak'] as int) + 1;
      int maxStreak = status['maxStreak'] as int;
      if (currentStreak > maxStreak) maxStreak = currentStreak;

      int totalCompleted = (status['totalCompleted'] as int) + 1;

      await prefs.setInt(_prefKeyCurrentStreak, currentStreak);
      await prefs.setInt(_prefKeyMaxStreak, maxStreak);
      await prefs.setInt(_prefKeyTotalCompleted, totalCompleted);

      // Vráti výšku odmeny. Ukladanie do DB robí QuizOverlayScreen v jednom balíku.
      return challenge.bonusSeconds;
    }

    return 0;
  }

  static String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
}