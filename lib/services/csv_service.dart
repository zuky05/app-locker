import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'database_helper.dart';

class CsvService {
  
  // ==========================================
  // PROFESIONÁLNY VLASTNÝ CSV PARSER
  // (Zvláda viacriadkové hodnoty v úvodzovkách, tzv. Quizlet formát)
  // ==========================================
  static List<List<String>> _parseCsvCustom(String csvString) {
    List<List<String>> rows = [];
    List<String> currentRow = [];
    StringBuffer currentCell = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < csvString.length; i++) {
      String char = csvString[i];
      String? nextChar = (i + 1 < csvString.length) ? csvString[i + 1] : null;

      if (insideQuotes) {
        if (char == '"') {
          if (nextChar == '"') {
            // Escapovaná úvodzovka ("") vnútri úvodzoviek
            currentCell.write('"');
            i++; // Preskočíme druhú úvodzovku
          } else {
            // Koniec úvodzoviek
            insideQuotes = false;
          }
        } else {
          currentCell.write(char);
        }
      } else {
        if (char == '"') {
          // Začiatok úvodzoviek
          insideQuotes = true;
        } else if (char == ',' || char == ';') { // Podpora čiarky aj bodkočiarky
          // Koniec bunky
          currentRow.add(currentCell.toString());
          currentCell.clear();
        } else if (char == '\n' || (char == '\r' && nextChar == '\n')) {
          // Koniec riadku
          currentRow.add(currentCell.toString());
          currentCell.clear();
          rows.add(currentRow);
          currentRow = [];
          if (char == '\r') i++; // Preskočíme \n
        } else {
          currentCell.write(char);
        }
      }
    }
    
    // Pridanie poslednej bunky a riadku, ak neskončil novým riadkom
    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      rows.add(currentRow);
    }
    return rows;
  }

  // ==========================================
  // IMPORT CSV DO DATABÁZY
  // ==========================================
  static Future<String?> importDeckFromCsv() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Všetky súbory',
        mimeTypes: ['*/*'], // Hrubá sila pre Android File Picker
      );
      
      final XFile? xFile = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (xFile != null) {
        if (!xFile.name.toLowerCase().endsWith('.csv')) {
          return "Prosím, vyberte súbor s príponou .csv";
        }

        final csvString = await xFile.readAsString();
        
        // Použitie nášho vlastného parsera (NULA chýb vo VS Code)
        List<List<String>> csvData = _parseCsvCustom(csvString);

        if (csvData.isEmpty) return "Súbor je prázdny.";

        String deckName = xFile.name.replaceAll('.csv', '');
        int newDeckId = await DatabaseHelper.instance.addNewDeck(deckName, 'Importované z CSV');

        int importedCount = 0;
        for (int i = 0; i < csvData.length; i++) {
          var row = csvData[i];
          
          if (row.length >= 2) {
            String question = row[0].trim();
            String answer = row[1].trim();
            
            if (i == 0 && (question.toLowerCase().contains('otazka') || 
                           question.toLowerCase().contains('question') || 
                           question.toLowerCase().contains('term'))) {
              continue; 
            }

            if (question.isNotEmpty && answer.isNotEmpty) {
              await DatabaseHelper.instance.addNewCard(newDeckId, question, answer);
              importedCount++;
            }
          }
        }
        return "Úspešne importovaných $importedCount kartičiek do balíčka '$deckName'.";
      }
      return null;
    } catch (e) {
      return "Nastala chyba pri importe: $e";
    }
  }

  // ==========================================
  // EXPORT BALÍČKA DO CSV
  // ==========================================
  static Future<void> exportDeckToCsv(int deckId, String deckName) async {
    try {
      final cards = await DatabaseHelper.instance.getCardsForDeck(deckId);
      
      StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln('Otazka,Odpoved'); 
      
      for (var card in cards) {
        String q = card['prompt']?.toString().replaceAll('"', '""') ?? '';
        String a = card['correct_answer']?.toString().replaceAll('"', '""') ?? '';
        
        // Pri exporte pridávame úvodzovky kôli bezpečnosti
        csvBuffer.writeln('"$q","$a"');
      }

      final directory = await getTemporaryDirectory();
      final safeDeckName = deckName.replaceAll(' ', '_'); 
      final path = '${directory.path}/$safeDeckName.csv';
      final file = File(path);
      await file.writeAsString(csvBuffer.toString());

      await Share.shareXFiles([XFile(path)], text: 'Export balíčka: $deckName');
      
    } catch (e) {
      debugPrint("Chyba pri exporte: $e");
    }
  }
}