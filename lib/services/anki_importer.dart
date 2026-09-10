import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'database_helper.dart';

class AnkiImporter {
  static Future<String?> importApkgDirect() async {
    try {
      // 1. PickFiles vracia List<PlatformFile>?
      final dynamic result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apkg'],
      );

      // Ak používateľ zrušil výber alebo je zoznam prázdny
      if (result == null) return null;

      // Ak je result priamo List<PlatformFile>
      List filesList = result is List ? result : (result.files ?? []);
      if (filesList.isEmpty) return null;

      final String? filePath = filesList.first.path;
      if (filePath == null) return null;

      File file = File(filePath);
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? ankiDbFile;
      for (final f in archive) {
        if (f.name == 'collection.anki2' || f.name == 'collection.anki21') {
          ankiDbFile = f;
          break;
        }
      }

      if (ankiDbFile == null) return "Chyba: V ZIPe sa nenašla databáza collection.anki2!";

      final tempDir = await getTemporaryDirectory();
      final dbPath = join(tempDir.path, 'temp_anki_${DateTime.now().millisecondsSinceEpoch}.db');
      File(dbPath).writeAsBytesSync(ankiDbFile.content as List<int>);

      Database ankiDb = await openDatabase(dbPath);
      final List<Map<String, dynamic>> notes = await ankiDb.query('notes');

      if (notes.isEmpty) {
        await ankiDb.close();
        await File(dbPath).delete();
        return "Súbor neobsahuje žiadne kartičky (poznámky v Anki sú prázdne).";
      }

      // 2. Extrahujeme platné dvojice otázka/odpoveď
      List<Map<String, String>> cardsToInsert = [];

      for (var note in notes) {
        String flds = note['flds'] as String;
        List<String> fields = flds.split('\x1f');
        
        List<String> validTextParts = [];
        for (var field in fields) {
          String cleaned = _cleanText(field);
          if (cleaned.isNotEmpty) {
            validTextParts.add(cleaned);
          }
        }

        if (validTextParts.length >= 2) {
          cardsToInsert.add({'prompt': validTextParts[0], 'answer': validTextParts[1]});
        } else if (validTextParts.length == 1) {
          cardsToInsert.add({'prompt': validTextParts[0], 'answer': "(Zisti z kontextu: ${validTextParts[0]})"});
        }
      }

      await ankiDb.close();
      await File(dbPath).delete();

      if (cardsToInsert.isEmpty) {
        return "Súbor obsahuje dáta, ale nepodarilo sa vyextrahovať žiadne textové kartičky.";
      }

      // 3. AŽ TERAZ vytvoríme balíček v databáze
      String fileName = basenameWithoutExtension(file.path);
      String deckName = fileName.isNotEmpty ? fileName : "Anki Import";
      
      int newDeckId = await DatabaseHelper.instance.addNewDeck(deckName, "Anki");

      for (var card in cardsToInsert) {
        await DatabaseHelper.instance.addNewCard(newDeckId, card['prompt']!, card['answer']!);
      }

      return "🎉 Balíček '$deckName' bol vytvorený so ${cardsToInsert.length} kartičkami!";
    } catch (e) {
      return "⚠️ Chyba pri importe: $e";
    }
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}