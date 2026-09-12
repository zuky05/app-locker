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
import '../services/revenuecat_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int customDeckCount = 0;
  bool isPremium = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDeckCount();
  }

  Future<void> _checkDeckCount() async {
    final count = await DatabaseHelper.instance.getCustomDeckCount();
    final premiumStatus = await RevenueCatService.isPremium();
    
    setState(() {
      customDeckCount = count;
      isPremium = premiumStatus;
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: currentTheme.buttonBorder,
        ),
        title: Column(
          children: [
            Icon(Icons.star_rounded, size: 50, color: currentTheme.warningColor),
            const SizedBox(height: 10),
            Text(
              "Odomkni Brainlock Premium!",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
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
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentTheme.errorColor,
              foregroundColor: currentTheme.getContrastTextColor(currentTheme.errorColor),
              shape: RoundedRectangleBorder(
                borderRadius: currentTheme.buttonBorderRadius,
                side: currentTheme.buttonBorder,
              ),
            ),
            child: const Text("Zrušiť"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await RevenueCatService.presentPaywall();
              
              if (success) {
                _checkDeckCount();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Vitaj v Premium klube! 🎉"), 
                      backgroundColor: currentTheme.successColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: currentTheme.warningColor,
              foregroundColor: currentTheme.getContrastTextColor(currentTheme.warningColor),
              shape: RoundedRectangleBorder(
                borderRadius: currentTheme.buttonBorderRadius,
                side: currentTheme.buttonBorder,
              ),
            ),
            child: const Text("Odomknúť Premium", style: TextStyle(fontWeight: FontWeight.bold)),
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
    

    final bool isLimitReached = customDeckCount >= 3 && !isPremium; 

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        elevation: theme.appBarTheme.elevation ?? 0,
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
            icon: Icon(Icons.star_rounded, color: Colors.amber, size: 30),
            tooltip: 'Premium',
            onPressed: () async {
              if (isPremium) {
                RevenueCatService.showCustomerCenter();
              } else {
                final success = await RevenueCatService.presentPaywall();
                if (success) _checkDeckCount();
              }
            },
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
          ? Center(child: CircularProgressIndicator(color: currentTheme.decksColor))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              physics: const BouncingScrollPhysics(),
              children: [
                
                // 1. DAILY GOAL
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  decoration: currentTheme.getCardDecoration(currentTheme.dailyGoalColor),
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
                              color: theme.colorScheme.onSurface,
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

                // 2. PREMIUM ACCESS BANNER
                InkWell(
                  onTap: () async {
                    if (isPremium) {
                      RevenueCatService.showCustomerCenter();
                    } else {
                      final success = await RevenueCatService.presentPaywall();
                      if (success) _checkDeckCount();
                    }
                  },
                  borderRadius: currentTheme.cardBorderRadius,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: currentTheme.getCardDecoration(currentTheme.warningColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_rounded, 
                          color: Colors.amber, 
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isPremium ? 'MANAGE PREMIUM' : 'PREMIUM ACCESS',
                          style: TextStyle(
                            color: currentTheme.id == 2 
                      ? Colors.black : currentTheme.warningColor ,
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
                    decoration: currentTheme.getCardDecoration(currentTheme.decksColor),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.style_rounded, 
                          size: 52, 
                          color: currentTheme.getIconColor(currentTheme.decksColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Decks',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
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
        decoration: currentTheme.getCardDecoration(accentColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 38, 
              color: currentTheme.getIconColor(accentColor),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
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
          decoration: currentTheme.getCardDecoration(accentColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLocked ? Icons.lock : icon,
                color: isLocked 
                    ? currentTheme.warningColor 
                    : currentTheme.getIconColor(accentColor),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
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