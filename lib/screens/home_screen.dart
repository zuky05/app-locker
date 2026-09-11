import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'deck_manager_screen.dart';
import 'app_selector_screen.dart';
import 'quizlet_playground_screen.dart';
import '../services/database_helper.dart';
import '../services/anki_importer.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';
import 'settings_screen.dart';
import 'test_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int customDeckCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDeckCount();
  }

  Future<void> _checkDeckCount() async {
    final count = await DatabaseHelper.instance.getCustomDeckCount();
    setState(() {
      customDeckCount = count;
      isLoading = false;
    });
  }

  Future<void> _handleAnkiImport() async {
    final String? result = await AnkiImporter.importApkgDirect();
    if (result == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    _checkDeckCount();
  }

  void _showPremiumDialog() {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final theme = currentTheme.theme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: currentTheme.cardBorderRadius),
        title: const Column(
          children: [
            Icon(Icons.star_rounded, size: 50, color: Color(0xFFFFB800)),
            SizedBox(height: 10),
            Text(
              "Odomkni Brainlock Premium!",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "Dosiahol si limit 3 vlastných balíčkov zadarmo.\n\nPre import ďalších balíčkov si aktivuj Premium.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: currentTheme.buttonBorderRadius),
            ),
            child: const Text("Zrušiť"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB800),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: currentTheme.buttonBorderRadius),
            ),
            child: const Text("Odomknúť Premium", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Pomocná metóda na vytvorenie dekorácie karty s vlastnou akcentovou farbou okroja
  BoxDecoration _getCustomCardDecoration(AppThemeData currentTheme, Color accentColor) {
    final theme = currentTheme.theme;

    // Pre Cyberpunk / Brutalism vytvoríme dynamický okraj podľa akcentu karty
    Border border;
    if (currentTheme.id == 0) {
      // Cyberpunk Dark: Neónový okraj vo farbe karty
      border = Border.all(color: accentColor, width: 1.5);
    } else if (currentTheme.id == 2) {
      // Neo Brutalism: Hrubý čierny okraj
      border = Border.all(color: Colors.black, width: 3.5);
    } else {
      border = currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.12));
    }

    // Pre Cyberpunk spravíme aj žiaru (glow) vo farbe danej karty
    List<BoxShadow>? shadows;
    if (currentTheme.id == 0) {
      shadows = [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.35),
          blurRadius: 10,
          spreadRadius: 1,
        )
      ];
    } else {
      shadows = currentTheme.cardShadows;
    }

    // Pre Neo Brutalism zafarbíme celú kartu akcentovou farbou
    Color cardBgColor = currentTheme.id == 2 ? accentColor : theme.cardColor;

    return BoxDecoration(
      color: cardBgColor,
      borderRadius: currentTheme.cardBorderRadius,
      border: border,
      boxShadow: shadows,
      gradient: currentTheme.id == 2 ? null : currentTheme.cardGradient,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final bool isLimitReached = customDeckCount >= 3;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        elevation: 0,
        title: Text(
          'Brainlock Decks',
          style: theme.appBarTheme.titleTextStyle ?? TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 30),
            tooltip: 'Premium',
            onPressed: _showPremiumDialog,
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined, 
              color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onSurface, 
              size: 24,
            ),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      // STICKY BOTTOM BAR (Quick Import)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 16.0, top: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QUICK IMPORT',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildImportTile(
                        title: 'Quizlet',
                        icon: Icons.language,
                        accentColor: currentTheme.quickImportColor,
                        isLocked: isLimitReached,
                        currentTheme: currentTheme,
                        onTap: () {
                          if (isLimitReached) {
                            _showPremiumDialog();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QuizletPlaygroundScreen()),
                            ).then((_) => _checkDeckCount());
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildImportTile(
                        title: 'Anki',
                        icon: Icons.view_carousel_rounded,
                        accentColor: currentTheme.quickImportColor,
                        isLocked: isLimitReached,
                        currentTheme: currentTheme,
                        onTap: () {
                          if (isLimitReached) {
                            _showPremiumDialog();
                          } else {
                            _handleAnkiImport();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              physics: const BouncingScrollPhysics(),
              children: [
                
                // 1. DAILY GOAL
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  decoration: _getCustomCardDecoration(currentTheme, currentTheme.dailyGoalColor),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DAILY GOAL',
                        style: TextStyle(
                          color: currentTheme.id == 2 ? Colors.black : currentTheme.dailyGoalColor,
                          fontSize: 13,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 42)),
                          const SizedBox(width: 14),
                          Text(
                            '15 / 20\nCards',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 15 / 20,
                          minHeight: 10,
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(currentTheme.dailyGoalColor),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. PREMIUM ACCESS BANNER (VŽDY ZLATÝ)
                InkWell(
                  onTap: _showPremiumDialog,
                  borderRadius: currentTheme.cardBorderRadius,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800), // ZLATÁ FARBA
                      borderRadius: currentTheme.cardBorderRadius,
                      border: currentTheme.id == 2 
                          ? Border.all(color: Colors.black, width: 3.5) 
                          : null,
                      boxShadow: currentTheme.id == 2 
                          ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4))] 
                          : [
                              BoxShadow(
                                color: const Color(0xFFFFB800).withValues(alpha: 0.4),
                                blurRadius: 10,
                              )
                            ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.black, size: 26),
                        SizedBox(width: 10),
                        Text(
                          'PREMIUM ACCESS',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. DECKS
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DeckManagerScreen()),
                    );
                    _checkDeckCount();
                  },
                  borderRadius: currentTheme.cardBorderRadius,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: _getCustomCardDecoration(currentTheme, currentTheme.decksColor),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.style_rounded, 
                          size: 52, 
                          color: currentTheme.id == 2 ? Colors.black : currentTheme.decksColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Decks',
                          style: TextStyle(
                            color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. TEST SETUP & BLOCKED APPS
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.settings_suggest_rounded,
                        title: 'Test Setup',
                        accentColor: currentTheme.testSetupColor,
                        currentTheme: currentTheme,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const TestSetupScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.smartphone_rounded,
                        title: 'Blocked Apps',
                        accentColor: currentTheme.blockedAppsColor,
                        currentTheme: currentTheme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AppSelectorScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color accentColor,
    required AppThemeData currentTheme,
    required VoidCallback onTap,
  }) {
    final theme = currentTheme.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: currentTheme.cardBorderRadius,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: _getCustomCardDecoration(currentTheme, accentColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 38, 
              color: currentTheme.id == 2 ? Colors.black : accentColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportTile({
    required String title,
    required IconData icon,
    required Color accentColor,
    required AppThemeData currentTheme,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    final theme = currentTheme.theme;

    return InkWell(
      onTap: onTap,
      borderRadius: currentTheme.buttonBorderRadius,
      child: Opacity(
        opacity: isLocked ? 0.65 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: _getCustomCardDecoration(currentTheme, accentColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLocked ? Icons.lock : icon,
                color: currentTheme.id == 2 ? Colors.black : (isLocked ? const Color(0xFFFFB800) : accentColor),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}