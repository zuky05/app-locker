import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/deck_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flashpass.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // 🟢 Zvýšená verzia pre podporu jazykov v balíčkoch (front_lang, back_lang)
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        is_premade INTEGER NOT NULL,
        front_lang TEXT NOT NULL DEFAULT 'en-US',
        back_lang TEXT NOT NULL DEFAULT 'en-US'
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL,
        prompt TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        counter INTEGER NOT NULL,
        wrong_count INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        deck_id INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        earned_seconds INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL,
        total_questions INTEGER NOT NULL
      )
    ''');

    await _seedPremadeDecks(db);
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE cards ADD COLUMN wrong_count INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE study_sessions ADD COLUMN earned_seconds INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
      await db.execute('UPDATE study_sessions SET correct_count = total_questions WHERE correct_count > total_questions AND total_questions > 0');
    }
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE decks ADD COLUMN front_lang TEXT NOT NULL DEFAULT 'en-US'");
        await db.execute("ALTER TABLE decks ADD COLUMN back_lang TEXT NOT NULL DEFAULT 'en-US'");
      } catch (_) {}
    }
  }

  Future<void> _seedPremadeDecks(Database db) async {
    try {
      final jsonString = await rootBundle.loadString('assets/decks/premade_decks.json');
      final List<dynamic> deckList = jsonDecode(jsonString);
      for (var d in deckList) {
        final deckId = await db.insert('decks', {
          'name': d['name'],
          'category': d['category'],
          'is_premade': 1,
          'front_lang': d['front_lang'] ?? 'en-US',
          'back_lang': d['back_lang'] ?? 'en-US',
        });

        for (var c in d['cards']) {
          await db.insert('cards', {
            'deck_id': deckId,
            'prompt': c['prompt'],
            'correct_answer': c['correct_answer'],
            'counter': 0,
            'wrong_count': 0,
          });
        }
      }
    } catch (e) {
      debugPrint("Database seeding error: $e");
    }
  }

  Future<List<Deck>> getDecks() async {
    final db = await instance.database;
    final result = await db.query('decks');
    return result.map((json) => Deck.fromMap(json)).toList();
  }

  Future<int> addNewDeck(String name, String category, {String frontLang = 'en-US', String backLang = 'en-US'}) async {
    final db = await instance.database;
    final deckId = await db.insert('decks', {
      'name': name,
      'category': category,
      'is_premade': 0,
      'front_lang': frontLang,
      'back_lang': backLang,
    });
    return deckId;
  }

  Future<void> removeCard(int id) async {
    final db = await instance.database;
    await db.rawDelete('DELETE FROM cards WHERE id = ?', [id]);
  }

  Future<void> addNewCard(int deckId, String prompt, String correctAnswer) async {
    final db = await instance.database;
    
    await db.insert('cards', {
      'deck_id': deckId,
      'prompt': prompt,
      'correct_answer': correctAnswer,
      'counter': 0,
      'wrong_count': 0,
    });
  }

  Future<int> getCustomDeckCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM decks WHERE is_premade = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  Future<Map<String, dynamic>?> getRandomQuizQuestion({int? deckId, List<int> excludeCardIds = const []}) async {
    final db = await instance.database;
    
    List<Map<String, dynamic>> randomCardResult;
    String excludeClause = excludeCardIds.isNotEmpty ? 'AND id NOT IN (${excludeCardIds.join(',')})' : '';

    if (deckId != null) {
      randomCardResult = await db.rawQuery(
        'SELECT * FROM cards WHERE deck_id = ? $excludeClause ORDER BY counter ASC, RANDOM() LIMIT 1',
        [deckId]
      );
    } else {
      randomCardResult = await db.rawQuery(
        'SELECT * FROM cards WHERE 1=1 $excludeClause ORDER BY counter ASC, RANDOM() LIMIT 1'
      );
    }
    
    if (randomCardResult.isEmpty) return null; 
    
    final card = randomCardResult.first;
    final cardId = card['id'] as int;
    final actualDeckId = card['deck_id'];
    final correctAnswer = card['correct_answer'] as String;
    final prompt = card['prompt'] as String;

    final wrongAnswers = await db.rawQuery('''
      SELECT correct_answer FROM cards 
      WHERE deck_id = ? AND id != ? 
      ORDER BY RANDOM() LIMIT 3
    ''', [actualDeckId, cardId]);

    List<String> options = [correctAnswer];
    for (var row in wrongAnswers) {
      options.add(row['correct_answer'] as String);
    }

    options.shuffle();
    await db.rawUpdate('UPDATE cards SET counter = counter + 1 WHERE id = ?', [cardId]);

    return {
      'id': cardId,
      'prompt': prompt,
      'correct_answer': correctAnswer,
      'options': options,
    };
  }

  Future<List<Map<String, dynamic>>> getLearningCards(int limit, {int? deckId, List<int> excludeCardIds = const []}) async {
    final db = await instance.database;
    List<Map<String, dynamic>> result;
    
    String excludeClause = excludeCardIds.isNotEmpty ? 'AND id NOT IN (${excludeCardIds.join(',')})' : '';

    if (deckId != null) {
      result = await db.rawQuery(
        'SELECT * FROM cards WHERE deck_id = ? $excludeClause ORDER BY counter ASC, RANDOM() LIMIT ?',
        [deckId, limit]
      );
    } else {
      result = await db.rawQuery(
        'SELECT * FROM cards WHERE 1=1 $excludeClause ORDER BY counter ASC, RANDOM() LIMIT ?',
        [limit]
      );
    }
    
    for (var card in result) {
      await db.rawUpdate('UPDATE cards SET counter = counter + 1 WHERE id = ?', [card['id']]);
    }
    
    return result;
  }

  Future<void> resetCountersForDeck(int deckId) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE cards SET counter = 0 WHERE deck_id = ?', [deckId]);
  }

  Future<List<Map<String, dynamic>>> getCardsForDeck(int deckId) async {
    final db = await instance.database;
    return await db.query(
      'cards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
    );
  }


  Future<Map<String, dynamic>?> getDeckById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'decks',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> removeDeck(int deckId) async {
    final db = await instance.database;
    await db.rawDelete('DELETE FROM decks WHERE id = ?', [deckId]);
    await db.rawDelete('DELETE FROM cards WHERE deck_id = ?', [deckId]);
  }

  Future<void> updateDeck(int deckId, String newName, String newCategory, {String? frontLang, String? backLang}) async {
    final db = await instance.database;
    final Map<String, dynamic> values = {
      'name': newName,
      'category': newCategory,
    };
    if (frontLang != null) values['front_lang'] = frontLang;
    if (backLang != null) values['back_lang'] = backLang;

    await db.update('decks', values, where: 'id = ?', whereArgs: [deckId]);
  }
  
  Future<int> getCardCountForDeck(int deckId) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM cards WHERE deck_id = ?', [deckId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> insertStudySession({
    required int deckId,
    required int durationSeconds,
    required int earnedSeconds,
    required int correctCount,
    required int totalQuestions,
  }) async {
    final db = await instance.database;
    final safeCorrect = correctCount > totalQuestions ? totalQuestions : correctCount;

    return await db.insert('study_sessions', {
      'deck_id': deckId,
      'duration_seconds': durationSeconds,
      'earned_seconds': earnedSeconds,
      'correct_count': safeCorrect,
      'total_questions': totalQuestions,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getAggregatedStats(int filterIndex) async {
    final db = await instance.database;

    String dateFilter = "";
    if (filterIndex == 0) {
      dateFilter = "WHERE date(timestamp) = date('now', 'localtime')";
    } else if (filterIndex == 1) {
      dateFilter = "WHERE date(timestamp) >= date('now', 'localtime', '-7 days')";
    }

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(total_questions), 0) AS total_cards,
        COALESCE(SUM(duration_seconds), 0) AS total_duration,
        COALESCE(SUM(earned_seconds), 0) AS total_earned,
        COALESCE(SUM(correct_count), 0) AS total_correct,
        COUNT(id) AS total_sessions
      FROM study_sessions
      $dateFilter
    ''');

    final row = result.first;
    final int totalCards = row['total_cards'] as int;
    final int totalDuration = row['total_duration'] as int;
    final int totalEarned = row['total_earned'] as int;
    final int totalCorrect = row['total_correct'] as int;
    final int totalSessions = row['total_sessions'] as int;

    int accuracy = 0;
    if (totalCards > 0) {
      final rawAccuracy = ((totalCorrect / totalCards) * 100).round();
      accuracy = rawAccuracy > 100 ? 100 : rawAccuracy;
    }

    final int minutesSaved = (totalEarned / 60).round();

    return {
      'cards': totalCards,
      'durationSeconds': totalDuration,
      'earnedSeconds': totalEarned,
      'timeMinutes': minutesSaved,
      'accuracy': accuracy,
      'sessions': totalSessions,
      'mastered': totalCorrect,
    };
  }

  Future<String> getFavoriteDeckName(int filterIndex) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT d.name, COUNT(s.id) as session_count
      FROM study_sessions s
      JOIN decks d ON s.deck_id = d.id
      GROUP BY s.deck_id
      ORDER BY session_count DESC
      LIMIT 1
    ''');

    if (result.isNotEmpty && result.first['name'] != null) {
      return result.first['name'].toString();
    }
    return 'Žiadny';
  }

  Future<Map<String, String>?> getNemesisCardDetails() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT prompt, correct_answer 
      FROM cards 
      WHERE wrong_count > 0 
      ORDER BY wrong_count DESC 
      LIMIT 1
    ''');

    if (result.isNotEmpty) {
      return {
        'prompt': result.first['prompt'].toString(),
        'correct_answer': result.first['correct_answer'].toString(),
      };
    }
    return null;
  }

  Future<int> getCurrentStreak() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT date(timestamp, 'localtime') as session_date 
      FROM study_sessions 
      ORDER BY session_date DESC
    ''');

    if (result.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    String formatDate(DateTime d) =>
        "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

    List<String> activeDates = result.map((r) => r['session_date'] as String).toList();

    String todayStr = formatDate(checkDate);
    String yesterdayStr = formatDate(checkDate.subtract(const Duration(days: 1)));

    if (!activeDates.contains(todayStr) && !activeDates.contains(yesterdayStr)) {
      return 0;
    }

    if (!activeDates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (activeDates.contains(formatDate(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<int> addEarnedTime(int bonusSeconds) async {
    final db = await instance.database;
    return await db.insert('study_sessions', {
      'timestamp': DateTime.now().toIso8601String(),
      'deck_id': 0,
      'duration_seconds': 0,
      'earned_seconds': bonusSeconds,
      'correct_count': 0,
      'total_questions': 0,
    });
  }

  Future<void> incrementCardWrongCount(int cardId) async {
    final db = await instance.database;
    await db.rawUpdate('''
      UPDATE cards 
      SET wrong_count = wrong_count + 1 
      WHERE id = ?
    ''', [cardId]);
  }
}