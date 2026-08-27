import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/deck_model.dart';
import 'package:flutter_svg/flutter_svg.dart';


class DeckDetailScreen extends StatefulWidget {
  final Deck deck;
  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  List<Map<String, dynamic>> cards = [];
  bool isLoading = true;
  
  // Sledujeme, na ktorej kartičke sme a či sme ju "otočili"
  int currentIndex = 0;
  bool showAnswer = false;
  
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final loadedCards = await DatabaseHelper.instance.getCardsForDeck(widget.deck.id!);
    setState(() {
      cards = loadedCards;
      isLoading = false;
    });
  }

  void _flipCard() {
    setState(() {
      showAnswer = !showAnswer;
    });
  }

  void _nextCard() {
    if (currentIndex < cards.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevCard() {
    if (currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _deleteCard() async {
    if (cards.isEmpty) return;

    final int indexToDelete = currentIndex;
    final int cardId = cards[indexToDelete]['id'];

    // 1. Animácia preč (nech to vyzerá plynulo)
    if (cards.length > 1) {
      if (indexToDelete < cards.length - 1) {
        await _pageController.nextPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        await _pageController.previousPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }

    // 2. Zmazať v databáze
    await DatabaseHelper.instance.removeCard(cardId);

    // 3. Stiahneme ÚPLNE NOVÝ zoznam (tým Flutteru dokážeme, že sa niečo zmenilo)
    final freshCards = await DatabaseHelper.instance.getCardsForDeck(widget.deck.id!);

    // 4. Bezpečné zarovnanie (Bez blikania!)
    setState(() {
      cards = freshCards;
      showAnswer = false;

      if (cards.isNotEmpty) {
        if (indexToDelete < cards.length) {
          _pageController.jumpToPage(indexToDelete); // Potichu skočíme tam, kde máme byť
        } else {
          _pageController.jumpToPage(cards.length - 1); // Ak sme zmazali poslednú
        }
      }
    });
  }

  void _showAddCardDialog() {
    final promptController = TextEditingController();
    final answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nová kartička'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: promptController,
              decoration: const InputDecoration(labelText: 'Otázka / Pojem'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: answerController,
              decoration: const InputDecoration(labelText: 'Správna odpoveď'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zrušiť')),
          ElevatedButton(
            onPressed: () async {
              if (promptController.text.isNotEmpty && answerController.text.isNotEmpty) {
                await DatabaseHelper.instance.addNewCard(
                  widget.deck.id!,
                  promptController.text,
                  answerController.text,
                );
                
                Navigator.pop(context); // Najprv zavrieme okienko
                
                // 1. POČKÁME, kým sa vytiahnu nové dáta z databázy
                await _loadCards(); 

                // 2. Dáme Flutteru "mikropauzu" (100 ms), aby stihol novú kartu reálne vykresliť
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (cards.isNotEmpty) {
                    // 3. Odscrollujeme úplne na koniec zoznamu k novej karte
                    _pageController.animateToPage(
                      cards.length - 1, 
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: const Text('Pridať'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.deck.name),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cards.isEmpty
              ? const Center(child: Text("Tento balíček je zatiaľ prázdny."))
              : Column(
                  children: [
                    // Zobrazenie počítadla (napr. 1 / 70)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "${currentIndex + 1} / ${cards.length}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    ),
                    
                    // Hlavná kartička
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          // Keď preswipujeme na novú kartu, vždy skryjeme odpoveď
                          setState(() {
                            currentIndex = index;
                            showAnswer = false;
                          });
                        },
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return GestureDetector(
                            key: ValueKey(card['id']),
                            onTap: _flipCard,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                              decoration: BoxDecoration(
                                color: showAnswer ? Colors.deepPurple.shade50 : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2, offset: Offset(0, 4))
                                ],
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 1. Malý nadpis na vrchu
                                      Text(
                                        showAnswer ? "ODPOVEĎ" : "OTÁZKA",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade500,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // 2. Obsah kartičky (Vlajka vs. Klasický text)
                                      if (!showAnswer && card['prompt'].toString().endsWith('.svg')) ...[
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: SvgPicture.asset(
                                            card['prompt'], // Správny kľúč pre cestu k SVG!
                                            height: 120,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        Text(
                                          showAnswer ? card['correct_answer'] : 'Komu patrí táto vlajka?',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                                        ),
                                      ] else ...[
                                        Text(
                                          showAnswer ? card['correct_answer'] : card['prompt'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                                        ),
                                      ],

                                      const SizedBox(height: 30),

                                      // 3. Ikona ruky
                                      Icon(
                                        Icons.touch_app,
                                        color: Colors.grey.shade300,
                                        size: 30,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Tlačidlá so šípkami naspodku
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40, top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _prevCard,
                            icon: const Icon(Icons.arrow_back_ios),
                            color: currentIndex > 0 ? Colors.deepPurple : Colors.grey,
                            iconSize: 30,
                          ),
                          const SizedBox(width: 40),
                          IconButton(
                            onPressed: _nextCard,
                            icon: const Icon(Icons.arrow_forward_ios),
                            color: currentIndex < cards.length - 1 ? Colors.deepPurple : Colors.grey,
                            iconSize: 30,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
      floatingActionButton: (widget.deck.isPremade == 0 || widget.deck.isPremade == false)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. Tlačidlo: VYMAZAŤ KARTIČKU
                if (cards.isNotEmpty) // Zobrazíme kôš iba vtedy, ak je v balíčku nejaká karta
                  FloatingActionButton(
                    heroTag: 'delete_btn', // TOTO JE TEN MAGICKÝ TAG!
                    onPressed: _deleteCard,
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.delete),
                  ),
                
                const SizedBox(height: 16), // Medzera medzi tlačidlami
                
                // 2. Tlačidlo: PRIDAŤ KARTIČKU
                FloatingActionButton.extended(
                  heroTag: 'add_btn', // AJ DRUHÉ MUSÍ MAŤ SVOJ TAG!
                  onPressed: _showAddCardDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Pridať"),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),

                FloatingActionButton.extended(
                  heroTag: 'removedeck_btn', // AJ DRUHÉ MUSÍ MAŤ SVOJ TAG!
                  onPressed: () async {
                    // 1. Zmažeme balíček (použijeme bezpečné ID z widgetu)
                    await DatabaseHelper.instance.removeDeck(widget.deck.id!);
                    // 2. Keďže balíček už neexistuje, vrátime používateľa späť na zoznam
                    Navigator.pop(context); 
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("deck"),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ],
            )
          : null,
          
    );

  }

}