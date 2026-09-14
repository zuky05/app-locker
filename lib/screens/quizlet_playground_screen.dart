import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/database_helper.dart';
import '../themes/theme_provider.dart';

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
    
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'QuizletChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _processExtractedData(message.message);
        },
      )
      ..loadRequest(Uri.parse('https://quizlet.com/search?query=medicine&type=sets'));
  }

  void _extractCards() async {
    setState(() {
      isExtracting = true;
      statusMessage = "Rolujem, klikám na 'See more' a zbieram dáta... 👻";
    });

    const String jsCode = '''
      async function extractAll() {
        try {
          var extracted = new Map(); 
          var scrollAttempts = 0;
          
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

          function clickSeeMore() {
            var buttons = document.querySelectorAll('button');
            for (var i = 0; i < buttons.length; i++) {
              if (buttons[i].innerText && buttons[i].innerText.toLowerCase().includes('see more')) {
                buttons[i].click();
                return;
              }
            }
          }

          window.scrollTo(0, 0);
          await new Promise(r => setTimeout(r, 500));
          
          while (scrollAttempts < 4) {
            collectVisible(); 
            clickSeeMore();
            
            var oldY = window.scrollY;
            window.scrollBy(0, 1000); 
            await new Promise(r => setTimeout(r, 800)); 
            
            if (window.scrollY === oldY || (window.innerHeight + window.scrollY) >= document.body.scrollHeight - 50) {
              scrollAttempts++; 
            } else {
              scrollAttempts = 0; 
            }
          }
          
          collectVisible();
          
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

      String deckName = "Quizlet Test ${DateTime.now().minute}:${DateTime.now().second}";
      await DatabaseHelper.instance.addNewDeck(deckName, "Playground");
      final decks = await DatabaseHelper.instance.getDecks();
      final newDeck = decks.last;

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    final Color accentColor = currentTheme.quickImportColor;
    final Color buttonFgColor = currentTheme.getContrastTextColor(accentColor);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Quizlet Lab 🕷️"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: currentTheme.getTileBg(isGranted: false, accentColor: accentColor),
            ),
            child: Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: controller),
          ),
        ],
      ),
      floatingActionButton: isExtracting
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: currentTheme.buttonBorderRadius,
                side: BorderSide.none,
              ),
              child: CircularProgressIndicator(color: accentColor),
            )
          : FloatingActionButton.extended(
              onPressed: _extractCards,
              icon: const Icon(Icons.downloading),
              label: const Text("Vytiahnuť kartičky", style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: accentColor,
              foregroundColor: buttonFgColor,
              shape: RoundedRectangleBorder(
                borderRadius: currentTheme.buttonBorderRadius,
                side: BorderSide.none,
              ),
              elevation: theme.appBarTheme.elevation ?? 0,
            ),
    );
  }
}