import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck_model.dart';
import '../services/database_helper.dart';
import '../themes/app_themes.dart';
import '../themes/theme_provider.dart';
import '../themes/themed_background.dart';
import '../services/locale_provider.dart';
import 'deck_detail_screen.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _deckNameController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _deckNameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _deckNameController.text.trim().isNotEmpty && 
           _categoryController.text.trim().isNotEmpty;
  }

  Future<Deck?> _createDeckInDb() async {
    final String deckName = _deckNameController.text.trim();
    final String category = _categoryController.text.trim();

    if (!_isFormValid) return null;

    final int deckId = await DatabaseHelper.instance.addNewDeck(
      deckName, 
      category,
    );

    return Deck(
      id: deckId,
      name: deckName,
      category: category,
      isPremade: false,
    );
  }

  void _saveDeckOnly() async {
    final newDeck = await _createDeckInDb();
    if (newDeck != null && mounted) {
      Navigator.pop(context);
    }
  }

  void _saveAndAddCards() async {
    final newDeck = await _createDeckInDb();
    if (newDeck != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: newDeck)),
      );
    }
  }

  // 🟢 KONTRASTNÉ, 3D NEUMORFNÉ A CYBERPUNK TLAČIDLÁ
  Widget _buildThemeButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required AppThemeData currentTheme,
    required bool isEnabled,
  }) {
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;

    BoxDecoration decoration;
    Color textColor;
    Color iconColor;

    if (isSoft) {
      if (isEnabled) {
        decoration = BoxDecoration(
          color: const Color(0xFFD1D9E6),
          borderRadius: currentTheme.buttonBorderRadius,
          boxShadow: const [
            BoxShadow(color: Color(0xFF97A7C0), offset: Offset(4, 4), blurRadius: 8),
            BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
          ],
        );
        textColor = const Color(0xFF2D3748);
        iconColor = currentTheme.decksColor;
      } else {
        decoration = BoxDecoration(
          color: const Color(0xFFC8D3E6),
          borderRadius: currentTheme.buttonBorderRadius,
          boxShadow: const [
            BoxShadow(color: Color(0xFF97A7C0), offset: Offset(1, 1), blurRadius: 3),
            BoxShadow(color: Colors.white, offset: Offset(-1, -1), blurRadius: 3),
          ],
        );
        textColor = const Color(0xFF97A7C0);
        iconColor = const Color(0xFF97A7C0);
      }
    } else if (isCyber) {
      final Color cyberCyan = isEnabled 
          ? const Color(0xFF00F5FF) 
          : const Color(0xFF00F5FF).withValues(alpha: 0.65);
          
      decoration = BoxDecoration(
        color: isEnabled 
            ? Colors.black.withValues(alpha: 0.85) 
            : const Color(0xFF00F5FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cyberCyan, width: 1.2),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: cyberCyan.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ] : null,
      );
      textColor = cyberCyan;
      iconColor = cyberCyan;
    } else {
      decoration = isNeo
          ? BoxDecoration(
              color: isEnabled ? currentTheme.decksColor : Colors.grey.shade300,
              borderRadius: currentTheme.buttonBorderRadius,
              border: Border.all(color: Colors.black, width: 3.5),
              boxShadow: isEnabled ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))] : null,
            )
          : currentTheme.getCardDecoration(isEnabled ? currentTheme.decksColor : Colors.grey);

      textColor = isNeo ? Colors.black : (isVibrant ? Colors.white : currentTheme.getContrastTextColor(currentTheme.decksColor));
      iconColor = isNeo ? Colors.black : (isVibrant ? Colors.white : currentTheme.getIconColor(currentTheme.decksColor));
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.85,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: isCyber ? BorderRadius.circular(4) : currentTheme.buttonBorderRadius,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: decoration,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  isCyber ? '// ${label.toUpperCase()}' : label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontFamily: isCyber ? 'monospace' : null,
                    fontWeight: isNeo || isCyber ? FontWeight.w900 : FontWeight.bold,
                    letterSpacing: isCyber ? 1.2 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;

    final BoxDecoration inputDecoration = isSoft
        ? BoxDecoration(
            color: const Color(0xFFC8D3E6),
            borderRadius: currentTheme.cardBorderRadius,
            boxShadow: const [
              BoxShadow(color: Color(0xFF97A7C0), offset: Offset(2, 2), blurRadius: 4),
              BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
            ],
          )
        : (isCyber
            ? BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF00F5FF).withValues(alpha: 0.4), width: 1.0),
              )
            : (isVibrant
                ? BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                    borderRadius: currentTheme.cardBorderRadius,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  )
                : BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: currentTheme.cardBorderRadius,
                    border: isNeo
                        ? Border.all(color: Colors.black, width: 3.5)
                        : Border.all(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                            width: 1.2,
                          ),
                  )));

    final Color inputTextColor = isSoft
        ? const Color(0xFF2D3748)
        : (isNeo ? Colors.black : (isVibrant || isCyber ? Colors.white : theme.colorScheme.onSurface));

    final Color labelTextColor = isSoft
        ? const Color(0xFF718096)
        : (isNeo ? Colors.black87 : (isCyber ? const Color(0xFF00F5FF).withValues(alpha: 0.7) : (isVibrant ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.6))));

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            t.createDeckTitle,
            style: TextStyle(
              fontWeight: isNeo || isCyber ? FontWeight.w900 : FontWeight.bold,
              fontFamily: isCyber ? 'monospace' : null,
              color: isNeo ? Colors.black : theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: isNeo ? Colors.black : theme.colorScheme.onSurface,
          elevation: theme.appBarTheme.elevation ?? 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. NÁZOV BALÍČKA
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: inputDecoration,
                child: TextField(
                  controller: _deckNameController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: inputTextColor,
                    fontFamily: isCyber ? 'monospace' : null,
                    fontWeight: isNeo || isCyber ? FontWeight.w900 : FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: isCyber ? t.createDeckNameHintCyber : t.createDeckNameHint,
                    labelStyle: TextStyle(
                      color: labelTextColor,
                      fontFamily: isCyber ? 'monospace' : null,
                      fontWeight: isNeo || isCyber ? FontWeight.bold : FontWeight.normal,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // 2. KATEGÓRIA BALÍČKA
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: inputDecoration,
                child: TextField(
                  controller: _categoryController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: inputTextColor,
                    fontFamily: isCyber ? 'monospace' : null,
                    fontWeight: isNeo || isCyber ? FontWeight.w900 : FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: isCyber ? t.createDeckCategoryHintCyber : t.createDeckCategoryHint,
                    labelStyle: TextStyle(
                      color: labelTextColor,
                      fontFamily: isCyber ? 'monospace' : null,
                      fontWeight: isNeo || isCyber ? FontWeight.bold : FontWeight.normal,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // 3. TLAČIDLO: PRIDAŤ KARTIČKY
              _buildThemeButton(
                label: t.createDeckBtnAddCards,
                icon: Icons.add_circle_outline_rounded,
                onTap: _saveAndAddCards,
                currentTheme: currentTheme,
                isEnabled: _isFormValid,
              ),

              const SizedBox(height: 14),

              // 4. TLAČIDLO: ULOŽIŤ BALÍČEK
              _buildThemeButton(
                label: t.createDeckBtnSave,
                icon: Icons.check_circle_outline_rounded,
                onTap: _saveDeckOnly,
                currentTheme: currentTheme,
                isEnabled: _isFormValid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}