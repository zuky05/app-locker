import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../themes/theme_provider.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _deckNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _promptController = TextEditingController();
  final _answerController = TextEditingController();

  @override
  void dispose() {
    _deckNameController.dispose();
    _categoryController.dispose();
    _promptController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _saveData() async {
    final String deckName = _deckNameController.text.trim();
    final String category = _categoryController.text.trim();
    final String prompt = _promptController.text.trim();
    final String answer = _answerController.text.trim();

    if (deckName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadaj názov balíčka')),
      );
      return;
    }

    // 1. Vytvorenie balíčka a získanie jeho ID
    final int deckId = await DatabaseHelper.instance.addNewDeck(
      deckName, 
      category.isNotEmpty ? category : "Custom",
    );

    // 2. Ak bola zadaná aj prvá karta, uloží sa spolu s balíčkom
    if (prompt.isNotEmpty && answer.isNotEmpty) {
      await DatabaseHelper.instance.addNewCard(deckId, prompt, answer);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    final Color buttonBgColor = currentTheme.decksColor;
    final Color buttonTextColor = currentTheme.getContrastTextColor(buttonBgColor);

    // Jednotná neutrálna dekorácia pre VŠETKY vstupujúce polia pre VŠETKY témy
    final BoxDecoration inputDecoration = BoxDecoration(
      color: theme.cardColor,
      borderRadius: currentTheme.cardBorderRadius,
      border: Border.all(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        width: 1.2,
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Nový balíček"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. NÁZOV BALÍČKA (NEUTRÁLNY PRE VŠETKY TÉMY)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: inputDecoration,
              child: TextField(
                controller: _deckNameController,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: "Názov balíčka (napr. Nemčina)",
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            const SizedBox(height: 14),

            // 2. KATEGÓRIA BALÍČKA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: inputDecoration,
              child: TextField(
                controller: _categoryController,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: "Kategória (napr. Jazyky)",
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              "Prvá kartička (voliteľné):", 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 14),

            // 3. OTÁZKA / POJEM
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: inputDecoration,
              child: TextField(
                controller: _promptController,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: "Otázka / Pojem (Predná strana)",
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 4. SPRÁVNA ODPOVEĎ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: inputDecoration,
              child: TextField(
                controller: _answerController,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: "Správna odpoveď (Zadná strana)",
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // TLAČIDLO ULOŽIŤ (Vypnutý outline pre Cyberpunk tému)
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: buttonBgColor,
                  foregroundColor: buttonTextColor,
                  elevation: currentTheme.cardShadows != null ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.buttonBorderRadius,
                    side: currentTheme.id == 4 
                        ? BorderSide.none 
                        : currentTheme.buttonBorder,
                  ),
                ),
                onPressed: _saveData,
                child: Text(
                  "Uložiť balíček", 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: buttonTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}