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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    final Color sectionColor = currentTheme.decksColor;
    final Color textColor = currentTheme.getContrastTextColor(sectionColor);

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: currentTheme.getCardDecoration(sectionColor),
              child: TextField(
                controller: _deckNameController,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: "Deck Name (e.g. Languages)",
                  labelStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: sectionColor, width: 2),
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
                  backgroundColor: sectionColor,
                  foregroundColor: textColor,
                  elevation: currentTheme.cardShadows != null ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.buttonBorderRadius,
                    side: currentTheme.buttonBorder,
                  ),
                ),
                onPressed: _saveData,
                child: Text(
                  "Save Deck", 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: textColor,
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