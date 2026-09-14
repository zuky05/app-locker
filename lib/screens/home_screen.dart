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

  // --- CAROUSEL STAV & AUTOSCROLL TIMER ---
  final PageController _pageController = PageController();
  int _currentCarouselPage = 0;
  Timer? _carouselTimer;

  // --- DENNÁ VÝZVA STAV ---
  DailyChallenge? _todayChallenge;
  int _challengeProgress = 0;
  bool _isChallengeCompleted = false;
  int _challengeStreak = 0;

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

  // Obnovenie všetkých dát naraz (Deck count, Výzva, StatsProvider)
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
            icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 30),
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
                            ).then((_) => _refreshAllData());
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
          : Consumer<StatsProvider>(
              builder: (context, statsProvider, child) {
                final todayStats = statsProvider.todayStats;
                final int streak = statsProvider.currentStreak;
                final int cardsDone = (todayStats['cards'] as num?)?.toInt() ?? 0;
                final int timeEarnedSeconds = (todayStats['time'] as num?)?.toInt() ?? 0;
                
                const int dailyTarget = 20;
                double progressValue = (cardsDone / dailyTarget).clamp(0.0, 1.0);

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    
                    // 1. CAROUSEL WITH AUTO-SCROLL (4 KARTY)
                    SizedBox(
                      height: 215,
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
                                // Karta 1: Daily Goal
                                _buildDailyGoalCard(
                                  context: context,
                                  currentTheme: currentTheme,
                                  theme: theme,
                                  streak: streak,
                                  cardsDone: cardsDone,
                                  dailyTarget: dailyTarget,
                                  progressValue: progressValue,
                                ),

                                // Karta 2: Denná Výzva
                                _buildDailyChallengeCard(
                                  context: context,
                                  currentTheme: currentTheme,
                                  theme: theme,
                                ),

                                // Karta 3: Získaný Čas (Time Earned)
                                _buildTimeEarnedCard(
                                  context: context,
                                  currentTheme: currentTheme,
                                  theme: theme,
                                  earnedSeconds: timeEarnedSeconds,
                                ),

                                // Karta 4: Úspešnosť a Mastery
                                _buildAccuracyMasteryCard(
                                  context: context,
                                  currentTheme: currentTheme,
                                  theme: theme,
                                  statsProvider: statsProvider,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Indikátor stránok (4 Bodky)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              bool isSelected = _currentCarouselPage == index;
                              Color dotColor;
                              switch (index) {
                                case 0: dotColor = currentTheme.dailyGoalColor; break;
                                case 1: dotColor = currentTheme.testSetupColor; break;
                                case 2: dotColor = currentTheme.quickImportColor; break;
                                case 3: dotColor = currentTheme.blockedAppsColor; break;
                                default: dotColor = currentTheme.dailyGoalColor;
                              }

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: isSelected ? 20 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? dotColor
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
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
                        decoration: currentTheme.id == 5 ? currentTheme.getCardDecoration(currentTheme.quickImportColor) : currentTheme.getCardDecoration(currentTheme.warningColor),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_rounded, 
                              color: currentTheme.id == 5 ? Colors.black : Colors.amber, 
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isPremium ? 'MANAGE PREMIUM' : 'PREMIUM ACCESS',
                              style: TextStyle(
                                color: currentTheme.id == 2 || currentTheme.id == 5 
                                    ? Colors.black 
                                    : currentTheme.warningColor,
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
                        _refreshAllData();
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
                );
              },
            ),
    );
  }

  // --- KARTA 1: DAILY GOAL ---
  Widget _buildDailyGoalCard({
    required BuildContext context,
    required AppThemeData currentTheme,
    required ThemeData theme,
    required int streak,
    required int cardsDone,
    required int dailyTarget,
    required double progressValue,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatsDetailScreen()),
        );
      },
      borderRadius: currentTheme.cardBorderRadius,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: currentTheme.getCardDecoration(currentTheme.dailyGoalColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'DAILY GOAL',
              style: TextStyle(
                color: currentTheme.id == 2 || currentTheme.id == 5 ? Colors.black : currentTheme.dailyGoalColor,
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
                  '$streak dni streak\n$cardsDone / $dailyTarget Kariet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 10,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(currentTheme.dailyGoalColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- KARTA 2: DENNÁ VÝZVA ---
  Widget _buildDailyChallengeCard({
    required BuildContext context,
    required AppThemeData currentTheme,
    required ThemeData theme,
  }) {
    if (_todayChallenge == null) {
      return Container(
        decoration: currentTheme.getCardDecoration(currentTheme.testSetupColor),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final double challengeProgressPct = (_challengeProgress / _todayChallenge!.target).clamp(0.0, 1.0);
    final int bonusMin = _todayChallenge!.bonusSeconds ~/ 60;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: currentTheme.getCardDecoration(
        _isChallengeCompleted ? currentTheme.successColor.withValues(alpha: 0.15) : currentTheme.testSetupColor,
      ),
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
                    'DENNÁ VÝZVA',
                    style: TextStyle(
                      color: currentTheme.getContrastTextColor(currentTheme.testSetupColor).withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              if (_challengeStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$_challengeStreak d',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
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
              color: currentTheme.getContrastTextColor(currentTheme.testSetupColor),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _todayChallenge!.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: currentTheme.getContrastTextColor(currentTheme.testSetupColor).withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: challengeProgressPct,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    color: _isChallengeCompleted ? currentTheme.successColor : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$_challengeProgress / ${_todayChallenge!.target}',
                style: TextStyle(
                  color: currentTheme.getContrastTextColor(currentTheme.testSetupColor),
                  fontWeight: FontWeight.bold,
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
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Odmena: +$bonusMin min',
                style: TextStyle(
                  color: currentTheme.getContrastTextColor(currentTheme.testSetupColor),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- KARTA 3: ZÍSKANÝ ČAS (TIME EARNED) ---
  Widget _buildTimeEarnedCard({
    required BuildContext context,
    required AppThemeData currentTheme,
    required ThemeData theme,
    required int earnedSeconds,
  }) {
    int minutes = earnedSeconds ~/ 60;
    int seconds = earnedSeconds % 60;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatsDetailScreen()),
        );
      },
      borderRadius: currentTheme.cardBorderRadius,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: currentTheme.getCardDecoration(currentTheme.quickImportColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ZÍSKANÝ ČAS DNES',
              style: TextStyle(
                color: currentTheme.id == 2 || currentTheme.id == 5 ? Colors.black : currentTheme.quickImportColor,
                fontSize: 13,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Text(
                  '${minutes}m ${seconds}s',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vybojovaný čas na odomknutie aplikácií',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- KARTA 4: ÚSPEŠNOSŤ A MASTERY ---
  Widget _buildAccuracyMasteryCard({
    required BuildContext context,
    required AppThemeData currentTheme,
    required ThemeData theme,
    required StatsProvider statsProvider,
  }) {
    final rawAccuracy = statsProvider.todayStats['accuracy'];
    double val = (rawAccuracy as num?)?.toDouble() ?? 0.0;

    double accuracyPct = val > 1.0 ? val : val * 100;
    int masteredCount = (statsProvider.todayStats['mastered'] as num?)?.toInt() ?? 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatsDetailScreen()),
        );
      },
      borderRadius: currentTheme.cardBorderRadius,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: currentTheme.getCardDecoration(currentTheme.blockedAppsColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ÚSPEŠNOSŤ & ZVLÁDNUTIE',
              style: TextStyle(
                color: currentTheme.id == 2 || currentTheme.id == 5 ? Colors.black : currentTheme.blockedAppsColor,
                fontSize: 13,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(
                      '${accuracyPct.toStringAsFixed(0)} %',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'Úspešnosť',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 45,
                  width: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                Column(
                  children: [
                    const Text('🧠', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(
                      '$masteredCount',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'Mastered kariet',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
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