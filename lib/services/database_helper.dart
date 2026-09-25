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
      version: 7,
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
    if (oldVersion < 7) {
      await _fixAndSanitizeDecks(db);
      await _seedPremadeDecks(db);
    }
  }

  // Vyčistí staré nežiadúce balíčky a zaradí správne balíčky do Geografie/Technológií
  Future<void> _fixAndSanitizeDecks(Database db) async {
    try {
      // Vymaže akýkoľvek výskyt "IT a programovanie" bez ohľadu na is_premade
      await db.rawDelete('''
        DELETE FROM decks 
        WHERE LOWER(name) LIKE '%it a programovanie%' 
           OR LOWER(name) LIKE '%it & programovanie%'
           OR (is_premade = 1 AND name NOT IN (
              'World Capitals', 
              'World Flags', 
              'Spanish Top 200 Words', 
              'German Top 200 Words', 
              'French Top 200 Words', 
              'Finnish Top 200 Words', 
              'HTTP Status Codes', 
              'Essential Linux Commands'
            ));
      ''');

      await db.rawUpdate('''
        UPDATE decks 
        SET category = 'Geography' 
        WHERE name IN ('World Capitals', 'World Flags');
      ''');

      await db.rawUpdate('''
        UPDATE decks 
        SET category = 'Language' 
        WHERE name IN ('Spanish Top 200 Words', 'German Top 200 Words', 'French Top 200 Words', 'Finnish Top 200 Words');
      ''');

      await db.rawUpdate('''
        UPDATE decks 
        SET category = 'Technology' 
        WHERE name IN ('HTTP Status Codes', 'Essential Linux Commands');
      ''');
    } catch (e) {
      debugPrint("Sanitize decks error: $e");
    }
  }

  Future<void> _seedPremadeDecks(Database db) async {
    try {
      final jsonString = await rootBundle.loadString('assets/decks/premade_decks.json');
      final List<dynamic> deckList = jsonDecode(jsonString);

      for (var d in deckList) {
        final existing = await db.query(
          'decks',
          where: 'name = ? AND is_premade = 1',
          whereArgs: [d['name']],
        );

        if (existing.isEmpty) {
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
      }
    } catch (e) {
      debugPrint("Database seeding error: $e");
    }
  }

  Future<List<Deck>> getDecks() async {
    final db = await instance.database;
    await _fixAndSanitizeDecks(db);
    await _seedPremadeDecks(db);
    final result = await db.query('decks');
    return result.map((json) => Deck.fromMap(json)).toList();
  }

  Future<int> addNewDeck(String name, String category, {String frontLang = 'en-US', String backLang = 'en-US'}) async {
    final db = await instance.database;
    return await db.insert('decks', {
      'name': name,
      'category': category,
      'is_premade': 0,
      'front_lang': frontLang,
      'back_lang': backLang,
    });
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
  
  Future<Map<String, dynamic>?> getRandomQuizQuestion({int? deckId, List<int> excludeCardIds = const [], String locale = 'en'}) async {
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
    
    final rawCard = randomCardResult.first;
    final cardId = rawCard['id'] as int;
    final actualDeckId = rawCard['deck_id'];

    final deckMap = await getDeckById(actualDeckId);
    final deckName = deckMap?['name'] ?? '';

    final card = localizePremadeCard(rawCard, deckName, locale);

    final correctAnswer = card['correct_answer'] as String;
    final prompt = card['prompt'] as String;

    final wrongAnswers = await db.rawQuery('''
      SELECT correct_answer FROM cards 
      WHERE deck_id = ? AND id != ? 
      ORDER BY RANDOM() LIMIT 3
    ''', [actualDeckId, cardId]);

    List<String> options = [correctAnswer];
    for (var row in wrongAnswers) {
      final locRow = localizePremadeCard(row, deckName, locale);
      options.add(locRow['correct_answer'] as String);
    }

    options.shuffle();
    await db.rawUpdate('UPDATE cards SET counter = counter + 1 WHERE id = ?', [cardId]);

    return {
      'id': cardId,
      'prompt': prompt,
      'correct_answer': correctAnswer,
      'options': options,
      'front_lang': card['front_lang'] ?? 'en-US',
      'back_lang': card['back_lang'] ?? 'en-US',
    };
  }

  Future<List<Map<String, dynamic>>> getLearningCards(int limit, {int? deckId, List<int> excludeCardIds = const [], String locale = 'en'}) async {
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

    String deckName = '';
    if (deckId != null) {
      final d = await getDeckById(deckId);
      deckName = d?['name'] ?? '';
    }

    List<Map<String, dynamic>> localizedResult = [];
    for (var card in result) {
      await db.rawUpdate('UPDATE cards SET counter = counter + 1 WHERE id = ?', [card['id']]);
      localizedResult.add(localizePremadeCard(card, deckName, locale));
    }
    
    return localizedResult;
  }

  Future<void> resetCountersForDeck(int deckId) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE cards SET counter = 0 WHERE deck_id = ?', [deckId]);
  }

  Future<List<Map<String, dynamic>>> getCardsForDeck(int deckId, {String locale = 'en'}) async {
    final db = await instance.database;
    final deckMap = await getDeckById(deckId);
    final deckName = deckMap?['name'] ?? '';

    final cards = await db.query(
      'cards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
    );

    return cards.map((c) => localizePremadeCard(c, deckName, locale)).toList();
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

  // ==========================================
  // INLINE LOKALIZÁCIA PREDPRIPRAVENÝCH KARIET
  // ==========================================
  static Map<String, dynamic> localizePremadeCard(Map<String, dynamic> card, String deckName, String locale) {
    if (locale != 'sk') return card;

    final cleanDeck = deckName.trim().toLowerCase();
    final prompt = card['prompt']?.toString() ?? '';
    final answer = card['correct_answer']?.toString() ?? '';

    if (cleanDeck.contains('spanish') || cleanDeck.contains('španiel')) {
      final skPrompt = _spanishToSk[answer] ?? _spanishToSk[prompt] ?? answer;
      return {
        ...card,
        'prompt': skPrompt,
        'correct_answer': _cleanQuotes(prompt),
        'front_lang': 'sk-SK',
        'back_lang': 'es-ES',
      };
    }

    if (cleanDeck.contains('german') || cleanDeck.contains('nemec')) {
      final skPrompt = _germanToSk[answer] ?? _germanToSk[prompt] ?? answer;
      return {
        ...card,
        'prompt': skPrompt,
        'correct_answer': _cleanQuotes(prompt),
        'front_lang': 'sk-SK',
        'back_lang': 'de-DE',
      };
    }

    if (cleanDeck.contains('french') || cleanDeck.contains('francúz')) {
      final skPrompt = _frenchToSk[answer] ?? _frenchToSk[prompt] ?? answer;
      return {
        ...card,
        'prompt': skPrompt,
        'correct_answer': _cleanQuotes(prompt),
        'front_lang': 'sk-SK',
        'back_lang': 'fr-FR',
      };
    }

    if (cleanDeck.contains('finnish') || cleanDeck.contains('fínsk')) {
      final skPrompt = _finnishToSk[answer] ?? _finnishToSk[prompt] ?? answer;
      return {
        ...card,
        'prompt': skPrompt,
        'correct_answer': _cleanQuotes(prompt),
        'front_lang': 'sk-SK',
        'back_lang': 'fi-FI',
      };
    }

    if (cleanDeck.contains('linux')) {
      return {
        ...card,
        'prompt': _linuxToSk[prompt] ?? prompt,
        'correct_answer': answer,
        'front_lang': 'sk-SK',
        'back_lang': 'en-US',
      };
    }

    if (cleanDeck.contains('capital') || cleanDeck.contains('hlavn')) {
      final countryEn = prompt.replaceAll('Capital of ', '').replaceAll(RegExp(r'\s*[\u1F1E6-\u1F1FF]{2}'), '').trim();
      final skCountry = _countryToSk[countryEn] ?? countryEn;
      final skCapital = _capitalToSk[answer] ?? answer;
      final flagMatch = RegExp(r'[\u1F1E6-\u1F1FF]{2}').stringMatch(prompt) ?? '';

      return {
        ...card,
        'prompt': 'Hlavné mesto: $skCountry $flagMatch'.trim(),
        'correct_answer': skCapital,
        'front_lang': 'sk-SK',
        'back_lang': 'sk-SK',
      };
    }

    if (cleanDeck.contains('flag') || cleanDeck.contains('vlajk')) {
      return {
        ...card,
        'prompt': prompt,
        'correct_answer': _countryToSk[answer] ?? answer,
        'front_lang': 'en-US',
        'back_lang': 'sk-SK',
      };
    }

    return card;
  }

  static String _cleanQuotes(String text) => text.replaceAll("'", "").replaceAll('"', '').trim();

  static final Map<String, String> _linuxToSk = {
    "Command to list directory contents": "Príkaz na výpis obsahu adresára",
    "Command to change current working directory": "Príkaz na zmenu pracovného adresára",
    "Command to print current working directory path": "Príkaz na výpis cesty k pracovnému adresáru",
    "Command to create a new directory": "Príkaz na vytvorenie nového adresára",
    "Command to remove an empty directory": "Príkaz na odstránenie prázdneho adresára",
    "Command to remove files or directories": "Príkaz na odstránenie súborov alebo adresárov",
    "Command to copy files or directories": "Príkaz na kopírovanie súborov alebo adresárov",
    "Command to move or rename files and directories": "Príkaz na presun alebo premenovanie súborov a adresárov",
    "Command to create an empty file or update timestamps": "Príkaz na vytvorenie prázdneho súboru alebo aktualizáciu časových pečiatok",
    "Command to display file contents on terminal": "Príkaz na zobrazenie obsahu súboru v termináli",
    "Command to view file contents page by page": "Príkaz na prehliadanie obsahu súboru po stránkach",
    "Command to view the first few lines of a file": "Príkaz na zobrazenie prvých pár riadkov súboru",
    "Command to view the last few lines of a file": "Príkaz na zobrazenie posledných pár riadkov súboru",
    "Command to search text matching a pattern inside files": "Príkaz na vyhľadávanie textu podľa vzoru v súboroch",
    "Command to search for files and directories in directory tree": "Príkaz na vyhľadávanie súborov a adresárov v strome adresárov",
    "Command to change file permissions": "Príkaz na zmenu prístupových práv k súboru",
    "Command to change file owner and group": "Príkaz na zmenu vlastníka a skupiny súboru",
    "Command to execute command with superuser (root) privileges": "Príkaz na spustenie príkazu s právami superpoužívateľa (root)",
    "Command to display running processes in real-time": "Príkaz na zobrazenie spustených procesov v reálnom čase",
    "Command to kill a process by PID": "Príkaz na ukončenie procesu podľa PID",
    "Command to kill processes by name": "Príkaz na ukončenie procesov podľa názvu",
    "Command to report a snapshot of current processes": "Príkaz na zobrazenie aktuálnych procesov",
    "Command to check disk space usage of filesystems": "Príkaz na kontrolu využitia miesta na disku",
    "Command to estimate file and directory space usage": "Príkaz na zistenie veľkosti súborov a adresárov",
    "Command to display amount of free and used memory (RAM)": "Príkaz na zobrazenie voľnej a využitej pamäte (RAM)",
    "Command to output text or variable values to terminal": "Príkaz na výpis textu alebo hodnôt premenných do terminálu",
    "Command to clear terminal screen": "Príkaz na vyčistenie obrazovky terminálu",
    "Command to show user command history": "Príkaz na zobrazenie histórie príkazov",
    "Command to manage network interfaces and IP addresses": "Príkaz na správu sieťových rozhraní a IP adries",
    "Command to send ICMP echo requests to test network connectivity": "Príkaz na testovanie sieťového spojenia pomocou ICMP",
    "Command to download files from web via HTTP/HTTPS/FTP": "Príkaz na sťahovanie súborov z webu cez HTTP/HTTPS/FTP",
    "Command to transfer data from or to a server using URL syntax": "Príkaz na prenos dát zo servera alebo na server pomocou URL",
    "Command to store and extract files from a tape archive": "Príkaz na vytváranie a rozbaľovanie archívov (tar)",
    "Command to compress files into zip format": "Príkaz na kompresiu súborov do formátu zip",
    "Command to extract zip archives": "Príkaz na rozbalenie zip archívov",
    "Command to connect to remote server securely via terminal": "Príkaz na bezpečné pripojenie k vzdialenému serveru cez SSH",
    "Command to copy files securely between hosts over SSH": "Príkaz na bezpečné kopírovanie súborov cez SSH",
    "Command to synchronize files efficiently between two locations": "Príkaz na efektívnu synchronizáciu súborov medzi dvoma miestami",
    "Command to display system kernel and architecture information": "Príkaz na zobrazenie informácií o jadre a architektúre systému",
    "Command to display current logged-in username": "Príkaz na zobrazenie mena aktuálne prihláseného používateľa",
    "Command to display system uptime and load average": "Príkaz na zobrazenie času behu systému a priemernej záťaže",
    "Command to control systemd system and service manager": "Príkaz na správu služieb a systému pomocou systemd",
    "Command to view system logs managed by systemd": "Príkaz na zobrazenie systémových logov zo systemd",
    "Command to create links between files": "Príkaz na vytvorenie odkazov (links) medzi súbormi",
    "Command to count lines, words, and bytes in a file": "Príkaz na spočítanie riadkov, slov a bajtov v súbore",
    "Command to sort lines of text files": "Príkaz na zoradenie riadkov v textovom súbore",
    "Command to report or omit repeated lines": "Príkaz na odstránenie alebo zobrazenie duplicity riadkov",
    "Command stream editor for filtering and transforming text": "Prúdový editor pre filtrovanie a úpravu textu (sed)",
    "Command for pattern scanning and processing language": "Nástroj na spracovanie a filtrovanie textu podľa vzorov (awk)",
    "Command to display manual page for any command": "Príkaz na zobrazenie manuálovej stránky príkazu",
    "Command to locate executable path of a command": "Príkaz na zistenie cesty k spustiteľnému súboru príkazu",
    "Command to change user password": "Príkaz na zmenu hesla používateľa",
    "Command to reboot the system": "Príkaz na reštartovanie systému",
    "Command to power off or shut down the machine": "Príkaz na vypnutie počítača",
    "Command to mount a filesystem": "Príkaz na pripojenie (mount) súborového systému",
    "Command to unmount a mounted filesystem": "Príkaz na odpojenie (umount) súborového systému",
    "Command to print or modify environment variables": "Príkaz na zobrazenie alebo úpravu premenných prostredia",
    "Command to set environment variables for child processes": "Príkaz na nastavenie premenných prostredia pre dcérske procesy",
    "Command to schedule periodic background jobs": "Príkaz na plánovanie pravidelných úloh na pozadí (cron)",
    "Command to exit current shell session": "Príkaz na ukončenie aktuálnej relácie shellu",
    "Command to search for commands in the PATH by name": "Príkaz na vyhľadanie umiestnenia príkazu v PATH",
    "Command to display alias definitions or create new ones": "Príkaz na zobrazenie alebo vytvorenie aliasov príkazov",
    "Command to remove an alias": "Príkaz na odstránenie aliasu",
    "Command to output the last part of a file or pipe": "Príkaz na zápis vstupu do súboru aj na štandardný výstup (tee)",
    "Command to run a command immune to hangups": "Príkaz na spustenie príkazu odolného voči odpojeniu relácie (nohup)",
    "Command to change root directory for current process": "Príkaz na zmenu koreňového adresára pre proces (chroot)",
    "Command to print user and group IDs": "Príkaz na zobrazenie ID používateľa a skupín",
    "Command to print the name of current terminal": "Príkaz na zobrazenie názvu aktuálneho terminálu",
    "Command to delay execution for a specified time": "Príkaz na pozastavenie vykonávania na určený čas",
    "Command to merge lines of files side-by-side": "Príkaz na spojenie riadkov zo súborov vedľa seba",
    "Command to translate or delete characters from input stream": "Príkaz na nahradenie alebo vymazanie znakov zo vstupu (tr)",
    "Command to split a file into pieces": "Príkaz na rozdelenie súboru na menšie časti",
    "Command to convert tabs to spaces or vice versa": "Príkaz na prevod tabulátorov na medzery",
    "Command to view open files and processes using them": "Príkaz na zobrazenie otvorených súborov a procesov",
    "Command to trace system calls and signals": "Príkaz na sledovanie systémových volaní a signálov (strace)"
  };

  static final Map<String, String> _spanishToSk = {
    "Time / Weather": "Čas / Počasie", "Year": "Rok", "People": "Ľudia", "Man": "Muž",
    "Woman": "Žena", "Life": "Život", "Day": "Deň", "Thing": "Vec", "World": "Svet",
    "House": "Dom", "Work / Job": "Práca", "Part": "Časť", "Place": "Miesto",
    "Government": "Vláda", "Case": "Prípad", "Group": "Skupina", "Problem": "Problém",
    "Fact": "Fakt", "Hand": "Ruka", "Eye": "Oko", "Hour / Time": "Hodina / Čas",
    "Truth": "Pravda", "Water": "Voda", "Mother": "Matka", "Father": "Otec",
    "Friend": "Priateľ", "Family": "Rodina", "Money": "Peniaze", "Night": "Noc",
    "City": "Mesto", "Name": "Meno", "Country": "Krajina", "Question": "Otázka",
    "Door": "Dvere", "Street": "Ulica", "Book": "Kniha", "Word": "Slovo",
    "Side": "Strana", "Son / Child": "Syn / Dieťa", "Moment": "Chvíľa", "Body": "Telo",
    "Head": "Hlava", "Sun": "Slnko", "Light": "Svetlo", "Dog": "Pes", "Cat": "Mačka",
    "Food": "Jedlo", "Love": "Láska", "Air": "Vzduch", "Sea": "More",
    "To be (permanent)": "Byť (trvalo)", "To be (temporary)": "Byť (prechodne)",
    "To do / To make": "Robiť / Vytvoriť", "To have": "Mať", "To go": "Ísť",
    "To say / To tell": "Povedať", "To be able to / Can": "Môcť", "To see": "Vidieť",
    "To eat": "Jesť", "To drink": "Piť", "To speak / To talk": "Hovoriť",
    "To know (facts)": "Vedieť (fakty)", "To want / To love": "Chcieť / Ľúbiť",
    "To arrive": "Prísť", "To pass / To happen": "Prejsť / Stať sa", "Must / Should": "Musieť / Maly by",
    "To put": "Položiť", "To seem": "Zdať sa", "To stay / To remain": "Zostať",
    "To believe": "Veriť", "To carry / To wear": "Nosiť", "To leave / To allow": "Nechať / Povoliť",
    "To follow / To continue": "Sledovať / Pokračovať", "To find": "Nájsť", "To call": "Volať",
    "To think": "Myslieť", "To leave / To exit": "Odisť", "To return / To come back": "Vrátiť sa",
    "To take / To drink": "Vziať / Piť", "To know (people/places)": "Poznať (ľudí/miesta)",
    "To live": "Žiť", "To feel": "Cítiť", "To write": "Písať", "To read": "Čítať",
    "To open": "Otvoriť", "To close": "Zatvoriť", "To buy": "Kúpiť", "To sell": "Predať",
    "To work": "Pracovať", "To study": "Študovať", "To learn": "Učiť sa",
    "To understand": "Rozumieť", "To help": "Pomôcť", "To play (games/sports)": "Hrať",
    "To listen": "Počúvať", "To look at": "Pozerať sa na", "To search / To look for": "Hľadať",
    "To pay": "Platiť", "To sleep": "Spať", "To change": "Meniť", "Big / Large": "Veľký",
    "Small / Little": "Malý", "Good": "Dobrý", "Bad": "Zlý", "New": "Nový", "Old": "Starý",
    "First": "Prvý", "Last": "Posledný", "Long": "Dlhý", "Tall / High": "Vysoký",
    "Short / Low": "Nízky / Krátky", "Young": "Mladý", "Easy": "Ľahký", "Difficult": "Ťažký",
    "Important": "Dôležitý", "Same": "Rovnaký", "Other / Another": "Iný", "Alone / Only": "Sám / Len",
    "Fast / Quick": "Rýchly", "Slow": "Pomalý", "Happy": "Šťastný", "Sad": "Smutný",
    "Tired": "Unavený", "Pretty / Nice": "Pekný", "Ugly": "Oškaredý", "Hot": "Horúci",
    "Cold": "Studený", "Clean": "Čistý", "Dirty": "Špinavý", "Full": "Plný", "Empty": "Prázdny",
    "Strong": "Silný", "Rich / Delicious": "Bohatý / Chutný", "Poor": "Chudobný",
    "Close / Near": "Blízko", "Far": "Ďaleko", "Early": "Skoro", "Late": "Neskoro",
    "Always": "Vždy", "Never": "Nikdy", "Sometimes": "Občas", "Now": "Teraz", "Today": "Dnes",
    "Yesterday": "Včera", "Tomorrow / Morning": "Zajtra / Ráno", "Here": "Tu", "There": "Tam",
    "Much / A lot": "Veľa", "Little / Few": "Málo", "More": "Viac", "Less": "Menej",
    "Very": "Veľmi", "Also / Too": "Taktiež", "Neither / Either": "Ani", "Yes": "Áno", "No": "Nie",
    "Maybe / Perhaps": "Možno", "Well / Fine": "Dobre", "Badly / Poorly": "Zle", "Hello": "Ahoj",
    "Goodbye": "Dovidenia", "Please": "Prosím", "Thank you": "Ďakujem", "You're welcome": "Nie je za čo",
    "I'm sorry": "Prepáč", "Excuse me": "S dovolením", "I": "Ja", "You (informal)": "Ty",
    "He": "On", "She": "Ona", "We": "My", "They": "Oni", "You (formal)": "Vy", "What": "Čo",
    "Who": "Kto", "Where": "Kde", "When": "Kedy", "Why": "Prečo", "How": "Ako",
    "How much": "Koľko", "And": "A", "Or": "Alebo", "But": "Ale", "Because": "Lebo", "If": "Ak",
    "Like / As": "Ako", "For / To": "Pre / K", "For / By": "Za / Od", "With": "S", "Without": "Bez",
    "In / On / At": "V / Na", "Of / From": "Z / O", "To / At": "Do / K", "About / On top of": "O / Na",
    "Between / Among": "Medzi", "Until": "Až do", "From / Since": "Od", "Trip / Journey": "Cesta / Výlet",
    "School": "Škola", "Table": "Stôl"
  };

  static final Map<String, String> _germanToSk = {
    "Window": "Okno", "Key": "Kľúč", "Clock / Watch": "Hodiny / Hodinky", "Picture / Image": "Obrázok",
    "Newspaper": "Noviny", "Time": "Čas", "Year": "Rok", "Person / Human": "Človek", "Day": "Deň",
    "Woman / Wife": "Žena / Manželka", "Man / Husband": "Muž / Manžel", "Child": "Dieťa", "Life": "Život",
    "World": "Svet", "House": "Dom", "Hand": "Ruka", "Eye": "Oko", "City / Town": "Mesto",
    "Country / Land": "Krajina", "Name": "Meno", "Mother": "Matka", "Father": "Otec", "Friend": "Priateľ",
    "Family": "Rodina", "Money": "Peniaze", "Night": "Noc", "Question": "Otázka", "Door": "Dvere",
    "Street": "Ulica", "Book": "Kniha", "Word": "Slovo", "Side / Page": "Strana", "Son": "Syn",
    "Daughter": "Dcéra", "Head": "Hlava", "Body": "Telo", "Sun": "Slnko", "Light": "Svetlo",
    "Dog": "Pes", "Cat": "Mačka", "Food": "Jedlo", "Love": "Láska", "Air": "Vzduch", "Sea": "More",
    "Water": "Voda", "Work / Job": "Práca", "Place": "Miesto", "Case": "Prípad", "Group": "Skupina",
    "Problem": "Problém", "Reason / Ground": "Dôvod", "Truth": "Pravda", "Way / Path": "Cesta",
    "Hour": "Hodina", "Part": "Časť", "To be": "Byť", "To have": "Mať", "To become": "Stať sa",
    "To be able to / Can": "Môcť", "Must / To have to": "Musieť", "To say / To tell": "Povedať",
    "To do / To make": "Robiť / Vytvoriť", "To give": "Dať", "To come": "Prísť", "To want": "Chcieť",
    "To go / To walk": "Ísť / Kráčať", "To know (facts)": "Vedieť (fakty)", "To see": "Vidieť",
    "To let / To allow": "Nechať / Povoliť", "To stand": "Stáť", "To find": "Nájsť", "To stay / To remain": "Zostať",
    "To lie / To be situated": "Ležať", "To be called": "Robiť sa / Volať sa", "To think": "Myslieť",
    "To take": "Vziať", "To do": "Robiť", "To believe": "Veriť", "To hold / To stop": "Držať / Zastaviť",
    "To call / To name": "Volať / Pomenovať", "To like": "Mať rád", "To show": "Ukázať", "To lead": "Viesť",
    "To speak": "Hovoriť", "To bring": "Priniesť", "To live": "Žiť", "To drive / To go (vehicle)": "Šoférovať / Ísť (autom)",
    "To mean / To think": "Myslieť si", "To ask": "Pýtať sa", "To know (people/places)": "Poznať",
    "To apply / To be valid": "Platiť", "To place / To put": "Položiť", "To play": "Hrať", "To work": "Pracovať",
    "To need": "Potrebovať", "To follow": "Sledovať", "To learn": "Učiť sa", "To understand": "Rozumieť",
    "To eat": "Jesť", "To drink": "Piť", "To write": "Písať", "To read": "Čítať", "To buy": "Kúpiť",
    "To hear / To listen": "Počuť / Počúvať", "To help": "Pomôcť", "Big / Tall": "Veľký / Vysoký",
    "Small / Little": "Malý", "Good": "Dobrý", "Bad": "Zlý", "New": "Nový", "Old": "Starý",
    "First": "Prvý", "Last": "Posledný", "Long": "Dlhý", "High": "Vysoký", "Young": "Mladý",
    "Easy / Simple": "Jednoduchý / Ľahký", "Difficult": "Ťažký", "Important": "Dôležitý",
    "Same / Equal": "Rovnaký", "Different": "Iný", "Alone": "Sám", "Fast / Quick": "Rýchly",
    "Slow": "Pomalý", "Happy": "Šťastný", "Sad": "Smutný", "Tired": "Unavený", "Beautiful / Nice": "Pekný",
    "Ugly": "Oškaredý", "Hot": "Horúci", "Cold": "Studený", "Clean": "Čistý", "Dirty": "Špinavý",
    "Full": "Plný", "Empty": "Prázdny", "Strong": "Silný", "Rich": "Bohatý", "Poor": "Chudobný",
    "Near / Close": "Blízko", "Far": "Ďaleko", "Early": "Skoro", "Late": "Neskoro", "Always": "Vždy",
    "Never": "Nikdy", "Sometimes": "Občas", "Now": "Teraz", "Today": "Dnes", "Yesterday": "Včera",
    "Tomorrow": "Zajtra", "Here": "Tu", "There": "Tam", "Much / A lot": "Veľa", "Little / Few": "Málo",
    "More": "Viac", "Very": "Veľmi", "Also / Too": "Taktiež", "Yes": "Áno", "No": "Nie", "Maybe": "Možno",
    "Please / You're welcome": "Prosím / Nie je za čo", "Thank you": "Ďakujem", "Hello": "Ahoj",
    "Goodbye": "Dovidenia", "Excuse me / Sorry": "Prepáč", "I": "Ja", "You (informal)": "Ty",
    "He": "On", "She / They / You (formal)": "Ona / Oni / Vy", "It": "To", "We": "My", "You (plural)": "Vy",
    "What": "Čo", "Who": "Kto", "Where": "Kde", "When": "Kedy", "Why": "Prečo", "How": "Ako",
    "And": "A", "Or": "Alebo", "But": "Ale", "Because": "Lebo", "If / When": "Ak / Kedy",
    "That (conjunction)": "Že", "With": "S", "Without": "Bez", "In": "V", "From / Of": "Z / Od",
    "To": "K / Do", "On / Upon": "Na", "For": "Pre", "Over / About": "Nad / O", "Under / Among": "Pod / Medzi",
    "In front of / Before": "Pred", "After / To (a direction)": "Po / Do", "Through": "Cez",
    "Against": "Proti", "Chair": "Stolička", "Car": "Auto"
  };

  static final Map<String, String> _frenchToSk = {
    "Daughter / Girl": "Dcéra / Dievča", "Money / Silver": "Peniaze / Striebro", "Path / Way": "Cesta",
    "To be necessary / Must": "Byť potrebné / Musieť", "To spend time": "Stráviť čas",
    "To look at / To watch": "Pozerať", "To function": "Fungovať", "To go out / To exit": "Ísť von",
    "To enter": "Vstúpiť", "Beautiful / Handsome": "Krásny", "Clean / Own": "Čistý / Vlastný",
    "A lot / Much": "Veľa", "Hello / Good morning": "Dobrý deň / Ahoj", "Sorry / Excuse me": "Prepáč",
    "You (plural/formal)": "Vy", "They (masculine)": "Oni", "They (feminine)": "Ony",
    "How much / How many": "Koľko", "For / In order to": "Pre / Aby", "In / Inside": "V / Vo vnútri",
    "During": "Počas", "Before": "Pred", "After": "Po", "Car": "Auto"
  };

  static final Map<String, String> _finnishToSk = {
    "Thing / Matter": "Vec", "House / Building": "Dom / Budova", "Hand / Arm": "Ruka",
    "Country / Earth / Land": "Krajina / Zem", "Boy / Son": "Chlapec / Syn", "Girl / Daughter": "Dievča / Dcéra",
    "Air / Weather": "Vzduch / Počasie", "Reason / Cause": "Dôvod / Príčina", "Road / Way": "Cesta",
    "Hour / Lesson": "Hodina / Lekcia", "To be / To have": "Byť / Mať", "To come / To become": "Prísť / Stať sa",
    "To must / To like / To hold": "Musieť / Mať rád", "To think / To consider": "Myslieť",
    "To feel / To know (people)": "Cítiť / Poznať", "To watch / To look": "Pozerať",
    "To change / To move": "Meniť / Sťahovať sa", "To wait / To expect": "Čakať", "To leave / To depart": "Odísť",
    "To sit": "Sedieť", "To pay / To cost": "Platiť / Stáť (cenu)", "To use": "Používať",
    "To start": "Začať", "To stop / To finish": "Skončiť", "To happen": "Stať sa", "To travel": "Cestovať",
    "Bad / Evil": "Zlý", "Difficult / Hard": "Ťažký", "Other / Second": "Iný / Druhý",
    "Far away": "Ďaleko", "On time / Early": "Na čas / Skoro", "A little / Few": "Málo",
    "Well / Very": "Dobre / Veľmi", "Please / You're welcome": "Prosím / Nie je za čo", "Hi": "Ahoj",
    "You (singular)": "Ty", "He / She": "On / Ona", "Phone": "Telefón", "Computer": "Počítač",
    "Forest": "Les", "Lake": "Jazero", "Sky / Heaven": "Nebo", "Flower": "Kvet", "Home": "Domov"
  };

  static final Map<String, String> _countryToSk = {
    "Afghanistan": "Afganistan", "Albania": "Albánsko", "Algeria": "Alžírsko", "Andorra": "Andorra",
    "Angola": "Angola", "Antigua and Barbuda": "Antigua a Barbuda", "Argentina": "Argentína",
    "Armenia": "Arménsko", "Australia": "Austrália", "Austria": "Rakúsko", "Azerbaijan": "Azerbajdžan",
    "Bahamas": "Bahamy", "Bahrain": "Bahrajn", "Bangladesh": "Bangladéš", "Barbados": "Barbados",
    "Belarus": "Bielorusko", "Belgium": "Belgicko", "Belize": "Belize", "Benin": "Benin",
    "Bhutan": "Bhután", "Bolivia": "Bolívia", "Bosnia and Herzegovina": "Bosna a Hercegovina",
    "Botswana": "Botswana", "Brazil": "Brazília", "Brunei": "Brunej", "Bulgaria": "Bulharsko",
    "Burkina Faso": "Burkina Faso", "Burundi": "Burundi", "Cabo Verde": "Kapverdy",
    "Cambodia": "Kambodža", "Cameroon": "Kamerun", "Canada": "Kanada", "Central African Republic": "Stredoafrická republika",
    "Chad": "Čad", "Chile": "Čile", "China": "Čína", "Colombia": "Kolumbia", "Comoros": "Komory",
    "Congo": "Kongo", "Democratic Republic of the Congo": "Kongo (DRK)", "Costa Rica": "Kostarika",
    "Croatia": "Chorvátsko", "Cuba": "Kuba", "Cyprus": "Cyprus", "Czech Republic": "Česko",
    "Denmark": "Dánsko", "Djibouti": "Džibutsko", "Dominica": "Dominika", "Dominican Republic": "Dominikánska republika",
    "East Timor": "Východný Timor", "Ecuador": "Ekvádor", "Egypt": "Egypt", "El Salvador": "Salvádor",
    "Equatorial Guinea": "Rovníková Guinea", "Eritrea": "Eritrea", "Estonia": "Estónsko",
    "Eswatini": "Eswatini", "Ethiopia": "Etiópia", "Fiji": "Fidži", "Finland": "Fínsko",
    "France": "Francúzsko", "Gabon": "Gabon", "Gambia": "Gambia", "Georgia": "Gruzínsko",
    "Germany": "Nemecko", "Ghana": "Ghana", "Greece": "Grécko", "Grenada": "Grenada",
    "Guatemala": "Guatemala", "Guinea": "Guinea", "Guinea-Bissau": "Guinea-Bissau",
    "Guyana": "Guyana", "Haiti": "Haiti", "Honduras": "Honduras", "Hungary": "Maďarsko",
    "Iceland": "Island", "India": "India", "Indonesia": "Indonézia", "Iran": "Irán",
    "Iraq": "Irak", "Ireland": "Írsko", "Israel": "Izrael", "Italy": "Taliansko",
    "Ivory Coast": "Pobrežie Slonoviny", "Jamaica": "Jamajka", "Japan": "Japonsko",
    "Jordan": "Jordánsko", "Kazakhstan": "Kazachstan", "Kenya": "Keňa", "Kiribati": "Kiribati",
    "North Korea": "Severná Kórea", "South Korea": "Južná Kórea", "Kuwait": "Kuvajt",
    "Kyrgyzstan": "Kirgizsko", "Laos": "Laos", "Latvia": "Lotyšsko", "Lebanon": "Libanon",
    "Lesotho": "Lesotho", "Liberia": "Libéria", "Libya": "Líbya", "Liechtenstein": "Lichtenštajnsko",
    "Lithuania": "Litva", "Luxembourg": "Luxembursko", "Madagascar": "Madagaskar",
    "Malawi": "Malawi", "Malaysia": "Malajzia", "Maldives": "Maledivy", "Mali": "Mali",
    "Malta": "Malta", "Marshall Islands": "Marshallove ostrovy", "Mauritania": "Mauritánia",
    "Mauritius": "Maurícius", "Mexico": "Mexiko", "Micronesia": "Mikronézia", "Moldova": "Moldavsko",
    "Monaco": "Monako", "Mongolia": "Mongolsko", "Montenegro": "Čierna Hora", "Morocco": "Maroko",
    "Mozambique": "Mozambik", "Myanmar": "Mjanmarsko", "Namibia": "Namíbia", "Nauru": "Nauru",
    "Nepal": "Nepál", "Netherlands": "Holandsko", "New Zealand": "Nový Zéland",
    "Nicaragua": "Nikaragua", "Niger": "Niger", "Nigeria": "Nigéria", "North Macedonia": "Severné Macedónsko",
    "Norway": "Nórsko", "Oman": "Omán", "Pakistan": "Pakistan", "Palau": "Palau",
    "Palestine": "Palestína", "Panama": "Panama", "Papua New Guinea": "Papua-Nová Guinea",
    "Paraguay": "Paraguaj", "Peru": "Peru", "Philippines": "Filipíny", "Poland": "Poľsko",
    "Portugal": "Portugalsko", "Qatar": "Katar", "Romania": "Rumunsko", "Russia": "Rusko",
    "Rwanda": "Rwanda", "Saint Kitts and Nevis": "Svätý Krištof a Nevis", "Saint Lucia": "Svätá Lucia",
    "Saint Vincent and the Grenadines": "Svätý Vincent a Grenadíny", "Samoa": "Samoa",
    "San Marino": "San Maríno", "Sao Tome and Principe": "Svätý Tomáš a Princov ostrov",
    "Saudi Arabia": "Saudská Arábia", "Senegal": "Senegal", "Serbia": "Srbsko",
    "Seychelles": "Seychely", "Sierra Leone": "Sierra Leone", "Singapore": "Singapur",
    "Slovakia": "Slovensko", "Slovenia": "Slovinsko", "Solomon Islands": "Šalamúnove ostrovy",
    "Somalia": "Somálsko", "South Africa": "Južná Afrika", "South Sudan": "Južný Sudán",
    "Spain": "Španielsko", "Sri Lanka": "Srí Lanka", "Sudan": "Sudán", "Suriname": "Surinam",
    "Sweden": "Švédsko", "Switzerland": "Švajčiarsko", "Syria": "Sýria", "Tajikistan": "Tadžikistan",
    "Tanzania": "Tanzánia", "Thailand": "Thajsko", "Togo": "Togo", "Tonga": "Tonga",
    "Trinidad and Tobago": "Trinidad a Tobago", "Tunisia": "Tunisko", "Turkey": "Turecko",
    "Turkmenistan": "Turkménsko", "Tuvalu": "Tuvalu", "Uganda": "Uganda", "Ukraine": "Ukrajina",
    "United Arab Emirates": "Spojené arabské emiráty", "United Kingdom": "Spojené kráľovstvo",
    "United States": "Spojené štáty", "Uruguay": "Uruguaj", "Uzbekistan": "Uzbekistan",
    "Vanuatu": "Vanuatu", "Vatican City": "Vatikán", "Venezuela": "Venezuela", "Vietnam": "Vietnam",
    "Yemen": "Jemen", "Zambia": "Zambia", "Zimbabwe": "Zimbabwe"
  };

  static final Map<String, String> _capitalToSk = {
    "Vienna": "Viedeň", "Rome": "Rím", "Prague": "Praha", "Berlin": "Berlín",
    "London": "Londýn", "Paris": "Paríž", "Warsaw": "Varšava", "Athens": "Atény",
    "Brussels": "Brusel", "Moscow": "Moskva", "Beijing": "Peking", "Lisbon": "Lisabon",
    "Zagreb": "Záhreb", "Bucharest": "Bukurešť", "Copenhagen": "Kodaň", "Tokyo": "Tokio",
    "Kyiv": "Kyjev", "Kabul": "Kábul"
  };
}