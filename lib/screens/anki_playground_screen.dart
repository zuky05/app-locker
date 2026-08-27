import 'package:flutter/material.dart';
import '../services/anki_importer.dart';
import '../services/database_helper.dart';

class AnkiPlaygroundScreen extends StatefulWidget {
  const AnkiPlaygroundScreen({super.key});

  @override
  State<AnkiPlaygroundScreen> createState() => _AnkiPlaygroundScreenState();
}

class _AnkiPlaygroundScreenState extends State<AnkiPlaygroundScreen> {
  String statusMessage = "Pripravený na testovanie Anki Importu.\n(Tento screen môžeme kedykoľvek zmazať)";
  bool isImporting = false;

  void _testImport() async {
    setState(() {
      isImporting = true;
      statusMessage = "Vytváram dočasný testovací balíček...";
    });

    try {
      String deckName = "Anki Test ${DateTime.now().minute}:${DateTime.now().second}";
      await DatabaseHelper.instance.addNewDeck(deckName, "Playground");
      
      final decks = await DatabaseHelper.instance.getDecks();
      final newDeck = decks.last;

      setState(() {
        statusMessage = "Balíček '$deckName' vytvorený.\nProsím, vyber .apkg súbor...";
      });

      // TU JE ZMENA: Čakáme na náš detailný textový report
      String resultMsg = await AnkiImporter.importApkg(newDeck.id!);

      setState(() {
        isImporting = false;
        statusMessage = resultMsg; // Vypíše na obrazovku presne to, čo zistil Importer
      });
    } catch (e) {
      setState(() {
        isImporting = false;
        statusMessage = "⚠️ Hlavná chyba: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laboratórium 🧪"),
        backgroundColor: Colors.teal, // Nech sa to farebne líši od zvyšku appky
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.science, size: 80, color: Colors.teal),
              const SizedBox(height: 24),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),
              isImporting
                  ? const CircularProgressIndicator(color: Colors.teal)
                  : ElevatedButton.icon(
                      onPressed: _testImport,
                      icon: const Icon(Icons.download),
                      label: const Text("Vyskúšať Anki Import"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}