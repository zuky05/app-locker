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
    _database = await _initDB('brainlock.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        is_premade INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL,
        prompt TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        counter INTEGER NOT NULL,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        deck_id INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        correct_count INTEGER NOT NULL,
        total_questions INTEGER NOT NULL
      )
    ''');

    await _seedPremadeDecks(db);
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
        });

        for (var c in d['cards']) {
          await db.insert('cards', {
            'deck_id': deckId,
            'prompt': c['prompt'],
            'correct_answer': c['correct_answer'],
            'counter': 0,
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

  Future<int> addNewDeck(String name, String category) async {
    final db = await instance.database;
    final deckId = await db.insert('decks', {
      'name': name,
      'category': category,
      'is_premade': 0,
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

  Future<void> removeDeck(int deckId) async {
    final db = await instance.database;
    await db.rawDelete('DELETE FROM decks WHERE id = ?', [deckId]);
    await db.rawDelete('DELETE FROM cards WHERE deck_id = ?', [deckId]);
  }

  Future<void> updateDeck(int deckId, String newName, String newCategory) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE decks SET name = ?, category = ? WHERE id = ?', [newName, newCategory, deckId]);
  }
  
  Future<int> getCardCountForDeck(int deckId) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM cards WHERE deck_id = ?', [deckId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }


Future<int> insertStudySession({
  required int deckId,
  required int durationSeconds,
  required int correctCount,
  required int totalQuestions,
}) async {
  final db = await instance.database;
  return await db.insert('study_sessions', {
    'timestamp': DateTime.now().toIso8601String(),
    'deck_id': deckId,
    'duration_seconds': durationSeconds,
    'correct_count': correctCount,
    'total_questions': totalQuestions,
  });
}

  // 2. Načítanie agregovaných štatistík (Dnes / Tento týždeň / Lifetime)
  Future<Map<String, dynamic>> getAggregatedStats(int filterIndex) async {
    // 0 = Dnes, 1 = Tento týždeň (posledných 7 dní), 2 = Lifetime
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
        COALESCE(SUM(correct_count), 0) AS total_correct
      FROM study_sessions
      $dateFilter
    ''');

    final row = result.first;
    final int totalCards = row['total_cards'] as int;
    final int totalDuration = row['total_duration'] as int;
    final int totalCorrect = row['total_correct'] as int;

    final int accuracy = totalCards > 0 ? ((totalCorrect / totalCards) * 100).round() : 0;
    final int minutesSaved = (totalDuration / 60).round();

    return {
      'cards': totalCards,
      'timeMinutes': minutesSaved,
      'accuracy': accuracy,
    };
  }

  // 3. Výpočet série nepretržitého učenia (Streak)
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

    // Naformátovanie dátumu na YYYY-MM-DD
    String formatDate(DateTime d) =>
        "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

    List<String> activeDates = result.map((r) => r['session_date'] as String).toList();

    // Ak dnešný ani včerajší deň nemá záznam, streak je 0
    String todayStr = formatDate(checkDate);
    String yesterdayStr = formatDate(checkDate.subtract(const Duration(days: 1)));

    if (!activeDates.contains(todayStr) && !activeDates.contains(yesterdayStr)) {
      return 0;
    }

    // Počítanie po sebe nasledujúcich dní
    if (!activeDates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (activeDates.contains(formatDate(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}