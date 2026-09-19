import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// Oficiálny balíček od Flutter tímu namiesto problémového file_picker
import 'package:file_selector/file_selector.dart'; 
import 'database_helper.dart';

class CsvService {
  
  // ==========================================
  // IMPORT CSV DO DATABÁZY
  // ==========================================
  static Future<String?> importDeckFromCsv() async {
    try {
      // 1. Spolahlivý výber súboru cez oficiálny file_selector
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'CSV Files',
        extensions: <String>['csv'],
      );
      
      final XFile? xFile = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (xFile != null) {
        final csvString = await xFile.readAsString();
        
        // 2. VLASTNÝ PARSER (žiadne závislosti na CSV balíčkoch)
        List<List<String>> csvData = [];
        List<String> lines = csvString.split('\n');
        
        for (String line in lines) {
          if (line.trim().isEmpty) continue;
          List<String> row = line.contains(';') ? line.split(';') : line.split(',');
          csvData.add(row);
        }

        if (csvData.isEmpty) return "Súbor je prázdny.";

        // Extrahujeme bezpečné meno
        String deckName = xFile.name.replaceAll('.csv', '');
        int newDeckId = await DatabaseHelper.instance.addNewDeck(deckName, 'Importované z CSV');

        int importedCount = 0;
        for (int i = 0; i < csvData.length; i++) {
          var row = csvData[i];
          
          if (row.length >= 2) {
            String question = row[0].replaceAll('"', '').trim();
            String answer = row[1].replaceAll('"', '').trim();
            
            if (i == 0 && (question.toLowerCase().contains('otazka') || question.toLowerCase().contains('question'))) {
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
      
      // 3. VLASTNÝ GENERÁTOR
      StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln('Otazka,Odpoved'); 
      
      for (var card in cards) {
        String q = card['prompt']?.toString().replaceAll('"', '""') ?? '';
        String a = card['correct_answer']?.toString().replaceAll('"', '""') ?? '';
        csvBuffer.writeln('"$q","$a"');
      }

      final directory = await getTemporaryDirectory();
      final safeDeckName = deckName.replaceAll(' ', '_'); 
      final path = '${directory.path}/$safeDeckName.csv';
      final file = File(path);
      await file.writeAsString(csvBuffer.toString());

      // 4. Univerzálne zdieľanie pre staršie aj novšie verzie
      // Upozornenie: Ak IDE podčiarkne Share modrou vlnovkou, je to len Warning, appka pôjde!
      await Share.shareXFiles([XFile(path)], text: 'Export balíčka: $deckName');
      
    } catch (e) {
      debugPrint("Chyba pri exporte: $e");
    }
  }
}