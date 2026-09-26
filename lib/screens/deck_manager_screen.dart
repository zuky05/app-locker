import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../models/deck_model.dart';
import '../themes/app_themes.dart';
import '../themes/theme_provider.dart';
import 'deck_detail_screen.dart';
import 'create_deck_screen.dart';
import 'quiz_overlay_screen.dart';
import '../services/anki_importer.dart';
import '../services/revenuecat_service.dart';
import '../themes/themed_background.dart';
import '../services/csv_service.dart';
import '../services/locale_provider.dart';

class DeckManagerScreen extends StatefulWidget {
  const DeckManagerScreen({super.key});

  @override
  State<DeckManagerScreen> createState() => _DeckManagerScreenState();
}

class _DeckManagerScreenState extends State<DeckManagerScreen> with SingleTickerProviderStateMixin {
  List<Deck> myDecks = [];
  List<Deck> premadeDecks = [];
  bool isLoading = true;
  bool isPremium = false;
  
  int? expandedDeckId;
  int? activeBlockerDeckId;

  late TabController _tabController;

  static const Color _softCardBg = Color(0xFFF8FAFC);

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
      final bool exists = loadedDecks.any((d) => d.id == activeId);
      final int activeCardCount = exists ? await DatabaseHelper.instance.getCardCountForDeck(activeId) : 0;

      if (!exists || activeCardCount < 5) {
        await prefs.remove('active_test_deck_id');
        activeId = null;
      }
    }

    if (activeId == null && loadedDecks.isNotEmpty) {
      Deck? defaultDeck;

      for (var d in loadedDecks) {
        final nameLower = d.name.toLowerCase();
        if (nameLower.contains('capital') || nameLower.contains('hlavné mestá') || nameLower.contains('world capitals')) {
          final count = await DatabaseHelper.instance.getCardCountForDeck(d.id!);
          if (count >= 5) {
            defaultDeck = d;
            break;
          }
        }
      }

      if (defaultDeck == null) {
        for (var d in loadedDecks) {
          if (d.isPremade) {
            final count = await DatabaseHelper.instance.getCardCountForDeck(d.id!);
            if (count >= 5) {
              defaultDeck = d;
              break;
            }
          }
        }
      }

      if (defaultDeck != null) {
        await prefs.setInt('active_test_deck_id', defaultDeck.id!);
        activeId = defaultDeck.id;
      }
    }
    
    final premiumStatus = await RevenueCatService.isPremium();
    if (!mounted) return;

    setState(() {
      myDecks = loadedDecks.where((d) => !d.isPremade).toList();
      premadeDecks = loadedDecks.where((d) => d.isPremade).toList();
      activeBlockerDeckId = activeId;
      isPremium = premiumStatus;
      isLoading = false;
    });
  }

  // 🟢 DYNAMICKÝ POPIS KATEGÓRIÍ PODĽA ZVOLENÉHO JAZYKA
  String _getCategoryDescription(String category, bool isEn) {
    final cleanCategory = category.toLowerCase().trim();
    if (cleanCategory.contains('geography') || cleanCategory.contains('geografia')) {
      return isEn
          ? 'Test your knowledge of capitals, flags, and world geography.'
          : 'Otestuj svoje znalosti hlavných miest, vlajok a geografie sveta.';
    }
    if (cleanCategory.contains('language') || cleanCategory.contains('jazyk')) {
      return isEn
          ? 'Expand your vocabulary in the most spoken world languages.'
          : 'Rozšír si slovnú zásobu v najpoužívanejších svetových jazykoch.';
    }
    if (cleanCategory.contains('tech') || cleanCategory.contains('it') || cleanCategory.contains('computer') || cleanCategory.contains('informa')) {
      return isEn
          ? 'Master HTTP status codes, Linux commands, and developer concepts.'
          : 'Ovládni HTTP status kódy, Linux príkazy a základné vývojárske koncepty.';
    }
    return isEn
        ? 'Ready-to-use card collections for fast learning.'
        : 'Pripravené kolekcie kartičiek pre rýchle učenie.';
  }

  Future<void> _handleAnkiImport() async {
    final String? result = await AnkiImporter.importApkgDirect();
    if (result == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    await _loadDecks();
  }

  IconData _getCategoryIcon(String category) {
    final cleanCategory = category.trim().toLowerCase();
    if (cleanCategory.contains('geography') || cleanCategory.contains('geografia')) return Icons.public;
    if (cleanCategory.contains('language') || cleanCategory.contains('jazyk')) return Icons.translate;
    if (cleanCategory.contains('tech') || cleanCategory.contains('it') || cleanCategory.contains('computer') || cleanCategory.contains('informa')) return Icons.terminal;
    return Icons.folder_special;
  }

  Widget _buildDialogButton({
    required String label,
    required Color accentColor,
    required AppThemeData currentTheme,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;
    final theme = currentTheme.theme;

    BoxDecoration decoration;
    Color textColor;

    if (isSoft) {
      if (isSecondary) {
        decoration = BoxDecoration(
          color: _softCardBg,
          borderRadius: currentTheme.buttonBorderRadius,
          boxShadow: const [
            BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(3, 3), blurRadius: 6),
            BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
          ],
        );
        textColor = const Color(0xFF2D3748);
      } else {
        decoration = BoxDecoration(
          color: accentColor,
          borderRadius: currentTheme.buttonBorderRadius,
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha: 0.45), offset: const Offset(4, 4), blurRadius: 10),
            BoxShadow(color: Colors.white.withValues(alpha: 0.5), offset: const Offset(-2, -2), blurRadius: 6),
          ],
        );
        textColor = Colors.white;
      }
    } else if (isSecondary) {
      if (isVibrant) {
        decoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF64748B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
        );
        textColor = Colors.white;
      } else if (isCyber) {
        decoration = BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF00F5FF).withValues(alpha: 0.5), width: 1.0),
        );
        textColor = Colors.white;
      } else if (isNeo) {
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(color: Colors.black, width: 3.5),
        );
        textColor = Colors.black;
      } else {
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.cardColor, theme.scaffoldBackgroundColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), width: 1.5),
        );
        textColor = theme.colorScheme.onSurface;
      }
    } else {
      decoration = isNeo
          ? BoxDecoration(
              color: accentColor,
              borderRadius: currentTheme.buttonBorderRadius,
              border: Border.all(color: Colors.black, width: 3.5),
            )
          : currentTheme.getCardDecoration(accentColor);
      textColor = isNeo ? Colors.black : currentTheme.getContrastTextColor(accentColor);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: currentTheme.buttonBorderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: decoration,
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDeckDialog() async {
    final t = context.read<LocaleProvider>().t;
    final int customCount = await DatabaseHelper.instance.getCustomDeckCount();
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;
    final Color sectionColor = currentTheme.testSetupColor;

    final dialogBgColor = isNeo 
        ? Colors.white 
        : (isSoft 
            ? _softCardBg 
            : (isCyber 
                ? Colors.black.withValues(alpha: 0.92) 
                : (isVibrant ? const Color(0xFF0F172A) : theme.cardColor)));

    final dialogTextColor = isNeo 
        ? Colors.black 
        : (isSoft 
            ? const Color(0xFF2D3748) 
            : (isVibrant || isCyber ? Colors.white : theme.colorScheme.onSurface));

    if (customCount >= 3 && !isPremium) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: currentTheme.cardBorderRadius,
            side: isNeo ? const BorderSide(color: Colors.black, width: 3.5) : (isCyber ? const BorderSide(color: Color(0xFF00F5FF), width: 1.5) : currentTheme.buttonBorder),
          ),
          title: Column(
            children: [
              Icon(Icons.star_rounded, size: 50, color: isNeo ? Colors.black : currentTheme.warningColor),
              const SizedBox(height: 10),
              Text(
                t.premiumLimitTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold, color: dialogTextColor),
              ),
            ],
          ),
          content: Text(
            t.premiumLimitCustomDecks,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: isNeo ? FontWeight.bold : FontWeight.normal, color: isNeo ? Colors.black87 : dialogTextColor.withValues(alpha: 0.8)),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            _buildDialogButton(
              label: t.buttonCancel,
              accentColor: currentTheme.errorColor,
              currentTheme: currentTheme,
              isSecondary: true,
              onTap: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(width: 8),
            _buildDialogButton(
              label: t.buttonUnlockPremium,
              accentColor: currentTheme.warningColor,
              currentTheme: currentTheme,
              onTap: () async {
                Navigator.pop(dialogContext);
                final success = await RevenueCatService.presentPaywall();
                if (success) {
                  await _loadDecks();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.premiumSuccessToast), 
                      backgroundColor: currentTheme.successColor,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;

    Widget buildOptionButton({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      BoxDecoration decoration;
      Color textColor;
      Color iconColor;

      if (isSoft) {
        decoration = BoxDecoration(
          color: _softCardBg,
          borderRadius: currentTheme.buttonBorderRadius,
          boxShadow: const [
            BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(4, 4), blurRadius: 10),
            BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 8),
          ],
        );
        textColor = const Color(0xFF2D3748);
        iconColor = sectionColor;
      } else if (isNeo) {
        decoration = BoxDecoration(
          color: sectionColor,
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(color: Colors.black, width: 3.5),
        );
        textColor = Colors.black;
        iconColor = Colors.black;
      } else if (isCyber) {
        decoration = BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF00F5FF).withValues(alpha: 0.6), width: 1.0),
        );
        textColor = const Color(0xFF00F5FF);
        iconColor = const Color(0xFF00F5FF);
      } else {
        decoration = currentTheme.getCardDecoration(sectionColor);
        textColor = isVibrant ? Colors.white : currentTheme.getContrastTextColor(sectionColor);
        iconColor = isVibrant ? Colors.white : currentTheme.getIconColor(sectionColor);
      }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: currentTheme.buttonBorderRadius,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: decoration,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: isNeo ? const BorderSide(color: Colors.black, width: 3.5) : (isCyber ? const BorderSide(color: Color(0xFF00F5FF), width: 1.5) : currentTheme.buttonBorder),
        ),
        title: Text(
          t.addDeckDialogTitle, 
          textAlign: TextAlign.center, 
          style: TextStyle(fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold, color: dialogTextColor, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildOptionButton(
              icon: Icons.add_circle_outline,
              label: t.optionCustomDeck,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateDeckScreen()),
                ).then((_) => _loadDecks());
              },
            ),
            const SizedBox(height: 10),
            buildOptionButton(
              icon: Icons.description_rounded,
              label: t.optionCsvImport,
              onTap: () async {
                Navigator.pop(context);
                final result = await CsvService.importDeckFromCsv();
                
                if (result != null && mounted) {
                  await _loadDecks();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result)),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            buildOptionButton(
              icon: Icons.upload_file,
              label: t.optionAnkiImport,
              onTap: () async {
                Navigator.pop(context);
                await _handleAnkiImport();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDeckDialog(Deck deck) {
    final t = context.read<LocaleProvider>().t;
    final nameController = TextEditingController(text: deck.name);
    final categoryController = TextEditingController(text: deck.category);
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = currentTheme.testSetupColor;
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;

    final dialogBgColor = isNeo 
        ? Colors.white 
        : (isSoft 
            ? _softCardBg 
            : (isCyber 
                ? Colors.black.withValues(alpha: 0.92) 
                : (isVibrant ? const Color(0xFF0F172A) : theme.cardColor)));

    final dialogTextColor = isNeo 
        ? Colors.black 
        : (isSoft 
            ? const Color(0xFF2D3748) 
            : (isVibrant || isCyber ? Colors.white : theme.colorScheme.onSurface));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: isNeo ? const BorderSide(color: Colors.black, width: 3.5) : (isCyber ? const BorderSide(color: Color(0xFF00F5FF), width: 1.5) : currentTheme.buttonBorder),
        ),
        title: Text(
          t.renameDeckTitle, 
          style: TextStyle(color: dialogTextColor, fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController, 
              style: TextStyle(color: dialogTextColor, fontWeight: isNeo ? FontWeight.w900 : FontWeight.normal),
              decoration: InputDecoration(
                labelText: t.fieldDeckName,
                labelStyle: TextStyle(color: dialogTextColor.withValues(alpha: 0.6)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: isCyber ? const Color(0xFF00F5FF) : sectionColor, width: 2)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController, 
              style: TextStyle(color: dialogTextColor, fontWeight: isNeo ? FontWeight.w900 : FontWeight.normal),
              decoration: InputDecoration(
                labelText: t.fieldCategory,
                labelStyle: TextStyle(color: dialogTextColor.withValues(alpha: 0.6)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: isCyber ? const Color(0xFF00F5FF) : sectionColor, width: 2)),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          _buildDialogButton(
            label: t.buttonCancel,
            accentColor: currentTheme.errorColor,
            currentTheme: currentTheme,
            isSecondary: true,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          _buildDialogButton(
            label: t.btnSave,
            accentColor: sectionColor,
            currentTheme: currentTheme,
            onTap: () async {
              if (nameController.text.isNotEmpty && categoryController.text.isNotEmpty) {
                Navigator.pop(context);
                await DatabaseHelper.instance.updateDeck(deck.id!, nameController.text, categoryController.text);
                await _loadDecks();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Deck deck) {
    final t = context.read<LocaleProvider>().t;
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;

    final dialogBgColor = isNeo 
        ? Colors.white 
        : (isSoft 
            ? _softCardBg 
            : (isCyber 
                ? Colors.black.withValues(alpha: 0.92) 
                : (isVibrant ? const Color(0xFF0F172A) : theme.cardColor)));

    final dialogTextColor = isNeo 
        ? Colors.black 
        : (isSoft 
            ? const Color(0xFF2D3748) 
            : (isVibrant || isCyber ? Colors.white : theme.colorScheme.onSurface));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: isNeo ? const BorderSide(color: Colors.black, width: 3.5) : (isCyber ? const BorderSide(color: Color(0xFF00F5FF), width: 1.5) : currentTheme.buttonBorder),
        ),
        title: Text(t.deleteDeckTitle, style: TextStyle(color: dialogTextColor, fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold)),
        content: Text(
          t.deleteDeckContent(deck.name),
          style: TextStyle(color: isNeo ? Colors.black87 : dialogTextColor.withValues(alpha: 0.8), fontWeight: isNeo ? FontWeight.bold : FontWeight.normal),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          _buildDialogButton(
            label: t.buttonCancel,
            accentColor: currentTheme.errorColor,
            currentTheme: currentTheme,
            isSecondary: true,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          _buildDialogButton(
            label: t.btnDeleteAction,
            accentColor: currentTheme.errorColor,
            currentTheme: currentTheme,
            onTap: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.removeDeck(deck.id!);
              
              if (activeBlockerDeckId == deck.id) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('active_test_deck_id');
              }
              await _loadDecks();
            },
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentTheme = themeProvider.currentThemeData;
    final theme = Theme.of(context);
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;

    BoxDecoration? btnDecoration;
    if (isSoft) {
      btnDecoration = BoxDecoration(
        color: _softCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFCBD5E1),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      );
    }

    final Color effectiveColor = isCyber 
        ? (color == currentTheme.errorColor ? const Color(0xFFFF3344) : const Color(0xFF00F5FF))
        : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: btnDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                color: isNeo 
                    ? Colors.black 
                    : (isSoft ? effectiveColor : (isCyber ? effectiveColor : (isVibrant && color == theme.colorScheme.onSurface ? Colors.white : effectiveColor))), 
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold, 
                  color: isNeo 
                      ? Colors.black 
                      : (isSoft ? const Color(0xFF2D3748) : (isCyber ? Colors.white.withValues(alpha: 0.9) : (isVibrant ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.9)))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckCard(Deck deck) {
    final t = context.watch<LocaleProvider>().t;
    final isExpanded = expandedDeckId == deck.id;
    final bool isCustom = !deck.isPremade;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = currentTheme.testSetupColor;
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;

    return FutureBuilder<int>(
      future: DatabaseHelper.instance.getCardCountForDeck(deck.id!),
      builder: (context, snapshot) {
        final cardCount = snapshot.data ?? 0;
        final bool hasEnoughCards = cardCount >= 5;
        final bool isActive = (activeBlockerDeckId == deck.id) && hasEnoughCards;

        final cardDecoration = isCyber
            ? BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: currentTheme.cardBorderRadius,
                border: Border.all(
                  color: isActive 
                      ? const Color(0xFF00FF66) 
                      : const Color(0xFF00F5FF).withValues(alpha: 0.35),
                  width: isActive ? 1.5 : 1.0,
                ),
              )
            : currentTheme.getCardDecoration(sectionColor, isSelected: isActive);

        final Color tileBgColor = currentTheme.getTileBg(isGranted: false, accentColor: sectionColor);
        final Color avatarBg = isNeo 
            ? Colors.white 
            : (isCyber 
                ? Colors.black.withValues(alpha: 0.5) 
                : (isVibrant ? Colors.white.withValues(alpha: 0.2) : tileBgColor));
        
        final Color avatarIconColor = isNeo 
            ? Colors.black 
            : (isCyber 
                ? const Color(0xFF00F5FF) 
                : (isVibrant ? Colors.white : currentTheme.getContrastTextColor(tileBgColor)));

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: cardDecoration,
          child: ClipRRect(
            borderRadius: currentTheme.cardBorderRadius,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: isSoft
                        ? BoxDecoration(
                            color: const Color(0xFFEBF0F5),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(2, 2), blurRadius: 4),
                              BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                            ],
                          )
                        : null,
                    child: CircleAvatar(
                      backgroundColor: isSoft ? Colors.transparent : avatarBg,
                      child: Icon(_getCategoryIcon(deck.category), size: 20, color: isSoft ? sectionColor : avatarIconColor),
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          deck.getLocalizedName(context), 
                          style: TextStyle(
                            fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
                            fontSize: 16,
                            color: isNeo ? Colors.black : (isSoft ? const Color(0xFF2D3748) : (isCyber || isVibrant ? Colors.white : theme.colorScheme.onSurface)),
                          ), 
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: isSoft
                              ? BoxDecoration(
                                  color: const Color(0xFFEBF0F5),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(2, 2), blurRadius: 4),
                                    BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                                  ],
                                )
                              : (isCyber 
                                  ? BoxDecoration(
                                      color: const Color(0xFF00FF66).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(color: const Color(0xFF00FF66), width: 1.0),
                                    )
                                  : BoxDecoration(
                                      color: currentTheme.successColor, 
                                      borderRadius: BorderRadius.circular(4),
                                      border: isNeo ? Border.all(color: Colors.black, width: 2.0) : Border.fromBorderSide(currentTheme.buttonBorder),
                                    )),
                          child: Text(
                            t.activeBadge, 
                            style: TextStyle(
                              color: isSoft ? currentTheme.successColor : (isCyber ? const Color(0xFF00FF66) : (isNeo ? Colors.black : currentTheme.getContrastTextColor(currentTheme.successColor))), 
                              fontSize: 10, 
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      ]
                    ],
                  ),
                  subtitle: Text(
                    "${deck.getLocalizedCategory(context)} • ${context.read<LocaleProvider>().locale == 'en' ? 'Cards' : 'Karty'}: $cardCount",
                    style: TextStyle(
                      fontWeight: isNeo ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                      color: isNeo ? Colors.black87 : (isSoft ? const Color(0xFF718096) : (isCyber ? Colors.white60 : (isVibrant ? Colors.white.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.7)))),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!hasEnoughCards) ...[
                        Icon(Icons.warning_amber_rounded, color: isNeo ? Colors.black : currentTheme.warningColor, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isNeo ? Colors.black : (isSoft ? const Color(0xFF718096) : (isCyber ? const Color(0xFF00F5FF) : (isVibrant ? Colors.white : currentTheme.getIconColor(sectionColor)))),
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
                    decoration: BoxDecoration(
                      color: isNeo ? Colors.black.withValues(alpha: 0.05) : (isVibrant ? Colors.white.withValues(alpha: 0.15) : (isCyber ? Colors.black.withValues(alpha: 0.4) : Colors.transparent)),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      border: isNeo || isVibrant ? Border(top: BorderSide(color: isNeo ? Colors.black : (isVibrant ? Colors.white.withValues(alpha: 0.3) : currentTheme.buttonBorder.color), width: isNeo ? 3.5 : 2.0)) : (isCyber ? Border(top: BorderSide(color: const Color(0xFF00F5FF).withValues(alpha: 0.2), width: 1.0)) : null),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Column(
                      children: [
                        if (!isNeo && !isVibrant && !isSoft && !isCyber) ...[
                          Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              icon: isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                              label: isActive ? t.btnActive : t.btnSelect,
                              color: isNeo ? Colors.black : (isActive ? currentTheme.successColor : (isSoft ? const Color(0xFF2D3748) : theme.colorScheme.onSurface)),
                              onTap: () async {
                                if (!hasEnoughCards) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.errorMinCardsBlock)),
                                  );
                                  return;
                                }
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setInt('active_test_deck_id', deck.id);
                                setState(() => activeBlockerDeckId = deck.id);
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.style,
                              label: t.btnView,
                              color: isNeo ? Colors.black : currentTheme.blockedAppsColor,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck, isReadOnly: true)),
                              ).then((_) => _loadDecks()),
                            ),
                            Opacity(
                              opacity: hasEnoughCards ? 1.0 : 0.4,
                              child: _buildActionButton(
                                icon: Icons.quiz,
                                label: t.btnTest,
                                color: isNeo ? Colors.black : currentTheme.decksColor,
                                onTap: hasEnoughCards ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => QuizOverlayScreen(practiceDeckId: deck.id)),
                                ) : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.errorMinCardsTest)),
                                  );
                                },
                              ),
                            ),
                            _buildActionButton(
                              icon: Icons.share,
                              label: t.btnShare,
                              color: isNeo ? Colors.black : currentTheme.decksColor,
                              onTap: () async {
                                final currentLocale = context.read<LocaleProvider>().locale;
                                final cards = await DatabaseHelper.instance.getCardsForDeck(deck.id);
                                final isEn = currentLocale == 'en';

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

                                final String shareLink = 'flashpass://share?data=$base64Data';
                                final String message = isEn
                                    ? 'Come learn the deck "${deck.getLocalizedName(context)}" on FlashPass! Click to import: $shareLink'
                                    : 'Poď sa učiť balíček "${deck.getLocalizedName(context)}" vo FlashPasse! Klikni pre import: $shareLink';

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
                                label: t.btnEditCards,
                                color: isNeo ? Colors.black : currentTheme.dailyGoalColor,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck)),
                                ).then((_) => _loadDecks()),
                              ),
                              _buildActionButton(
                                icon: Icons.edit,
                                label: t.btnRename,
                                color: isNeo ? Colors.black : currentTheme.warningColor,
                                onTap: () => _showRenameDeckDialog(deck),
                              ),
                              _buildActionButton(
                                icon: Icons.delete,
                                label: t.btnDelete,
                                color: isNeo ? Colors.black : currentTheme.errorColor,
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
    final t = context.watch<LocaleProvider>().t;
    final theme = Theme.of(context);
    final currentTheme = Provider.of<ThemeProvider>(context).currentThemeData;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;

    if (deckList.isEmpty) {
      return Center(
        child: Text(
          t.emptyMyDecks,
          style: TextStyle(
            fontWeight: isNeo ? FontWeight.w900 : FontWeight.normal,
            color: isNeo ? Colors.black : (isSoft ? const Color(0xFF718096) : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: deckList.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemBuilder: (context, index) => _buildDeckCard(deckList[index]),
    );
  }

  Widget _buildGroupedPremadeDeckList(List<Deck> deckList) {
    final t = context.watch<LocaleProvider>().t;
    final isEn = context.watch<LocaleProvider>().locale == 'en';
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = currentTheme.testSetupColor;
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;

    if (deckList.isEmpty) {
      return Center(
        child: Text(
          t.emptyPremadeDecks,
          style: TextStyle(
            fontWeight: isNeo ? FontWeight.w900 : FontWeight.normal,
            color: isNeo ? Colors.black : (isSoft ? const Color(0xFF718096) : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    final Map<String, List<Deck>> groupedDecks = {};
    for (var deck in deckList) {
      groupedDecks.putIfAbsent(deck.getLocalizedCategory(context), () => []).add(deck);
    }

    // 🟢 Zoradenie kategórií: Informatika / Technology bude VŽDY úplne na spodku
    final categories = groupedDecks.keys.toList();
    categories.sort((a, b) {
      final aClean = a.toLowerCase();
      final bClean = b.toLowerCase();
      final aIsTech = aClean.contains('informa') || aClean.contains('tech') || aClean.contains('computer');
      final bIsTech = bClean.contains('informa') || bClean.contains('tech') || bClean.contains('computer');

      if (aIsTech && !bIsTech) return 1;
      if (!aIsTech && bIsTech) return -1;
      return a.compareTo(b);
    });

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      children: categories.map((categoryName) {
        final categoryDecks = groupedDecks[categoryName]!;

        final cardDeco = isCyber
            ? BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: currentTheme.cardBorderRadius,
                border: Border.all(
                  color: const Color(0xFF00F5FF).withValues(alpha: 0.4),
                  width: 1.0,
                ),
              )
            : currentTheme.getCardDecoration(sectionColor);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: cardDeco,
          child: ClipRRect(
            borderRadius: currentTheme.cardBorderRadius,
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              leading: Container(
                width: 36,
                height: 36,
                decoration: isSoft
                    ? BoxDecoration(
                        color: const Color(0xFFEBF0F5),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(2, 2), blurRadius: 4),
                          BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                        ],
                      )
                    : null,
                child: Center(
                  child: Icon(
                    _getCategoryIcon(categoryName), 
                    color: isNeo ? Colors.black : (isSoft ? sectionColor : (isCyber ? const Color(0xFF00F5FF) : (isVibrant ? Colors.white : currentTheme.getIconColor(sectionColor)))), 
                    size: 22,
                  ),
                ),
              ),
              iconColor: isNeo ? Colors.black : (isSoft ? const Color(0xFF718096) : (isCyber ? const Color(0xFF00F5FF) : (isVibrant ? Colors.white : sectionColor))),
              collapsedIconColor: isNeo ? Colors.black : (isSoft ? const Color(0xFF718096) : (isCyber ? const Color(0xFF00F5FF) : (isVibrant ? Colors.white : sectionColor))),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(
                categoryName,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: isNeo ? Colors.black : (isSoft ? const Color(0xFF2D3748) : (isCyber ? Colors.white : (isVibrant ? Colors.white : sectionColor))),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _getCategoryDescription(categoryName, isEn),
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: isNeo ? FontWeight.bold : FontWeight.normal,
                    color: isNeo ? Colors.black87 : (isSoft ? const Color(0xFF718096) : (isCyber ? Colors.white70 : (isVibrant ? Colors.white.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.7)))),
                  ),
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
    final t = context.watch<LocaleProvider>().t;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final Color sectionColor = currentTheme.testSetupColor;
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;

    final bool isLimitReached = (myDecks.length >= 3 && !isPremium);
    final Color fabBgColor = isLimitReached ? currentTheme.warningColor : sectionColor;

    final tabDecoration = isSoft
        ? BoxDecoration(
            color: const Color(0xFFEBF0F5),
            borderRadius: currentTheme.buttonBorderRadius,
            boxShadow: const [
              BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(3, 3), blurRadius: 6),
              BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
            ],
          )
        : (isNeo
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: currentTheme.buttonBorderRadius,
                border: Border.all(color: Colors.black, width: 3.5),
              )
            : (isCyber 
                ? BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF00F5FF).withValues(alpha: 0.3), width: 1.0),
                  )
                : BoxDecoration(
                    color: isVibrant 
                        ? Colors.black.withValues(alpha: 0.06) 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: currentTheme.buttonBorderRadius,
                  )));

    final tabIndicator = isSoft
        ? BoxDecoration(
            color: _softCardBg,
            borderRadius: currentTheme.buttonBorderRadius,
            boxShadow: const [
              BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(3, 3), blurRadius: 6),
              BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
            ],
          )
        : (isNeo
            ? BoxDecoration(
                color: sectionColor,
                borderRadius: currentTheme.buttonBorderRadius,
                border: Border.all(color: Colors.black, width: 2.5),
              )
            : (isCyber 
                ? BoxDecoration(
                    color: const Color(0xFF00F5FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF00F5FF), width: 1.0),
                  )
                : currentTheme.getCardDecoration(sectionColor)));

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            t.deckManagerTitle,
            style: TextStyle(
              fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
              color: isNeo ? Colors.black : theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: isNeo ? Colors.black : theme.colorScheme.onSurface,
          elevation: theme.appBarTheme.elevation ?? 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: tabDecoration,
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: tabIndicator,
                  labelColor: isSoft 
                      ? sectionColor 
                      : (isCyber ? const Color(0xFF00F5FF) : (isNeo ? Colors.black : (isVibrant ? Colors.white : currentTheme.getContrastTextColor(sectionColor)))),
                  unselectedLabelColor: isSoft 
                      ? const Color(0xFF718096) 
                      : (isCyber ? Colors.white60 : (isNeo ? Colors.black54 : (isVibrant ? const Color(0xFF334155) : theme.colorScheme.onSurface.withValues(alpha: 0.7)))),
                  labelStyle: TextStyle(fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: TextStyle(fontWeight: isNeo ? FontWeight.bold : FontWeight.w600, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(t.tabMyDecks),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.library_books_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(t.tabPremadeDecks),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showAddDeckDialog,
                  borderRadius: currentTheme.buttonBorderRadius,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: isSoft
                        ? BoxDecoration(
                            color: _softCardBg,
                            borderRadius: currentTheme.buttonBorderRadius,
                            boxShadow: const [
                              BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(4, 4), blurRadius: 8),
                              BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
                            ],
                          )
                        : (isNeo
                            ? BoxDecoration(
                                color: fabBgColor,
                                borderRadius: currentTheme.buttonBorderRadius,
                                border: Border.all(color: Colors.black, width: 3.5),
                              )
                            : (isCyber 
                                ? BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF00F5FF), width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x5900F5FF),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  )
                                : currentTheme.getCardDecoration(fabBgColor))),
                    child: Icon(
                      isLimitReached ? Icons.block : Icons.add,
                      color: isSoft ? sectionColor : (isCyber ? const Color(0xFF00F5FF) : (isNeo ? Colors.black : (isVibrant ? Colors.white : currentTheme.getContrastTextColor(fabBgColor)))),
                      size: 26,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}