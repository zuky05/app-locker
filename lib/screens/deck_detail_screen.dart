import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../models/deck_model.dart';
import '../themes/app_themes.dart';
import '../themes/theme_provider.dart';
import '../themes/themed_background.dart';

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

  void _showAddCardBottomSheet() {
    final promptController = TextEditingController();
    final answerController = TextEditingController();
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = currentTheme.decksColor;
    final bool isVibrant = currentTheme.id == 5;
    final bool isSoft = currentTheme.id == 1;

    final dialogBgColor = isSoft
        ? const Color(0xFFD1D9E6)
        : (isVibrant ? const Color(0xFF0F172A) : theme.cardColor);

    final dialogTextColor = isSoft
        ? const Color(0xFF2D3748)
        : (isVibrant ? Colors.white : theme.colorScheme.onSurface);

    final BoxDecoration inputDecoration = isSoft
        ? BoxDecoration(
            color: const Color(0xFFC8D3E6),
            borderRadius: currentTheme.cardBorderRadius,
            boxShadow: const [
              BoxShadow(color: Color(0xFF97A7C0), offset: Offset(2, 2), blurRadius: 4),
              BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
            ],
          )
        : (isVibrant
            ? BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                borderRadius: currentTheme.cardBorderRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              )
            : BoxDecoration(
                color: theme.cardColor,
                borderRadius: currentTheme.cardBorderRadius,
                border: currentTheme.id == 2
                    ? Border.all(color: Colors.black, width: 3.5)
                    : Border.all(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
              ));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dialogBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: currentTheme.buttonBorder,
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: dialogTextColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(
                "Nová kartička",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: dialogTextColor,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: inputDecoration,
                child: TextField(
                  controller: promptController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: dialogTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: "Otázka / Pojem (Predná strana)",
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(
                      color: dialogTextColor.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: inputDecoration,
                child: TextField(
                  controller: answerController,
                  minLines: 2,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: dialogTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: "Správna odpoveď (Zadná strana)",
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(
                      color: dialogTextColor.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final prompt = promptController.text.trim();
                    final answer = answerController.text.trim();

                    if (prompt.isNotEmpty && answer.isNotEmpty) {
                      await DatabaseHelper.instance.addNewCard(
                        widget.deck.id!,
                        prompt,
                        answer,
                      );

                      if (!mounted) return;
                      Navigator.pop(bottomSheetContext);

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
                  borderRadius: currentTheme.buttonBorderRadius,
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: currentTheme.getCardDecoration(sectionColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded, 
                          color: isVibrant ? Colors.white : currentTheme.getIconColor(sectionColor),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Pridať kartičku",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isVibrant ? Colors.white : currentTheme.getContrastTextColor(sectionColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = currentTheme.decksColor;
    final bool isVibrant = currentTheme.id == 5;
    final bool isSoft = currentTheme.id == 1;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.deck.name),
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: theme.appBarTheme.elevation ?? 0,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: sectionColor))
            : cards.isEmpty
                ? Center(
                    child: Text(
                      "Tento balíček je zatiaľ prázdny.",
                      style: TextStyle(color: isSoft ? const Color(0xFF718096) : (isVibrant ? Colors.white.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.7))),
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
                            color: isSoft ? sectionColor : (isVibrant ? Colors.white : sectionColor),
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

                            // 🟢 VŽDY ROVNAKÁ NEUMORFNÁ KARTA PRE OBE STRANY
                            final cardDecoration = currentTheme.getCardDecoration(sectionColor);

                            final Color cardTextColor = isSoft
                                ? const Color(0xFF2D3748)
                                : (isVibrant ? Colors.white : theme.colorScheme.onSurface);

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
                                            color: isSoft ? const Color(0xFF718096) : cardTextColor.withValues(alpha: 0.7),
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
                                          color: isSoft ? const Color(0xFF97A7C0) : cardTextColor.withValues(alpha: 0.4),
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
                              icon: const Icon(Icons.arrow_back_ios_rounded),
                              color: currentIndex > 0 
                                  ? (isSoft ? sectionColor : (isVibrant ? Colors.white : sectionColor)) 
                                  : (isSoft ? const Color(0xFF97A7C0) : (isVibrant ? Colors.white24 : theme.colorScheme.onSurface.withValues(alpha: 0.25))),
                              iconSize: 30,
                            ),
                            const SizedBox(width: 40),
                            IconButton(
                              onPressed: _nextCard,
                              icon: const Icon(Icons.arrow_forward_ios_rounded),
                              color: currentIndex < cards.length - 1 
                                  ? (isSoft ? sectionColor : (isVibrant ? Colors.white : sectionColor)) 
                                  : (isSoft ? const Color(0xFF97A7C0) : (isVibrant ? Colors.white24 : theme.colorScheme.onSurface.withValues(alpha: 0.25))),
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
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _deleteCard,
                        borderRadius: currentTheme.buttonBorderRadius,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: currentTheme.getCardDecoration(currentTheme.errorColor),
                          child: Icon(
                            Icons.delete, 
                            color: isSoft ? currentTheme.errorColor : currentTheme.getContrastTextColor(currentTheme.errorColor), 
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showAddCardBottomSheet,
                      borderRadius: currentTheme.buttonBorderRadius,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: currentTheme.getCardDecoration(sectionColor),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add, 
                              color: isSoft ? sectionColor : (isVibrant ? Colors.white : currentTheme.getContrastTextColor(sectionColor)), 
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Pridať",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSoft ? const Color(0xFF2D3748) : (isVibrant ? Colors.white : currentTheme.getContrastTextColor(sectionColor)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}