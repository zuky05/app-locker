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

  @override
  void dispose() {
    _deckNameController.dispose();
    super.dispose();
  }

  void _saveData() async {
    String deckName = _deckNameController.text.trim();
    if (deckName.isEmpty) return;

    await DatabaseHelper.instance.addNewDeck(deckName, "Custom");

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Načítanie aktívnej témy
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    // Sekcová farba pre Decks (zdedená z témy)
    final Color sectionColor = currentTheme.decksColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Create New Deck"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kontajner pre TextField obalený štýlom karty
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: currentTheme.cardBorderRadius,
                border: currentTheme.id == 2 
                    ? Border.all(color: Colors.black, width: 3.5)
                    : (currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.15))),
                boxShadow: currentTheme.id == 2 
                    ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)]
                    : currentTheme.cardShadows,
                gradient: currentTheme.id == 2 ? null : currentTheme.cardGradient,
              ),
              child: TextField(
                controller: _deckNameController,
                style: TextStyle(
                  color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface, 
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: "Deck Name (e.g. History)",
                  labelStyle: TextStyle(
                    color: currentTheme.id == 2 
                        ? Colors.black54 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: currentTheme.id == 2 ? Colors.black : sectionColor),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            Text(
              "First Card:", 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: currentTheme.id == 2 ? Colors.black : sectionColor,
                  foregroundColor: currentTheme.id == 2 ? Colors.white : (sectionColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                  elevation: currentTheme.id == 2 ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.buttonBorderRadius,
                    side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 2.5) : BorderSide.none,
                  ),
                ),
                onPressed: _saveData,
                child: Text(
                  "Save Deck", 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: currentTheme.id == 2 ? Colors.white : (sectionColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}