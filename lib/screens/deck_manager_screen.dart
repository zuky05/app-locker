import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../models/deck_model.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';
import 'deck_detail_screen.dart';
import 'quiz_overlay_screen.dart';
import 'quizlet_playground_screen.dart';
import '../services/anki_importer.dart';

// 1. IMPORT REVENUECAT
import '../services/revenuecat_service.dart';

class DeckManagerScreen extends StatefulWidget {
  const DeckManagerScreen({super.key});

  @override
  State<DeckManagerScreen> createState() => _DeckManagerScreenState();
}

class _DeckManagerScreenState extends State<DeckManagerScreen> with SingleTickerProviderStateMixin {
  List<Deck> myDecks = [];
  List<Deck> premadeDecks = [];
  bool isLoading = true;
  bool isPremium = false; // 2. PRIDANÁ PREMENNÁ PRE PREMIUM
  
  int? expandedDeckId;
  int? activeBlockerDeckId;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); 
    });
    _loadDecks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    final loadedDecks = await DatabaseHelper.instance.getDecks();
    final prefs = await SharedPreferences.getInstance();
    int? activeId = prefs.getInt('active_test_deck_id');

    if (activeId != null) {
      final activeCardCount = await DatabaseHelper.instance.getCardCountForDeck(activeId);
      if (activeCardCount < 5) {
        await prefs.remove('active_test_deck_id');
        activeId = null;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Aktívny balíček bol odznačený, pretože má menej ako 5 kariet."),
            ),
          );
        }
      }
    }
    
    // 3. NAČÍTAME STAV PREDPLATNÉHO
    final premiumStatus = await RevenueCatService.isPremium();
    if (!mounted) return;

    setState(() {
      myDecks = loadedDecks.where((d) => d.isPremade == 0 || d.isPremade == false).toList();
      premadeDecks = loadedDecks.where((d) => d.isPremade == 1 || d.isPremade == true).toList();
      activeBlockerDeckId = activeId;
      isPremium = premiumStatus;
      isLoading = false;
    });
  }

  String _getCategoryDescription(String category) {
    switch (category.toLowerCase().trim()) {
      case 'geography':
        return 'Otestuj svoje znalosti hlavných miest, vlajok a geografie sveta.';
      case 'language':
        return 'Rozšír si slovnú zásobu v najpoužívanejších svetových jazykoch.';
      case 'technology':
      case 'tech':
      case 'it':
        return 'Ovládni HTTP status kódy, Linux príkazy a základné vývojárske koncepty.';
      default:
        return 'Pripravené kolekcie kartičiek pre rýchle učenie.';
    }
  }

  Future<void> _handleAnkiImport() async {
    final String? result = await AnkiImporter.importApkgDirect();
    if (result == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    _loadDecks();
  }

  IconData _getCategoryIcon(String category) {
    final cleanCategory = category.trim().toLowerCase();
    if (cleanCategory.contains('geography')) return Icons.public;
    if (cleanCategory.contains('language')) return Icons.translate;
    if (cleanCategory.contains('tech')) return Icons.terminal;
    return Icons.folder_special;
  }

  Color get _decksAccentColor => const Color(0xFFBD00FF);

  BoxDecoration _getCardDecoration(AppThemeData currentTheme, Color accentColor, {bool isActive = false}) {
    final theme = currentTheme.theme;
    
    if (isActive) {
      return BoxDecoration(
        color: theme.cardColor,
        borderRadius: currentTheme.cardBorderRadius,
        border: currentTheme.id == 2 ? Border.all(color: Colors.black, width: 3.5) : Border.all(color: const Color(0xFF00E676), width: 3.0),
        boxShadow: const [],
        gradient: currentTheme.id == 2 ? null : currentTheme.cardGradient,
      );
    }

    Border border;
    if (currentTheme.id == 2) {
      border = Border.all(color: Colors.black, width: 3.5);
    } else {
      border = Border.all(color: accentColor, width: 1.5);
    }

    List<BoxShadow>? shadows;
    if (currentTheme.id == 0) {
      shadows = [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.35),
          blurRadius: 10,
          spreadRadius: 1,
        )
      ];
    } else if (currentTheme.id == 2) {
      shadows = const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)];
    } else {
      shadows = currentTheme.cardShadows;
    }

    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: currentTheme.cardBorderRadius,
      border: border,
      boxShadow: shadows,
      gradient: currentTheme.id == 2 ? null : currentTheme.cardGradient,
    );
  }

  void _showAddDeckDialog() async {
    final int customCount = await DatabaseHelper.instance.getCustomDeckCount();
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = _decksAccentColor;

    // 4. KĽÚČOVÁ ZMENA: Dialóg sa ukáže len ak NEMÁ premium a má >= 3 balíčky
    if (customCount >= 3 && !isPremium) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: currentTheme.id == 2 ? Colors.white : theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: currentTheme.cardBorderRadius,
            side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 3.5) : BorderSide.none,
          ),
          title: const Column(
            children: [
              Icon(Icons.star_rounded, size: 50, color: Colors.amber),
              SizedBox(height: 10),
              Text(
                "Odomkni Brainlock Premium!",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          content: Text(
            "Dosiahol si limit 3 vlastných balíčkov zadarmo.\n\nPre neobmedzené vytváranie kartičiek a prístup ku všetkým balíčkom si aktivuj Premium.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: currentTheme.id == 2 ? Colors.black87 : theme.colorScheme.onSurface),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: currentTheme.buttonBorderRadius),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Zrušiť"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Zavrieme dialóg
                // 5. TLAČIDLO TERAZ OTVÁRA PAYWALL
                final success = await RevenueCatService.presentPaywall();
                if (success) {
                  _loadDecks(); // Obnovíme stav
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vitaj v Premium klube! 🎉"), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: currentTheme.buttonBorderRadius),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Odomknúť Premium", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.id == 2 ? Colors.white : theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 3.5) : BorderSide.none,
        ),
        title: Text(
          'Pridať nový balíček', 
          textAlign: TextAlign.center, 
          style: TextStyle(fontWeight: FontWeight.bold, color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTheme.id == 2 ? Colors.black : sectionColor,
                  foregroundColor: currentTheme.id == 2 ? Colors.white : (sectionColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.buttonBorderRadius,
                    side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateManualDeckDialog();
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Add new deck", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTheme.id == 2 ? Colors.black : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.buttonBorderRadius,
                    side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QuizletPlaygroundScreen()),
                  ).then((_) => _loadDecks());
                },
                icon: const Icon(Icons.school),
                label: const Text("Import from Quizlet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTheme.id == 2 ? Colors.black : Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.buttonBorderRadius,
                    side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _handleAnkiImport();
                },
                icon: const Icon(Icons.upload_file),
                label: const Text("Import from Anki", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateManualDeckDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = _decksAccentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.id == 2 ? Colors.white : theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 3.5) : BorderSide.none,
        ),
        title: Text('Nový balíček', style: TextStyle(color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController, 
              style: TextStyle(color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Názov',
                labelStyle: TextStyle(color: currentTheme.id == 2 ? Colors.black54 : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: currentTheme.id == 2 ? Colors.black : sectionColor)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController, 
              style: TextStyle(color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Kategória (napr. Jazyky)',
                labelStyle: TextStyle(color: currentTheme.id == 2 ? Colors.black54 : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: currentTheme.id == 2 ? Colors.black : sectionColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Zrušiť', style: TextStyle(color: currentTheme.id == 2 ? Colors.black54 : theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && categoryController.text.isNotEmpty) {
                await DatabaseHelper.instance.addNewDeck(nameController.text, categoryController.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadDecks();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: currentTheme.id == 2 ? Colors.black : sectionColor, 
              foregroundColor: currentTheme.id == 2 ? Colors.white : (sectionColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: currentTheme.buttonBorderRadius,
                side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
              ),
            ),
            child: const Text('Vytvoriť'),
          ),
        ],
      ),
    );
  }

  void _showRenameDeckDialog(Deck deck) {
    final nameController = TextEditingController(text: deck.name);
    final categoryController = TextEditingController(text: deck.category);
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = _decksAccentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.id == 2 ? Colors.white : theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 3.5) : BorderSide.none,
        ),
        title: Text('Upraviť balíček', style: TextStyle(color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController, 
              style: TextStyle(color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Názov balíčka',
                labelStyle: TextStyle(color: currentTheme.id == 2 ? Colors.black54 : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: currentTheme.id == 2 ? Colors.black : sectionColor)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController, 
              style: TextStyle(color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Kategória',
                labelStyle: TextStyle(color: currentTheme.id == 2 ? Colors.black54 : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: currentTheme.id == 2 ? Colors.black : sectionColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Zrušiť', style: TextStyle(color: currentTheme.id == 2 ? Colors.black54 : theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && categoryController.text.isNotEmpty) {
                Navigator.pop(context);
                await DatabaseHelper.instance.updateDeck(deck.id!, nameController.text, categoryController.text);
                _loadDecks();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: currentTheme.id == 2 ? Colors.black : sectionColor, 
              foregroundColor: currentTheme.id == 2 ? Colors.white : (sectionColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: currentTheme.buttonBorderRadius,
                side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
              ),
            ),
            child: const Text('Uložiť'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Deck deck) {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final theme = currentTheme.theme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.id == 2 ? Colors.white : theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 3.5) : BorderSide.none,
        ),
        title: Text('Vymazať balíček?', style: TextStyle(color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Text(
          'Naozaj chceš vymazať balíček "${deck.name}"? Táto akcia je nenávratná a vymaže aj všetky kartičky v ňom.',
          style: TextStyle(color: currentTheme.id == 2 ? Colors.black87 : theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Zrušiť', style: TextStyle(color: currentTheme.id == 2 ? Colors.black54 : theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: currentTheme.buttonBorderRadius),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.removeDeck(deck.id!);
              
              if (activeBlockerDeckId == deck.id) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('active_test_deck_id');
              }
              _loadDecks();
            },
            child: const Text('Vymazať'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckCard(Deck deck) {
      final isExpanded = expandedDeckId == deck.id;
      final bool isCustom = deck.isPremade == 0 || deck.isPremade == false;
      final themeProvider = Provider.of<ThemeProvider>(context);
      final currentTheme = themeProvider.currentThemeData;
      final theme = currentTheme.theme;
      final Color sectionColor = _decksAccentColor;

      return FutureBuilder<int>(
        future: DatabaseHelper.instance.getCardCountForDeck(deck.id!),
        builder: (context, snapshot) {
          final cardCount = snapshot.data ?? 0;
          final bool hasEnoughCards = cardCount >= 5;
          final bool isActive = (activeBlockerDeckId == deck.id) && hasEnoughCards;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: _getCardDecoration(currentTheme, sectionColor, isActive: isActive),
            child: ClipRRect(
              borderRadius: currentTheme.cardBorderRadius,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: currentTheme.id == 2 ? sectionColor : sectionColor.withValues(alpha: 0.15),
                      child: Icon(Icons.style, color: currentTheme.id == 2 ? Colors.black : sectionColor),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            deck.name, 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ), 
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676), 
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AKTÍVNY', 
                              style: TextStyle(
                                color: Colors.black, 
                                fontSize: 10, 
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                    subtitle: Text(
                      "${deck.category} • Karty: $cardCount",
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!hasEnoughCards) ...[
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: sectionColor,
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        expandedDeckId = isExpanded ? null : deck.id;
                      });
                    },
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      width: double.infinity,
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Column(
                        children: [
                          Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionButton(
                                icon: isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                                label: isActive ? "Aktívny" : "Zvoliť",
                                color: isActive ? const Color(0xFF00E676) : theme.colorScheme.onSurface,
                                onTap: () async {
                                  if (!hasEnoughCards) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Na blokovanie musíte mať aspoň 5 kariet.")),
                                    );
                                    return;
                                  }
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setInt('active_test_deck_id', deck.id!);
                                  setState(() => activeBlockerDeckId = deck.id);
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.style,
                                label: "View",
                                color: Colors.orange.shade800,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck, isReadOnly: true)),
                                ).then((_) => _loadDecks()),
                              ),
                              Opacity(
                                opacity: hasEnoughCards ? 1.0 : 0.4,
                                child: _buildActionButton(
                                  icon: Icons.quiz,
                                  label: "Test",
                                  color: sectionColor,
                                  onTap: hasEnoughCards ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => QuizOverlayScreen(practiceDeckId: deck.id)),
                                  ) : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Na spustenie testu musíte mať aspoň 5 kariet.")),
                                    );
                                  },
                                ),
                              ),
                              _buildActionButton(
                                icon: Icons.share,
                                label: "Share",
                                color: Colors.blueAccent,
                                onTap: () async {
                                  final cards = await DatabaseHelper.instance.getCardsForDeck(deck.id!);

                                  final mapData = {
                                    'title': deck.name,
                                    'category': deck.category,
                                    'cards': cards.map((c) => {
                                      'q': c['question'] ?? c['front'] ?? c['prompt'] ?? '',
                                      'a': c['answer'] ?? c['back'] ?? c['correct_answer'] ?? '',
                                    }).toList(),
                                  };

                                  String jsonString = jsonEncode(mapData);
                                  String base64Data = base64Url.encode(utf8.encode(jsonString));

                                  final String shareLink = 'brainlock://share?data=$base64Data';
                                  final String message = 'Poď sa učiť balíček "${deck.name}" v Brainlocku! Klikni pre import: $shareLink';

                                  Share.share(message);
                                },
                              ),
                            ],
                          ),
                          if (isCustom) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.add_circle_outline_outlined,
                                  label: "Edit Cards",
                                  color: Colors.pink,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck)),
                                  ).then((_) => _loadDecks()),
                                ),
                                _buildActionButton(
                                  icon: Icons.edit,
                                  label: "Rename",
                                  color: Colors.orangeAccent,
                                  onTap: () => _showRenameDeckDialog(deck),
                                ),
                                _buildActionButton(
                                  icon: Icons.delete,
                                  label: "Delete",
                                  color: Colors.redAccent,
                                  onTap: () => _showDeleteConfirmDialog(deck),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

  Widget _buildCustomDeckList(List<Deck> deckList) {
    final theme = Theme.of(context);
    if (deckList.isEmpty) {
      return Center(
        child: Text(
          "Nenašli sa žiadne vlastné balíčky. Skús nejaký vytvoriť!",
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }
    return ListView.builder(
      itemCount: deckList.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) => _buildDeckCard(deckList[index]),
    );
  }

  Widget _buildGroupedPremadeDeckList(List<Deck> deckList) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = _decksAccentColor;

    if (deckList.isEmpty) {
      return Center(
        child: Text(
          "Žiadne predpripravené balíčky.",
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }

    final Map<String, List<Deck>> groupedDecks = {};
    for (var deck in deckList) {
      groupedDecks.putIfAbsent(deck.category, () => []).add(deck);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      children: groupedDecks.entries.map((entry) {
        final categoryName = entry.key;
        final categoryDecks = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: _getCardDecoration(currentTheme, sectionColor),
          child: ClipRRect(
            borderRadius: currentTheme.cardBorderRadius,
            child: ExpansionTile(
              leading: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Icon(_getCategoryIcon(categoryName), color: sectionColor, size: 28),
                ),
              ),
              iconColor: sectionColor,
              collapsedIconColor: sectionColor,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                categoryName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: sectionColor),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _getCategoryDescription(categoryName),
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: categoryDecks.map((deck) => _buildDeckCard(deck)).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = _decksAccentColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Brainlock Decks'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: theme.appBarTheme.elevation ?? 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: sectionColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: sectionColor,
          tabs: const [
            Tab(text: 'My decks', icon: Icon(Icons.person)),
            Tab(text: 'Premade decks', icon: Icon(Icons.library_books)),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: sectionColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCustomDeckList(myDecks), 
                _buildGroupedPremadeDeckList(premadeDecks),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showAddDeckDialog,
              // 6. KĽÚČOVÁ ZMENA: Ak máš Premium, tlačidlo je vždy prístupné (+) a vo farbe
              backgroundColor: currentTheme.id == 2 ? Colors.black : ((myDecks.length >= 3 && !isPremium) ? Colors.amber : sectionColor),
              foregroundColor: currentTheme.id == 2 ? Colors.white : (sectionColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: currentTheme.cardBorderRadius,
                side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 2.5) : BorderSide.none,
              ),
              child: Icon((myDecks.length >= 3 && !isPremium) ? Icons.block : Icons.add),
            )
          : null,
    );
  }
}