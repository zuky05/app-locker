import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'database_helper.dart';

class AnkiImporter {
  static Future<String> importApkg(int deckId) async {
    try {
      final pickedFile = await FilePicker.pickFile();
      
      if (pickedFile == null || pickedFile.path == null) {
        return "Zrušil si výber súboru.";
      }

      File file = File(pickedFile.path!);
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

      if (notes.isEmpty) return "Databáza otvorená, ale tabuľka 'notes' je úplne prázdna!";

      int importedCount = 0;

      for (var note in notes) {
        String flds = note['flds'] as String;
        List<String> fields = flds.split('\x1f');
        
        // INTELIGENTNÝ FILTER: Zozbiera iba polia, v ktorých reálne nejaký text je
        List<String> validTextParts = [];
        for (var field in fields) {
          String cleaned = _cleanText(field);
          if (cleaned.isNotEmpty) {
            validTextParts.add(cleaned);
          }
        }

        // Ak sme našli aspoň 2 časti s textom (štandardná karta)
        if (validTextParts.length >= 2) {
          String prompt = validTextParts[0];
          String answer = validTextParts[1];
          await DatabaseHelper.instance.addNewCard(deckId, prompt, answer);
          importedCount++;
        } 
        // Bonus: Ak karta mala len 1 jediný text (napríklad Cloze doplňovačky)
        else if (validTextParts.length == 1) {
          await DatabaseHelper.instance.addNewCard(deckId, validTextParts[0], "(Zisti z kontextu: ${validTextParts[0]})");
          importedCount++;
        }
      }

      await ankiDb.close();
      await File(dbPath).delete();

      if (importedCount == 0) {
        return "Našlo sa ${notes.length} poznámok, ale žiadna nedávala zmysel.";
      }

      return "🎉 ÚSPECH: Neskutočné! Podarilo sa pridať $importedCount kartičiek do tvojho balíčka!";
    } catch (e) {
      return "⚠️ Výnimka: $e";
    }
  }

  // Funkcia teraz čistí aj zbytočné medzery naviac, aby bol text dokonale pekný
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Zmaže HTML (napr. <b>, <div>)
        .replaceAll('&nbsp;', ' ')          // Nahradí HTML medzery
        .trim();
  }
}