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
      // Komunikačný kanál
      ..addJavaScriptChannel(
        'QuizletChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _processExtractedData(message.message);
        },
      )
      ..loadRequest(Uri.parse('https://quizlet.com/search?query=medicine&type=sets'));
  }

  // Funkcia, ktorá vstrekne náš kód do Quizlet stránky
  void _extractCards() async {
    setState(() {
      isExtracting = true;
      statusMessage = "Rolujem, klikám na 'See more' a zbieram dáta... 👻";
    });

    // VYLEPŠENÝ JAVASCRIPT: Auto-Scroller s automatickým klikaním!
    const String jsCode = '''
      async function extractAll() {
        try {
          var extracted = new Map(); 
          var scrollAttempts = 0;
          
          // Zber toho, čo je práve na obrazovke
          function collectVisible() {
            var termElements = document.querySelectorAll('.TermText');
            for (var i = 0; i < termElements.length - 1; i += 2) {
              if (termElements[i] && termElements[i+1]) {
                var q = termElements[i].innerText.trim();
                var a = termElements[i+1].innerText.trim();
                if (q !== "" && a !== "") {
                  extracted.set(q, a); 
                }
              }
            }
          }

          // NOVÁ FUNKCIA: Hľadáčik na tlačidlo "See more"
          function clickSeeMore() {
            var buttons = document.querySelectorAll('button');
            for (var i = 0; i < buttons.length; i++) {
              // Hľadáme tlačidlo, ktoré obsahuje text "See more" (odignorujeme veľké/malé písmená)
              if (buttons[i].innerText && buttons[i].innerText.toLowerCase().includes('see more')) {
                buttons[i].click(); // KLIK!
                return; // Našli sme a klikli, môžeme ísť ďalej
              }
            }
          }

          window.scrollTo(0, 0);
          await new Promise(r => setTimeout(r, 500));
          
          // Zvýšili sme limit na 4 pokusy, aby robot počkal aj pri veľmi dlhých balíčkoch
          while (scrollAttempts < 4) {
            collectVisible(); 
            
            clickSeeMore(); // Pred rolovaním robot skontroluje, či netreba otvoriť ďalšie karty!
            
            var oldY = window.scrollY;
            window.scrollBy(0, 1000); 
            await new Promise(r => setTimeout(r, 800)); 
            
            if (window.scrollY === oldY || (window.innerHeight + window.scrollY) >= document.body.scrollHeight - 50) {
              scrollAttempts++; 
            } else {
              scrollAttempts = 0; 
            }
          }
          
          collectVisible(); // Posledný zber na dne
          
          var cards = [];
          extracted.forEach(function(value, key) {
            cards.push({q: key, a: value});
          });
          
          QuizletChannel.postMessage(JSON.stringify(cards));
        } catch(e) {
          QuizletChannel.postMessage("ERROR:" + e.toString());
        }
      }
      
      extractAll(); 
    ''';

    await controller.runJavaScript(jsCode);
  }

  // Funkcia, ktorá spracuje dáta z JS
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
          Expanded(
            child: WebViewWidget(controller: controller),
          ),
        ],
      ),
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