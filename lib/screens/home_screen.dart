import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'deck_manager_screen.dart';
import 'app_selector_screen.dart';
import 'quizlet_playground_screen.dart';
import '../services/database_helper.dart';
import '../services/anki_importer.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';
import '../themes/themed_background.dart';
import '../services/stats_provider.dart';
import 'settings_screen.dart';
import 'test_setup_screen.dart';
import 'stats_detail_screen.dart';
import '../services/revenuecat_service.dart';
import '../services/daily_challenge_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int customDeckCount = 0;
  bool isPremium = false;
  bool isLoading = true;

  final PageController _pageController = PageController();
  int _currentCarouselPage = 0;
  Timer? _carouselTimer;

  DailyChallenge? _todayChallenge;
  int _challengeProgress = 0;
  bool _isChallengeCompleted = false;
  int _challengeStreak = 0;

  static const Color _softCardBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _refreshAllData();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshAllData() async {
    await _checkDeckCount();
    await _loadDailyChallenge();
    if (mounted) {
      await Provider.of<StatsProvider>(context, listen: false).loadTodayStats();
    }
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _pageController.hasClients) {
        int nextPage = (_currentCarouselPage + 1) % 4;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _checkDeckCount() async {
    final count = await DatabaseHelper.instance.getCustomDeckCount();
    final premiumStatus = await RevenueCatService.isPremium();
    
    if (!mounted) return;
    setState(() {
      customDeckCount = count;
      isPremium = premiumStatus;
      isLoading = false;
    });
  }

  Future<void> _loadDailyChallenge() async {
    final status = await DailyChallengeService.getTodayChallengeStatus();
    if (!mounted) return;
    setState(() {
      _todayChallenge = status['challenge'] as DailyChallenge?;
      _challengeProgress = (status['progress'] as num?)?.toInt() ?? 0;
      _isChallengeCompleted = (status['isCompleted'] as bool?) ?? false;
      _challengeStreak = (status['currentStreak'] as num?)?.toInt() ?? 0;
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
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;

    final dialogBgColor = isNeo 
        ? Colors.white 
        : (isSoft ? _softCardBg : theme.cardColor);

    final dialogTextColor = isNeo 
        ? Colors.black 
        : (isSoft ? const Color(0xFF2D3748) : Colors.white);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: isNeo ? const BorderSide(color: Colors.black, width: 3.5) : currentTheme.buttonBorder,
        ),
        title: Column(
          children: [
            Icon(Icons.star_rounded, size: 50, color: isNeo ? Colors.black : currentTheme.warningColor),
            const SizedBox(height: 10),
            Text(
              "Odomkni FlashPass Premium!",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold, color: dialogTextColor),
            ),
          ],
        ),
        content: Text(
          "Dosiahol si limit 3 vlastných balíčkov zadarmo.\n\nPre neobmedzené vytváranie balíčkov si aktivuj Premium.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: isNeo ? FontWeight.w600 : FontWeight.normal, color: dialogTextColor.withValues(alpha: 0.8)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentTheme.errorColor,
              foregroundColor: currentTheme.getContrastTextColor(currentTheme.errorColor),
              elevation: isNeo ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: currentTheme.buttonBorderRadius,
                side: isNeo ? const BorderSide(color: Colors.black, width: 3.5) : currentTheme.buttonBorder,
              ),
            ),
            child: Text("Zrušiť", style: TextStyle(color: isNeo ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
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
              elevation: isNeo ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: currentTheme.buttonBorderRadius,
                side: isNeo ? const BorderSide(color: Colors.black, width: 3.5) : currentTheme.buttonBorder,
              ),
            ),
            child: Text("Odomknúť Premium", style: TextStyle(fontWeight: FontWeight.w900, color: isNeo ? Colors.black : Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCardHeader({
    required String title,
    required Color titleColor,
    required bool isSoft,
    required bool isNeo,
    required bool isCyber,
    String? sysCode,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isCyber)
          Text(
            sysCode ?? '// SYS_01',
            style: TextStyle(
              color: titleColor.withValues(alpha: 0.8),
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          )
        else
          const SizedBox(width: 26),
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 12,
            letterSpacing: isCyber ? 1.5 : 1.2,
            fontFamily: isCyber ? 'monospace' : null,
            fontWeight: FontWeight.w900,
          ),
        ),
        Container(
          width: 26,
          height: 26,
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
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: isNeo 
                ? Colors.black 
                : (isSoft ? const Color(0xFF64748B) : titleColor.withValues(alpha: 0.85)),
          ),
        ),
      ],
    );
  }

  Widget _buildShipatonFooterBadge(BuildContext context) {
    final currentTheme = Provider.of<ThemeProvider>(context).currentThemeData;
    final bool isCyberpunk = currentTheme.id == 0 || currentTheme.name.toLowerCase().contains('cyberpunk');
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';

    final Color textColor = isCyberpunk
        ? const Color(0xFF00F0FF)
        : (isNeo
            ? Colors.black
            : (isSoft
                ? const Color(0xFF4A5568)
                : (isGlass 
                    ? Colors.white.withValues(alpha: 0.85)
                    : currentTheme.theme.colorScheme.onSurface.withValues(alpha: 0.65))));

    final Color badgeBg = isCyberpunk
        ? const Color(0xFF120E24).withValues(alpha: 0.85)
        : (isNeo
            ? const Color(0xFFF7EED2)
            : (isSoft
                ? const Color(0xFFD1D9E6)
                : (isGlass
                    ? Colors.white.withValues(alpha: 0.10)
                    : currentTheme.theme.cardColor.withValues(alpha: 0.60))));

    final Border border = isCyberpunk
        ? Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5), width: 1.2)
        : (isNeo
            ? Border.all(color: Colors.black, width: 2.5)
            : (isGlass
                ? Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.0)
                : Border.all(color: textColor.withValues(alpha: 0.20), width: 1.0)));

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
          border: border,
          boxShadow: isNeo 
              ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2))] 
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rocket_launch_rounded, 
              size: 13, 
              color: isCyberpunk ? const Color(0xFFFF007F) : textColor,
            ),
            const SizedBox(width: 6),
            Text(
              "Created for Shipaton 2026 by RevenueCat",
              style: TextStyle(
                fontSize: 11,
                fontWeight: isNeo || isCyberpunk ? FontWeight.w900 : FontWeight.w600,
                fontFamily: isCyberpunk ? 'monospace' : null,
                color: textColor,
                letterSpacing: isCyberpunk ? 0.6 : 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: theme.appBarTheme.elevation ?? 0,
        title: Row(
          children: [
            Text(
              'FlashPass Decks',
              style: theme.appBarTheme.titleTextStyle ?? TextStyle(
                color: isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : theme.colorScheme.onSurface),
                fontWeight: isNeo || isSoft ? FontWeight.w900 : FontWeight.bold,
                fontSize: 22,
                fontFamily: isCyber ? 'monospace' : null,
                letterSpacing: isCyber ? 1.5 : 1.0,
              ),
            ),
            if (isCyber) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF66).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF00FF66), width: 1.0),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'v1.0',
                  style: TextStyle(color: Color(0xFF00FF66), fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.star_rounded, color: isNeo ? Colors.black : Colors.amber, size: 30),
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
              color: isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : (theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onSurface)), 
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
      
      body: ThemedBackground(
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: currentTheme.testSetupColor))
            : Consumer<StatsProvider>(
                builder: (context, statsProvider, child) {
                  final todayStats = statsProvider.todayStats;
                  final int streak = statsProvider.currentStreak;
                  final int cardsDone = (todayStats['cards'] as num?)?.toInt() ?? 0;
                  final int timeEarnedSeconds = (todayStats['time'] as num?)?.toInt() ?? 0;
                  
                  const int dailyTarget = 20;
                  double progressValue = (cardsDone / dailyTarget).clamp(0.0, 1.0);

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 235,
                        child: Column(
                          children: [
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() => _currentCarouselPage = index);
                                  _startAutoScroll();
                                },
                                children: [
                                  _buildDailyGoalCard(
                                    context: context,
                                    currentTheme: currentTheme,
                                    theme: theme,
                                    streak: streak,
                                    cardsDone: cardsDone,
                                    dailyTarget: dailyTarget,
                                    progressValue: progressValue,
                                    isCyber: isCyber,
                                  ),

                                  _buildDailyChallengeCard(
                                    context: context,
                                    currentTheme: currentTheme,
                                    theme: theme,
                                    isCyber: isCyber,
                                  ),

                                  _buildTimeEarnedCard(
                                    context: context,
                                    currentTheme: currentTheme,
                                    theme: theme,
                                    earnedSeconds: timeEarnedSeconds,
                                    isCyber: isCyber,
                                  ),

                                  _buildAccuracyMasteryCard(
                                    context: context,
                                    currentTheme: currentTheme,
                                    theme: theme,
                                    statsProvider: statsProvider,
                                    isCyber: isCyber,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                bool isSelected = _currentCarouselPage == index;
                                Color dotColor;
                                switch (index) {
                                  case 0: dotColor = currentTheme.dailyGoalColor; break;
                                  case 1: dotColor = currentTheme.id == 5 ? const Color(0xFFFF3344) : currentTheme.decksColor; break;
                                  case 2: dotColor = currentTheme.quickImportColor; break;
                                  case 3: dotColor = currentTheme.id == 5 ? currentTheme.testSetupColor : currentTheme.blockedAppsColor; break;
                                  default: dotColor = currentTheme.dailyGoalColor;
                                }

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: isSelected ? 22 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? (isNeo ? Colors.black : (isSoft ? const Color(0xFF2563EB) : dotColor))
                                        : (isNeo ? Colors.black26 : (isSoft ? const Color(0xFFA0AEC0) : theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                                    borderRadius: BorderRadius.circular(isCyber ? 1 : 4),
                                    border: isNeo ? Border.all(color: Colors.black, width: 1.5) : (isCyber && isSelected ? Border.all(color: dotColor, width: 1) : null),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 13,
                                  color: isSoft ? const Color(0xFF64748B) : (isCyber ? const Color(0xFF00F5FF).withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCyber ? '// Ťukni na kartu pre detailné štatistiky' : 'Ťukni na kartu pre detailné štatistiky',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: isCyber ? 'monospace' : null,
                                    fontWeight: FontWeight.w600,
                                    color: isSoft ? const Color(0xFF64748B) : (isCyber ? const Color(0xFF00F5FF).withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // PREMIUM KARTA
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
                          decoration: isSoft
                              ? BoxDecoration(
                                  color: _softCardBg,
                                  borderRadius: currentTheme.cardBorderRadius,
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(5, 5), blurRadius: 14),
                                    BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
                                  ],
                                )
                              : (currentTheme.id == 5 
                                  ? currentTheme.getCardDecoration(currentTheme.quickImportColor) 
                                  : currentTheme.getCardDecoration(currentTheme.warningColor)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: isSoft
                                    ? BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(2, 2), blurRadius: 4),
                                          BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                                        ],
                                      )
                                    : null,
                                child: Icon(
                                  Icons.star_rounded, 
                                  color: isNeo ? Colors.black : (isSoft ? const Color(0xFFD97706) : (currentTheme.id == 5 ? Colors.white : Colors.amber)), 
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                isPremium 
                                    ? (isCyber ? '// MANAGE PREMIUM' : 'MANAGE PREMIUM') 
                                    : (isCyber ? '// UNLOCK PREMIUM' : 'PREMIUM ACCESS'),
                                style: TextStyle(
                                  color: isNeo 
                                      ? Colors.black 
                                      : (isSoft ? const Color(0xFFB45309) : (currentTheme.id == 5 ? Colors.white : currentTheme.warningColor)),
                                  fontWeight: FontWeight.w900,
                                  fontFamily: isCyber ? 'monospace' : null,
                                  letterSpacing: 1.3,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // DECKS KARTA
                      InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DeckManagerScreen()),
                          );
                          _refreshAllData();
                        },
                        borderRadius: currentTheme.cardBorderRadius,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          decoration: isSoft
                              ? BoxDecoration(
                                  color: _softCardBg,
                                  borderRadius: currentTheme.cardBorderRadius,
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(5, 5), blurRadius: 14),
                                    BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
                                  ],
                                )
                              : currentTheme.getCardDecoration(currentTheme.testSetupColor),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isCyber)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '// STORAGE_BANK :: DECKS',
                                    style: TextStyle(
                                      color: currentTheme.testSetupColor.withValues(alpha: 0.85),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              Container(
                                width: 68,
                                height: 68,
                                decoration: isSoft
                                    ? BoxDecoration(
                                        color: const Color(0xFFCCFBF1),
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(3, 3), blurRadius: 6),
                                          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                                        ],
                                      )
                                    : null,
                                child: Icon(
                                  Icons.style_rounded, 
                                  size: 38, 
                                  color: isNeo ? Colors.black : (isSoft ? const Color(0xFF0D9488) : currentTheme.getIconColor(currentTheme.testSetupColor)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Decks',
                                style: TextStyle(
                                  color: isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : (currentTheme.id == 5 ? Colors.white : theme.colorScheme.onSurface)),
                                  fontSize: 22,
                                  fontFamily: isCyber ? 'monospace' : null,
                                  fontWeight: isNeo || isSoft ? FontWeight.w900 : FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isCyber 
                                    ? '[$customDeckCount BALÍČKOV] :: Správa & tvorba' 
                                    : '$customDeckCount balíčkov · Správa & tvorba',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isNeo ? Colors.black87 : (isSoft ? const Color(0xFF64748B) : (currentTheme.id == 5 ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                                  fontSize: 12,
                                  fontFamily: isCyber ? 'monospace' : null,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // TEST SETUP & BLOCKED APPS
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionTile(
                              icon: Icons.settings_suggest_rounded,
                              title: 'Test Setup',
                              subtitle: isCyber ? '[SYS_CONFIG]' : 'Prispôsob si učenie',
                              accentColor: currentTheme.decksColor,
                              socketBgColor: isSoft ? const Color(0xFFEDE9FE) : null,
                              socketIconColor: isSoft ? const Color(0xFF7C3AED) : null,
                              currentTheme: currentTheme,
                              isCyber: isCyber,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const TestSetupScreen()))
                                    .then((_) => _refreshAllData());
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionTile(
                              icon: Icons.smartphone_rounded,
                              title: 'Blocked Apps',
                              subtitle: isCyber ? '[APP_LOCK]' : 'Výber blokovaných appiek',
                              accentColor: currentTheme.blockedAppsColor,
                              socketBgColor: isSoft ? const Color(0xFFFFE4E6) : null,
                              socketIconColor: isSoft ? const Color(0xFFE11D48) : null,
                              currentTheme: currentTheme,
                              isCyber: isCyber,
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

                      const SizedBox(height: 22),

                      // QUICK IMPORT PRIAMO V LISTVIEW
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: isSoft
                              ? BoxDecoration(
                                  color: _softCardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(3, 3), blurRadius: 5),
                                    BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 5),
                                  ],
                                )
                              : BoxDecoration(
                                  color: isNeo ? Colors.white : theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(isCyber ? 3 : 6),
                                  border: isNeo ? Border.all(color: Colors.black, width: 2.0) : (isCyber 
                                      ? Border.all(color: currentTheme.quickImportColor, width: 1.5) 
                                      : null),
                                  boxShadow: isNeo ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2))] : (isCyber ? [
                                    BoxShadow(color: currentTheme.quickImportColor.withValues(alpha: 0.3), blurRadius: 8)
                                  ] : null),
                                ),
                          child: Text(
                            isCyber ? '// DATA_INGESTION_PROTOCOL' : 'QUICK IMPORT',
                            style: TextStyle(
                              color: isNeo 
                                  ? Colors.black 
                                  : (isSoft ? const Color(0xFF4A5568) : (isCyber ? currentTheme.quickImportColor : theme.colorScheme.onSurface.withValues(alpha: 0.8))),
                              fontSize: 11,
                              fontFamily: isCyber ? 'monospace' : null,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildImportTile(
                              title: 'CSV Import',
                              icon: Icons.description_rounded,
                              accentColor: currentTheme.quickImportColor,
                              socketBgColor: isSoft ? const Color(0xFFD6E4FF) : null,
                              socketIconColor: isSoft ? const Color(0xFF2563EB) : null,
                              isLocked: false,
                              currentTheme: currentTheme,
                              isCyber: isCyber,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const QuizletPlaygroundScreen()),
                                ).then((_) => _refreshAllData());
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildImportTile(
                              title: 'Anki',
                              icon: Icons.view_carousel_rounded,
                              accentColor: currentTheme.quickImportColor,
                              socketBgColor: isSoft ? const Color(0xFFE0F2FE) : null,
                              socketIconColor: isSoft ? const Color(0xFF0284C7) : null,
                              isLocked: false,
                              currentTheme: currentTheme,
                              isCyber: isCyber,
                              onTap: () {
                                _handleAnkiImport();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // SHIPATON 2026 BADGE
                      _buildShipatonFooterBadge(context),

                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDailyGoalCard({
    required BuildContext context,
    required AppThemeData currentTheme,
    required ThemeData theme,
    required int streak,
    required int cardsDone,
    required int dailyTarget,
    required double progressValue,
    required bool isCyber,
  }) {
    final bool isNeobrutalism = currentTheme.id == 2;
    final bool isVibrant = currentTheme.id == 5;
    final bool isSoft = currentTheme.id == 1;
    
    final bool isCompleted = cardsDone >= dailyTarget;
    final int displayStreak = isCompleted ? streak + 1 : streak;
    final String dayWord = displayStreak == 1 ? 'Deň' : (displayStreak >= 2 && displayStreak <= 4 ? 'Dni' : 'Dní');

    final String statusText = isCompleted 
        ? 'Splnené  ' 
        : '$cardsDone / $dailyTarget Kariet';

    final Color progressFillColor = isNeobrutalism 
        ? Colors.black 
        : (isSoft ? const Color(0xFF2563EB) : (isVibrant ? Colors.white : (isCompleted ? currentTheme.successColor : currentTheme.dailyGoalColor)));
        
    final Color progressBgColor = isNeobrutalism 
        ? Colors.white 
        : (isSoft ? const Color(0xFFE2E8F0) : Colors.black.withValues(alpha: 0.35));

    final BoxDecoration cardDecoration = isSoft
        ? BoxDecoration(
            color: _softCardBg,
            borderRadius: currentTheme.cardBorderRadius,
            boxShadow: const [
              BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(5, 5), blurRadius: 14),
              BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
            ],
          )
        : currentTheme.getCardDecoration(currentTheme.dailyGoalColor);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatsDetailScreen()),
        );
      },
      borderRadius: currentTheme.cardBorderRadius,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCarouselCardHeader(
              title: 'DAILY GOAL',
              titleColor: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFF2563EB) : (isVibrant ? Colors.white.withValues(alpha: 0.9) : currentTheme.dailyGoalColor)),
              isSoft: isSoft,
              isNeo: isNeobrutalism,
              isCyber: isCyber,
              sysCode: '// GOAL_TRACKER',
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 14),
                Text(
                  '$displayStreak $dayWord Streak\n$statusText',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFF1E293B) : (isVibrant ? Colors.white : theme.colorScheme.onSurface)),
                    fontWeight: isNeobrutalism || isSoft ? FontWeight.w900 : FontWeight.bold,
                    fontFamily: isCyber ? 'monospace' : null,
                    fontSize: 19,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: progressBgColor,
                borderRadius: BorderRadius.circular(isNeobrutalism ? 6 : (isCyber ? 2 : 8)),
                border: isNeobrutalism 
                    ? Border.all(color: Colors.black, width: 2.5) 
                    : (isCyber ? Border.all(color: currentTheme.dailyGoalColor.withValues(alpha: 0.5), width: 1) : null),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isNeobrutalism ? 3 : (isCyber ? 1 : 8)),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(progressFillColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard({
    required BuildContext context,
    required AppThemeData currentTheme,
    required ThemeData theme,
    required bool isCyber,
  }) {
    final bool isVibrantGradient = currentTheme.id == 5;
    final bool isNeobrutalism = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    
    final Color textColor = isNeobrutalism
        ? Colors.black
        : (isSoft ? const Color(0xFF1E293B) : (isVibrantGradient ? Colors.white : currentTheme.getContrastTextColor(currentTheme.decksColor)));

    final BoxDecoration cardDecoration = isSoft
        ? BoxDecoration(
            color: _softCardBg,
            borderRadius: currentTheme.cardBorderRadius,
            boxShadow: const [
              BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(5, 5), blurRadius: 14),
              BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
            ],
          )
        : (isVibrantGradient 
            ? BoxDecoration(
                borderRadius: currentTheme.cardBorderRadius,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3344), Color(0xFF66000E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : currentTheme.getCardDecoration(currentTheme.decksColor));

    if (_todayChallenge == null) {
      return Container(
        decoration: cardDecoration,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final double challengeProgressPct = (_challengeProgress / _todayChallenge!.target).clamp(0.0, 1.0);
    final int bonusMin = _todayChallenge!.bonusSeconds ~/ 60;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(_todayChallenge!.iconEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    isCyber ? '// MISSION_CONTROL' : 'DENNÁ VÝZVA',
                    style: TextStyle(
                      color: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFF7C3AED) : (isCyber ? currentTheme.decksColor : textColor.withValues(alpha: 0.8))),
                      fontSize: 12,
                      fontFamily: isCyber ? 'monospace' : null,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            if (_challengeStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isNeobrutalism ? Colors.white : (isSoft ? const Color(0xFFE2E8F0) : Colors.black),
                  borderRadius: BorderRadius.circular(isCyber ? 3 : 10),
                  border: Border.all(color: isNeobrutalism ? Colors.black : Colors.orange, width: isCyber ? 1.0 : 2.0),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '$_challengeStreak d',
                      style: TextStyle(
                        color: isNeobrutalism ? Colors.black : Colors.orange,
                        fontWeight: FontWeight.w900,
                        fontFamily: isCyber ? 'monospace' : null,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _todayChallenge!.title,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontFamily: isCyber ? 'monospace' : null,
              fontWeight: isNeobrutalism || isSoft ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _todayChallenge!.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isNeobrutalism ? Colors.black87 : (isSoft ? const Color(0xFF64748B) : textColor.withValues(alpha: 0.8)),
              fontSize: 12,
              fontWeight: isNeobrutalism ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: isNeobrutalism ? Colors.white : (isSoft ? const Color(0xFFE2E8F0) : Colors.black.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(isNeobrutalism ? 6 : (isCyber ? 2 : 8)),
                    border: isNeobrutalism ? Border.all(color: Colors.black, width: 2.0) : (isCyber ? Border.all(color: currentTheme.decksColor.withValues(alpha: 0.5), width: 1) : null),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isNeobrutalism ? 3 : (isCyber ? 1 : 8)),
                    child: LinearProgressIndicator(
                      value: challengeProgressPct,
                      backgroundColor: Colors.transparent,
                      color: isNeobrutalism 
                          ? Colors.black 
                          : (isSoft ? const Color(0xFF7C3AED) : (_isChallengeCompleted ? currentTheme.successColor : (isVibrantGradient ? Colors.white : theme.colorScheme.primary))),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$_challengeProgress / ${_todayChallenge!.target}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontFamily: isCyber ? 'monospace' : null,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: isSoft
                  ? BoxDecoration(
                      color: const Color(0xFFEBF0F5),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(2, 2), blurRadius: 4),
                        BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                      ],
                    )
                  : BoxDecoration(
                      color: isNeobrutalism ? Colors.white : Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(isCyber ? 3 : 8),
                      border: isNeobrutalism ? Border.all(color: Colors.black, width: 2.0) : (isCyber ? Border.all(color: Colors.amber, width: 1.0) : null),
                    ),
              child: Text(
                'Odmena: +$bonusMin min',
                style: TextStyle(
                  color: isSoft ? const Color(0xFF7C3AED) : textColor,
                  fontSize: 11,
                  fontFamily: isCyber ? 'monospace' : null,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEarnedCard({
    required BuildContext context,
    required AppThemeData currentTheme,
    required ThemeData theme,
    required int earnedSeconds,
    required bool isCyber,
  }) {
    int minutes = earnedSeconds ~/ 60;
    int seconds = earnedSeconds % 60;
    final bool isNeobrutalism = currentTheme.id == 2;
    final bool isVibrant = currentTheme.id == 5;
    final bool isSoft = currentTheme.id == 1;

    final BoxDecoration cardDecoration = isSoft
        ? BoxDecoration(
            color: _softCardBg,
            borderRadius: currentTheme.cardBorderRadius,
            boxShadow: const [
              BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(5, 5), blurRadius: 14),
              BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
            ],
          )
        : currentTheme.getCardDecoration(currentTheme.quickImportColor);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatsDetailScreen()),
        );
      },
      borderRadius: currentTheme.cardBorderRadius,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCarouselCardHeader(
              title: 'ZÍSKANÝ ČAS DNES',
              titleColor: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFF2563EB) : (isVibrant ? Colors.white.withValues(alpha: 0.9) : currentTheme.quickImportColor)),
              isSoft: isSoft,
              isNeo: isNeobrutalism,
              isCyber: isCyber,
              sysCode: '// TIME_LOG',
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 38)),
                const SizedBox(width: 12),
                Text(
                  '${minutes}m ${seconds}s',
                  style: TextStyle(
                    color: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFF1E293B) : (isVibrant ? Colors.white : theme.colorScheme.onSurface)),
                    fontWeight: isNeobrutalism || isSoft ? FontWeight.w900 : FontWeight.bold,
                    fontFamily: isCyber ? 'monospace' : null,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isCyber ? '[UNLOCK_TIME_BANK] :: Vybojovaný čas' : 'Vybojovaný čas na odomknutie aplikácií',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isNeobrutalism ? Colors.black87 : (isSoft ? const Color(0xFF64748B) : (isVibrant ? Colors.white.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                fontSize: 12,
                fontFamily: isCyber ? 'monospace' : null,
                fontWeight: isNeobrutalism || isSoft ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyMasteryCard({
    required BuildContext context,
    required AppThemeData currentTheme,
    required ThemeData theme,
    required StatsProvider statsProvider,
    required bool isCyber,
  }) {
    final rawAccuracy = statsProvider.todayStats['accuracy'];
    double val = (rawAccuracy as num?)?.toDouble() ?? 0.0;

    double accuracyPct = val > 1.0 ? val : val * 100;
    int masteredCount = (statsProvider.todayStats['mastered'] as num?)?.toInt() ?? 0;
    
    final bool isNeobrutalism = currentTheme.id == 2;
    final bool isVibrant = currentTheme.id == 5;
    final bool isSoft = currentTheme.id == 1;

    final Color accuracyCardColor = isVibrant 
        ? currentTheme.testSetupColor 
        : currentTheme.blockedAppsColor;

    final BoxDecoration cardDecoration = isSoft
        ? BoxDecoration(
            color: _softCardBg,
            borderRadius: currentTheme.cardBorderRadius,
            boxShadow: const [
              BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(5, 5), blurRadius: 14),
              BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
            ],
          )
        : currentTheme.getCardDecoration(accuracyCardColor);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatsDetailScreen()),
        );
      },
      borderRadius: currentTheme.cardBorderRadius,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCarouselCardHeader(
              title: 'ÚSPEŠNOSŤ & ZVLÁDNUTIE',
              titleColor: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFFE11D48) : (isVibrant ? Colors.white.withValues(alpha: 0.9) : accuracyCardColor)),
              isSoft: isSoft,
              isNeo: isNeobrutalism,
              isCyber: isCyber,
              sysCode: '// METRICS',
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 26)),
                    const SizedBox(height: 2),
                    Text(
                      '${accuracyPct.toStringAsFixed(0)} %',
                      style: TextStyle(
                        color: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFF1E293B) : (isVibrant ? Colors.white : theme.colorScheme.onSurface)),
                        fontWeight: isNeobrutalism || isSoft ? FontWeight.w900 : FontWeight.bold,
                        fontFamily: isCyber ? 'monospace' : null,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Úspešnosť',
                      style: TextStyle(
                        color: isNeobrutalism ? Colors.black87 : (isSoft ? const Color(0xFF64748B) : (isVibrant ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        fontSize: 11,
                        fontFamily: isCyber ? 'monospace' : null,
                        fontWeight: isNeobrutalism || isSoft ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: isNeobrutalism ? 2 : 1,
                  color: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFFCBD5E1) : (isVibrant ? Colors.white.withValues(alpha: 0.3) : theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                ),
                Column(
                  children: [
                    const Text('🧠', style: TextStyle(fontSize: 26)),
                    const SizedBox(height: 2),
                    Text(
                      '$masteredCount',
                      style: TextStyle(
                        color: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFF1E293B) : (isVibrant ? Colors.white : theme.colorScheme.onSurface)),
                        fontWeight: isNeobrutalism || isSoft ? FontWeight.w900 : FontWeight.bold,
                        fontFamily: isCyber ? 'monospace' : null,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Mastered kariet',
                      style: TextStyle(
                        color: isNeobrutalism ? Colors.black87 : (isSoft ? const Color(0xFF64748B) : (isVibrant ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        fontSize: 11,
                        fontFamily: isCyber ? 'monospace' : null,
                        fontWeight: isNeobrutalism || isSoft ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color accentColor,
    required AppThemeData currentTheme,
    required VoidCallback onTap,
    required bool isCyber,
    Color? socketBgColor,
    Color? socketIconColor,
  }) {
    final theme = currentTheme.theme;
    final bool isNeobrutalism = currentTheme.id == 2;
    final bool isVibrant = currentTheme.id == 5;
    final bool isSoft = currentTheme.id == 1;

    final BoxDecoration tileDecoration = isSoft
        ? BoxDecoration(
            color: _softCardBg,
            borderRadius: currentTheme.cardBorderRadius,
            boxShadow: const [
              BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(5, 5), blurRadius: 14),
              BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
            ],
          )
        : currentTheme.getCardDecoration(accentColor);

    return InkWell(
      onTap: onTap,
      borderRadius: currentTheme.cardBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: tileDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: isSoft
                  ? BoxDecoration(
                      color: socketBgColor ?? const Color(0xFFEBF0F5),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(2, 2), blurRadius: 4),
                        BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                      ],
                    )
                  : null,
              child: Icon(
                icon, 
                size: 26, 
                color: isNeobrutalism ? Colors.black : (isSoft ? (socketIconColor ?? accentColor) : currentTheme.getIconColor(accentColor)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFF1E293B) : (isVibrant ? Colors.white : theme.colorScheme.onSurface)),
                fontWeight: isNeobrutalism || isSoft ? FontWeight.w900 : FontWeight.bold,
                fontFamily: isCyber ? 'monospace' : null,
                fontSize: 15,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isNeobrutalism ? Colors.black87 : (isSoft ? const Color(0xFF64748B) : (isVibrant ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  fontSize: 11,
                  fontFamily: isCyber ? 'monospace' : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
    required bool isCyber,
    bool isLocked = false,
    Color? socketBgColor,
    Color? socketIconColor,
  }) {
    final theme = currentTheme.theme;
    final bool isNeobrutalism = currentTheme.id == 2;
    final bool isVibrant = currentTheme.id == 5;
    final bool isSoft = currentTheme.id == 1;

    final BoxDecoration tileDecoration = isSoft
        ? BoxDecoration(
            color: _softCardBg,
            borderRadius: currentTheme.buttonBorderRadius,
            boxShadow: const [
              BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(4, 4), blurRadius: 10),
              BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 8),
            ],
          )
        : currentTheme.getCardDecoration(accentColor);

    return InkWell(
      onTap: onTap,
      borderRadius: currentTheme.buttonBorderRadius,
      child: Opacity(
        opacity: isLocked ? 0.65 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: tileDecoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: isSoft
                    ? BoxDecoration(
                        color: socketBgColor ?? const Color(0xFFEBF0F5),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(2, 2), blurRadius: 4),
                          BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                        ],
                      )
                    : null,
                child: Icon(
                  isLocked ? Icons.lock : icon,
                  color: isNeobrutalism
                      ? Colors.black 
                      : (isSoft ? (socketIconColor ?? accentColor) : (isLocked ? currentTheme.warningColor : currentTheme.getIconColor(accentColor))),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: isNeobrutalism ? Colors.black : (isSoft ? const Color(0xFF1E293B) : (isVibrant ? Colors.white : theme.colorScheme.onSurface)),
                  fontWeight: isNeobrutalism || isSoft ? FontWeight.w900 : FontWeight.bold,
                  fontFamily: isCyber ? 'monospace' : null,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}