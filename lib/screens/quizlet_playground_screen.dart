import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../services/database_helper.dart';

class QuizletPlaygroundScreen extends StatefulWidget {
  const QuizletPlaygroundScreen({super.key});

  @override
  State<QuizletPlaygroundScreen> createState() => _QuizletPlaygroundScreenState();
}

class _QuizletPlaygroundScreenState extends State<QuizletPlaygroundScreen> {
  late final WebViewController controller;
  bool isExtracting = false;
  String statusMessage = "Nájdi balíček a klikni na 'Vytiahnuť kartičky'";

  @override
  void initState() {
    super.initState();
    
    // Inicializácia webového prehliadača
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Týmto vytvoríme komunikačný kanál medzi JavaScriptom na webe a naším Flutter kódom
      ..addJavaScriptChannel(
        'QuizletChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _processExtractedData(message.message);
        },
      )
      // Načítame úvodnú stránku Quizletu (rovno hľadanie, nech to máme rýchlejšie)
      ..loadRequest(Uri.parse('https://quizlet.com/search?query=medicine&type=sets'));
  }

  // Funkcia, ktorá vstrekne náš kód do Quizlet stránky
  void _extractCards() async {
    setState(() {
      isExtracting = true;
      statusMessage = "Cucám dáta z obrazovky...";
    });

    // Toto je náš tajný JavaScript Scraper
    // Hľadá všetky prvky s triedou 'TermText' (Otázka, Odpoveď, Otázka, Odpoveď...)
    const String jsCode = '''
      try {
        var termElements = document.querySelectorAll('.TermText');
        var cards = [];
        
        for (var i = 0; i < termElements.length; i += 2) {
          if (i + 1 < termElements.length) {
            var q = termElements[i].innerText;
            var a = termElements[i+1].innerText;
            cards.push({q: q, a: a});
          }
        }
        // Výsledok pošleme späť do Flutteru ako JSON text
        QuizletChannel.postMessage(JSON.stringify(cards));
      } catch(e) {
        QuizletChannel.postMessage("ERROR:" + e.toString());
      }
    ''';

    await controller.runJavaScript(jsCode);
  }

  // Funkcia, ktorá spracuje dáta, ktoré nám poslal JavaScript
  void _processExtractedData(String data) async {
    if (data.startsWith("ERROR:")) {
       setState(() {
         isExtracting = false;
         statusMessage = "Chyba na webe: ${data.substring(6)}";
       });
       return;
    }

    try {
      List<dynamic> cards = jsonDecode(data);
      
      if (cards.isEmpty) {
        setState(() {
          isExtracting = false;
          statusMessage = "⚠️ Nenašli sa kartičky. Si v Quizlete na stránke s balíčkom?";
        });
        return;
      }

      // Vytvoríme testovací balíček v našej databáze
      String deckName = "Quizlet Test ${DateTime.now().minute}:${DateTime.now().second}";
      await DatabaseHelper.instance.addNewDeck(deckName, "Playground");
      final decks = await DatabaseHelper.instance.getDecks();
      final newDeck = decks.last;

      // Uložíme všetky vytiahnuté kartičky
      for (var card in cards) {
        await DatabaseHelper.instance.addNewCard(newDeck.id!, card['q'], card['a']);
      }

      setState(() {
        isExtracting = false;
        statusMessage = "🎉 Úspech! Vytiahnutých ${cards.length} kartičiek do balíčka '$deckName'.";
      });

    } catch (e) {
      setState(() {
         isExtracting = false;
         statusMessage = "Chyba pri spracovaní dát: $e";
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quizlet Lab 🕷️"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Informačný panel navrchu
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.blueGrey.shade100,
            child: Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          // Samotný webový prehliadač (zaberá zvyšok obrazovky)
          Expanded(
            child: WebViewWidget(controller: controller),
          ),
        ],
      ),
      // Tlačidlo, ktoré spustí kradnutie kartičiek
      floatingActionButton: isExtracting
          ? const FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: _extractCards,
              icon: const Icon(Icons.downloading),
              label: const Text("Vytiahnuť kartičky"),
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
    );
  }
}