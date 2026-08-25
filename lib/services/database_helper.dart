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

    // Tabulka pre karticky
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL,
        prompt TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        distractors_json TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
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
            'distractors_json': jsonEncode(c['distractors']),
            'difficulty': c['difficulty'] ?? 1,
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

  Future<void> addNewCard(int deckId, String prompt, String correctAnswer, List<String> wrongAnswers) async {
    final db = await instance.database;
    
    await db.insert('cards', {
      'deck_id': deckId,
      'prompt': prompt,
      'correct_answer': correctAnswer,
      'distractors_json': jsonEncode(wrongAnswers), 
      'difficulty': 1,
    });
  }

  Future<int> getCustomDeckCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM decks WHERE is_premade = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

}