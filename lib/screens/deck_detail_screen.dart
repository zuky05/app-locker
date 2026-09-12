import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../models/deck_model.dart';
import '../themes/theme_provider.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;
  final bool isReadOnly;
  const DeckDetailScreen({
    super.key,
    required this.deck,
    this.isReadOnly = false,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  List<Map<String, dynamic>> cards = [];
  bool isLoading = true;

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

    if (cards.length > 1) {
      if (indexToDelete < cards.length - 1) {
        await _pageController.nextPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        await _pageController.previousPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }

    await DatabaseHelper.instance.removeCard(cardId);
    final freshCards = await DatabaseHelper.instance.getCardsForDeck(widget.deck.id!);

    setState(() {
      cards = freshCards;
      showAnswer = false;

      if (cards.isNotEmpty) {
        if (indexToDelete < cards.length) {
          _pageController.jumpToPage(indexToDelete);
        } else {
          _pageController.jumpToPage(cards.length - 1);
        }
      }
    });
  }

  void _showAddCardDialog() {
    final promptController = TextEditingController();
    final answerController = TextEditingController();
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = currentTheme.decksColor;
    final Color textColor = currentTheme.getContrastTextColor(sectionColor);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: currentTheme.buttonBorder,
        ),
        title: Text(
          'Nová kartička', 
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: promptController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Otázka / Pojem',
                labelStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: sectionColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: answerController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Správna odpoveď',
                labelStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: sectionColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: Text(
              'Zrušiť', 
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (promptController.text.isNotEmpty && answerController.text.isNotEmpty) {
                await DatabaseHelper.instance.addNewCard(
                  widget.deck.id!,
                  promptController.text,
                  answerController.text,
                );

                if (!mounted) return;
                Navigator.pop(dialogContext);

                await _loadCards();

                Future.delayed(const Duration(milliseconds: 100), () {
                  if (cards.isNotEmpty) {
                    _pageController.animateToPage(
                      cards.length - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: sectionColor,
              foregroundColor: textColor,
              shape: RoundedRectangleBorder(
                borderRadius: currentTheme.buttonBorderRadius,
                side: currentTheme.buttonBorder,
              ),
            ),
            child: const Text('Pridať'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    final Color sectionColor = currentTheme.decksColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.deck.name),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: sectionColor))
          : cards.isEmpty
              ? Center(
                  child: Text(
                    "Tento balíček je zatiaľ prázdny.",
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "${currentIndex + 1} / ${cards.length}",
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: sectionColor,
                        ),
                      ),
                    ),

                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            currentIndex = index;
                            showAnswer = false;
                          });
                        },
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];

                          final cardDecoration = showAnswer
                              ? currentTheme.getCardDecoration(sectionColor, isSelected: true)
                              : currentTheme.getCardDecoration(sectionColor);

                          final Color cardTextColor = showAnswer
                              ? currentTheme.getContrastTextColor(sectionColor)
                              : theme.colorScheme.onSurface;

                          return GestureDetector(
                            key: ValueKey(card['id']),
                            onTap: _flipCard,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                              decoration: cardDecoration,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        showAnswer ? "ODPOVEĎ" : "OTÁZKA",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: cardTextColor.withValues(alpha: 0.7),
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      if (!showAnswer && card['prompt'].toString().endsWith('.svg')) ...[
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: SvgPicture.asset(
                                            card['prompt'],
                                            height: 120,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Komu patrí táto vlajka?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 22, 
                                            fontWeight: FontWeight.w600,
                                            color: cardTextColor,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          showAnswer ? card['correct_answer'] : card['prompt'],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 24, 
                                            fontWeight: FontWeight.w600,
                                            color: cardTextColor,
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 30),

                                      Icon(
                                        Icons.touch_app,
                                        color: cardTextColor.withValues(alpha: 0.4),
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

                    Padding(
                      padding: const EdgeInsets.only(bottom: 40, top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _prevCard,
                            icon: const Icon(Icons.arrow_back_ios),
                            color: currentIndex > 0 
                                ? sectionColor 
                                : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                            iconSize: 30,
                          ),
                          const SizedBox(width: 40),
                          IconButton(
                            onPressed: _nextCard,
                            icon: const Icon(Icons.arrow_forward_ios),
                            color: currentIndex < cards.length - 1 
                                ? sectionColor 
                                : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                            iconSize: 30,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
      floatingActionButton: !widget.isReadOnly
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (cards.isNotEmpty)
                  FloatingActionButton(
                    heroTag: 'delete_btn',
                    onPressed: _deleteCard,
                    backgroundColor: currentTheme.errorColor,
                    foregroundColor: currentTheme.getContrastTextColor(currentTheme.errorColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: currentTheme.cardBorderRadius,
                      
                    ),
                    child: const Icon(Icons.delete),
                  ),

                const SizedBox(height: 16),

                FloatingActionButton.extended(
                  heroTag: 'add_btn',
                  onPressed: _showAddCardDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Pridať"),
                  backgroundColor: sectionColor,
                  foregroundColor: currentTheme.getContrastTextColor(sectionColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.cardBorderRadius,
                    
                  ),
                ),
              ],
            )
          : null,
    );
  }
}