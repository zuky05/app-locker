import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/deck_model.dart';
//import '../models/card_model.dart';

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
    // Tabulka pre balicky
    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        is_premade INTEGER NOT NULL
      )
    ''');

    // Tabulka pre karticky (UŽ BEZ distractors_json)
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

    // Tabulka pre statistiky
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

  
  Future<Map<String, dynamic>?> getRandomQuizQuestion() async {
    final db = await instance.database;
    
    // 1. ZMENA: Najprv zoradiť podľa počítadla (najmenej videné idú prvé), AŽ POTOM náhodne
    final randomCard = await db.rawQuery('SELECT * FROM cards ORDER BY counter ASC, RANDOM() LIMIT 1');
    
    if (randomCard.isEmpty) return null; 
    
    final card = randomCard.first;
    final cardId = card['id']; // Uložíme si ID, aby sme vedeli, komu zdvihnúť counter
    final deckId = card['deck_id'];
    final correctAnswer = card['correct_answer'] as String;
    final prompt = card['prompt'] as String;

    // 2. Vytiahneme max 3 iné odpovede z TOHO ISTÉHO balíčka ako chytáky
    final wrongAnswers = await db.rawQuery('''
      SELECT correct_answer FROM cards 
      WHERE deck_id = ? AND id != ? 
      ORDER BY RANDOM() LIMIT 3
    ''', [deckId, cardId]);

    // 3. Spojíme správnu odpoveď s chytákmi do jedného zoznamu
    List<String> options = [correctAnswer];
    for (var row in wrongAnswers) {
      options.add(row['correct_answer'] as String);
    }

    // 4. Zamiešame ich, aby správna nebola vždy prvá
    options.shuffle();

    // 5. ZMENA: Zdvihneme counter tejto kartičke o +1, aby sa neopakovala!
    await db.rawUpdate('UPDATE cards SET counter = counter + 1 WHERE id = ?', [cardId]);

    // Vrátime to úhľadne zabalené späť
    return {
      'prompt': prompt,
      'correct_answer': correctAnswer,
      'options': options,
    };
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

}