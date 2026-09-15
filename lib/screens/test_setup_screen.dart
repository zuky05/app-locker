import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';
import 'deck_manager_screen.dart';
import '../themes/themed_background.dart';

class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({super.key});

  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  SharedPreferences? _prefs;
  bool _isLoading = true;
  int? _activeDeckId;
  String _activeDeckName = "Načítavam...";
  int _availableCardCount = 10;

  // --- STAV PRE KVÍZ ---
  double _questionCount = 10;
  double _timeLimitIndex = 0;
  final List<String> _timeLabels = ["Bez limitu", "30 s", "25 s", "20 s", "15 s", "10 s"];
  final List<double> _timeMultipliers = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5];
  
  double _lockoutIndex = 2;
  final List<double> _lockoutPercentages = [0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00];

  bool _is3Options = false;
  bool _isSecondChance = false;
  bool _isSwapQuestion = false;
  bool _isConfusion = false;
  bool _isBlindTest = false;
  bool _isHardcore = false;
  bool _isDoubleTest = false;

  // --- STAV PRE LEARNING MODE ---
  bool _isLearningMode = false;
  double _learnCardCount = 10;
  double _learnInterval = 1;
  bool _learnRepeat = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    final activeDeckId = _prefs!.getInt('active_test_deck_id');
    _activeDeckId = activeDeckId;

    if (activeDeckId != null) {
      final decks = await DatabaseHelper.instance.getDecks();
      final currentDeck = decks.firstWhere(
        (d) => d.id == activeDeckId, 
        orElse: () => null as dynamic,
      );

      final cardCount = await DatabaseHelper.instance.getCardCountForDeck(activeDeckId);

      if (cardCount >= 5 && currentDeck != null) {
        _availableCardCount = cardCount;
        _activeDeckName = currentDeck.name;
      } else {
        _activeDeckId = null;
        await _prefs!.remove('active_test_deck_id');
      }
    }

    double savedQuestions = _prefs!.getDouble('test_questionCount') ?? 10;
    double savedLearnCards = _prefs!.getDouble('test_learnCardCount') ?? 10;

    double maxQuestions = _availableCardCount < 10 ? _availableCardCount.toDouble() : 10;
    if (maxQuestions < 3) maxQuestions = 3;
    if (savedQuestions > maxQuestions) savedQuestions = maxQuestions;

    double maxLearnCards = _availableCardCount < 20 ? _availableCardCount.toDouble() : 20;
    if (maxLearnCards < 5) maxLearnCards = 5;
    if (savedLearnCards > maxLearnCards) savedLearnCards = maxLearnCards;
    if (savedLearnCards < 5) savedLearnCards = 5;

    setState(() {
      _questionCount = savedQuestions;
      _learnCardCount = savedLearnCards;
      
      _timeLimitIndex = _prefs!.getDouble('test_timeLimitIndex') ?? 0;
      _lockoutIndex = _prefs!.getDouble('test_lockoutIndex') ?? 2;
      _is3Options = _prefs!.getBool('test_is3Options') ?? false;
      _isSecondChance = _prefs!.getBool('test_isSecondChance') ?? false;
      _isSwapQuestion = _prefs!.getBool('test_isSwapQuestion') ?? false;
      _isConfusion = _prefs!.getBool('test_isConfusion') ?? false;
      _isBlindTest = _prefs!.getBool('test_isBlindTest') ?? false;
      _isHardcore = _prefs!.getBool('test_isHardcore') ?? false;
      _isDoubleTest = _prefs!.getBool('test_isDoubleTest') ?? false;

      _isLearningMode = _prefs!.getBool('test_isLearningMode') ?? false;
      _learnInterval = _prefs!.getDouble('test_learnInterval') ?? 1;
      _learnRepeat = _prefs!.getBool('test_learnRepeat') ?? true;

      _isLoading = false;
    });
  }

  void _saveDouble(String key, double value) => _prefs?.setDouble(key, value);
  void _saveBool(String key, bool value) => _prefs?.setBool(key, value);

  // --- REÁLNE VYPOČÍTANÉ HODNOTY PRE LOCKOUT ---
  int get _requiredCorrectQuestions {
    double targetPct = _lockoutPercentages[_lockoutIndex.toInt()];
    return (targetPct * _questionCount).round();
  }

  // 🟢 OPRAVA: Násobič sa počíta stabilne priamo zo zvoleného prahu v nastavení
  double get _effectiveLockoutMultiplier {
    double targetPct = _lockoutPercentages[_lockoutIndex.toInt()];
    double mult = 1.0 + (targetPct - 0.5);
    if (mult < 0.6) return 0.6;
    if (mult > 1.5) return 1.5;
    return mult;
  }

  double get _currentMultiplier {
    double mult = 1.0;
    mult *= _timeMultipliers[_timeLimitIndex.toInt()];
    mult *= _effectiveLockoutMultiplier;
    if (_is3Options && !_isHardcore) mult *= 0.7;
    if (_isSwapQuestion) mult *= 0.85;
    if (_isSecondChance) mult *= 0.8;
    if (_isConfusion && !_isHardcore) mult *= 1.1;
    if (_isBlindTest) mult *= 1.25;
    if (_isHardcore) mult *= 1.5;
    if (_isDoubleTest) mult *= 1.75;
    return mult;
  }

  int get _timePerQuestion => (30 * _currentMultiplier).round();
  int get _totalTimePotential => _timePerQuestion * _questionCount.toInt();

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    if (_isLoading) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent, 
          body: Center(child: CircularProgressIndicator(color: currentTheme.testSetupColor)),
        ),
      );
    }

    double maxQuestions = _availableCardCount < 10 ? _availableCardCount.toDouble() : 10;
    double minQuestions = 3;
    if (maxQuestions < minQuestions) maxQuestions = minQuestions;
    
    int questionDivisions = (maxQuestions - minQuestions).toInt();
    if (questionDivisions <= 0) questionDivisions = 1;

    double maxLearnCards = _availableCardCount < 20 ? _availableCardCount.toDouble() : 20;
    double minLearnCards = 5;
    if (maxLearnCards < minLearnCards) maxLearnCards = minLearnCards;

    int learnDivisions = (maxLearnCards - minLearnCards).toInt();
    if (learnDivisions <= 0) learnDivisions = 1;

    double currentLearnValue = _learnCardCount;
    if (currentLearnValue > maxLearnCards) currentLearnValue = maxLearnCards;
    if (currentLearnValue < minLearnCards) currentLearnValue = minLearnCards;

    int targetPctInt = (_lockoutPercentages[_lockoutIndex.toInt()] * 100).round();
    String lockoutLabel = "$targetPctInt% (min. $_requiredCorrectQuestions / ${_questionCount.toInt()})";

    final Color headerContrastColor = currentTheme.getContrastTextColor(currentTheme.testSetupColor);

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: theme.appBarTheme.elevation ?? 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          title: Text('Nastavenie Testu', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            // KARTA AKTÍVNEHO BALÍČKA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeckManagerScreen()),
                  );
                  _loadSettings();
                },
                borderRadius: currentTheme.cardBorderRadius,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: currentTheme.getCardDecoration(
                    _activeDeckId == null ? currentTheme.errorColor : currentTheme.testSetupColor,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.15),
                        child: Icon(
                          _activeDeckId == null ? Icons.warning_amber_rounded : Icons.style,
                          color: headerContrastColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activeDeckId == null 
                                  ? "NEMÁŠ VYBRANÝ ŽIADEN BALÍČEK!" 
                                  : "AKTÍVNY BALíČEK",
                              style: TextStyle(
                                color: headerContrastColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _activeDeckId == null 
                                  ? "Klikni sem pre výber (min. 5 kariet)" 
                                  : "$_activeDeckName ($_availableCardCount kariet)",
                              style: TextStyle(
                                color: headerContrastColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Zmeniť",
                            style: TextStyle(
                              color: headerContrastColor.withValues(alpha: 0.9),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, color: headerContrastColor, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildSwitchCard(
                title: 'Learning Mode',
                subtitle: _isLearningMode ? 'Zamerané na opakovanie a učenie sa.' : 'Zamerané na výkon a získavanie času.',
                multiplier: 1.0, 
                value: _isLearningMode,
                isGold: false,
                showMultiplier: false,
                currentTheme: currentTheme,
                accentColor: currentTheme.testSetupColor,
                onChanged: (val) {
                  setState(() => _isLearningMode = val);
                  _saveBool('test_isLearningMode', val);
                },
              ),
            ),

            if (!_isLearningMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: currentTheme.getCardDecoration(currentTheme.testSetupColor),
                  child: Column(
                    children: [
                      Text(
                        'ODMENA ZA 1 SPRÁVNU ODPOVEĎ', 
                        style: TextStyle(
                          color: headerContrastColor.withValues(alpha: 0.8), 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(_timePerQuestion), 
                        style: TextStyle(
                          color: headerContrastColor, 
                          fontSize: 44, 
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: currentTheme.cardBorderRadius,
                          border: Border.all(color: headerContrastColor.withValues(alpha: 0.3), width: 1.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Celkový násobič', 
                                  style: TextStyle(
                                    color: headerContrastColor.withValues(alpha: 0.8), 
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'x${_currentMultiplier.toStringAsFixed(2)}', 
                                  style: TextStyle(
                                    color: headerContrastColor, 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Max potenciál testu', 
                                  style: TextStyle(
                                    color: headerContrastColor.withValues(alpha: 0.8), 
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTime(_totalTimePotential), 
                                  style: TextStyle(
                                    color: headerContrastColor, 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Text(
                      'ZÁKLADNÉ NASTAVENIA KVÍZU', 
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6), 
                        fontSize: 13, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSliderCard(
                      title: 'Počet otázok', 
                      valueLabel: '${_questionCount.toInt()} otázok', 
                      value: _questionCount, 
                      min: minQuestions, 
                      max: maxQuestions, 
                      divisions: questionDivisions, 
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _questionCount = val); 
                        _saveDouble('test_questionCount', val); 
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSliderCard(
                      title: 'Časový limit na otázku', 
                      valueLabel: _timeLabels[_timeLimitIndex.toInt()], 
                      multiplier: _timeMultipliers[_timeLimitIndex.toInt()], 
                      value: _timeLimitIndex, 
                      min: 0, 
                      max: 5, 
                      divisions: 5, 
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _timeLimitIndex = val); 
                        _saveDouble('test_timeLimitIndex', val); 
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSliderCard(
                      title: 'Lockout Prah (Min. úspešnosť)', 
                      valueLabel: lockoutLabel, 
                      multiplier: double.parse(_effectiveLockoutMultiplier.toStringAsFixed(2)), 
                      value: _lockoutIndex, 
                      min: 0, 
                      max: 7, 
                      divisions: 7, 
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _lockoutIndex = val); 
                        _saveDouble('test_lockoutIndex', val); 
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'MODIFIKÁTORY', 
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6), 
                        fontSize: 13, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      title: '3 Možnosti', 
                      subtitle: 'O jednu nesprávnu odpoveď menej.', 
                      multiplier: 0.7, 
                      value: _is3Options, 
                      isDisabled: _isHardcore, 
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _is3Options = val); 
                        _saveBool('test_is3Options', val); 
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      title: 'Vymeň kartu', 
                      subtitle: '1-krát za test môžeš vymeniť ťažkú otázku za novú.', 
                      multiplier: 0.85, 
                      value: _isSwapQuestion, 
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _isSwapQuestion = val); 
                        _saveBool('test_isSwapQuestion', val); 
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      title: 'Druhá šanca', 
                      subtitle: 'Jedna nesprávna odpoveď za celý test sa ti odpustí.', 
                      multiplier: 0.8, 
                      value: _isSecondChance, 
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _isSecondChance = val); 
                        _saveBool('test_isSecondChance', val); 
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      title: 'Confusion', 
                      subtitle: 'Pridaná možnosť "Žiadna z odpovedí".', 
                      multiplier: 1.1, 
                      value: _isConfusion, 
                      isDisabled: _isHardcore, 
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _isConfusion = val); 
                        _saveBool('test_isConfusion', val); 
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      title: 'Slepý test', 
                      subtitle: 'Správnosť odpovedí sa dozvieš až na záver testu.', 
                      multiplier: 1.25, 
                      value: _isBlindTest, 
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _isBlindTest = val); 
                        _saveBool('test_isBlindTest', val); 
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      title: 'Double Test', 
                      subtitle: 'Musíš zvládnuť 2 testy po sebe. Odmenu dostaneš až po druhom.', 
                      multiplier: 1.75, 
                      value: _isDoubleTest, 
                      isGold: false,
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() {
                          _isDoubleTest = val;
                          _saveBool('test_isDoubleTest', val);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      title: 'Hardcore (Write-in)', 
                      subtitle: 'Bez možností. Odpoveď musíš ručne napísať.', 
                      multiplier: 1.5, 
                      value: _isHardcore, 
                      isGold: false, 
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) {
                        setState(() {
                          _isHardcore = val;
                          _saveBool('test_isHardcore', val);
                          if (_isHardcore) { 
                            _is3Options = false; 
                            _isConfusion = false; 
                            _saveBool('test_is3Options', false); 
                            _saveBool('test_isConfusion', false); 
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] 
            else ...[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Text(
                      'NASTAVENIA UČENIA', 
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6), 
                        fontSize: 13, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSliderCard(
                      title: 'Počet kartičiek v dávke',
                      valueLabel: '${currentLearnValue.toInt()} kartičiek',
                      value: currentLearnValue,
                      min: minLearnCards, 
                      max: maxLearnCards, 
                      divisions: learnDivisions,
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _learnCardCount = val); 
                        _saveDouble('test_learnCardCount', val); 
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSliderCard(
                      title: 'Frekvencia uzamknutia (Pop-up)',
                      valueLabel: () {
                      int totalSeconds = (_learnInterval * 60).round();
                      int minutes = totalSeconds ~/ 60;
                      int seconds = totalSeconds % 60;
                      
                      if (seconds == 0) {
                        return 'Každé $minutes min.';
                      } else {
                        return 'Každé $minutes min. $seconds s.';
                      }
                    }(),
                      value: _learnInterval,
                      min: 1, max: 5, divisions: 8,
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _learnInterval = val); 
                        _saveDouble('test_learnInterval', val); 
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      title: 'Opakovanie nevedomostí',
                      subtitle: 'Karty, ktoré si nevedel, sa ukážu znovu na konci.',
                      multiplier: 1.0,
                      showMultiplier: false,
                      value: _learnRepeat,
                      currentTheme: currentTheme,
                      accentColor: currentTheme.testSetupColor,
                      onChanged: (val) { 
                        setState(() => _learnRepeat = val); 
                        _saveBool('test_learnRepeat', val); 
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- POMOCNÉ WIDGETY ---
  Widget _buildMultiplierBadge(double mult, AppThemeData currentTheme) {
    if (mult == 1.0) return const SizedBox.shrink();
    bool isPositive = mult > 1.0;
    Color badgeColor = isPositive ? currentTheme.successColor : currentTheme.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: currentTheme.getCardDecoration(badgeColor),
      child: Text(
        'x$mult', 
        style: TextStyle(
          color: currentTheme.getContrastTextColor(badgeColor), 
          fontWeight: FontWeight.bold, 
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title, 
    required String valueLabel, 
    required double value, 
    required double min, 
    required double max, 
    required int divisions, 
    required ValueChanged<double> onChanged, 
    required AppThemeData currentTheme,
    required Color accentColor,
    double? multiplier,
  }) {
    final textColor = currentTheme.getContrastTextColor(accentColor);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: currentTheme.getCardDecoration(accentColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title, 
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (multiplier != null) _buildMultiplierBadge(multiplier, currentTheme),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valueLabel, 
            style: TextStyle(
              color: textColor, 
              fontWeight: FontWeight.w900, 
              fontSize: 18,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: textColor, 
              inactiveTrackColor: textColor.withValues(alpha: 0.3), 
              thumbColor: textColor, 
              trackHeight: 6.0,
            ),
            child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title, 
    required String subtitle, 
    required double multiplier, 
    required bool value, 
    required ValueChanged<bool> onChanged, 
    required AppThemeData currentTheme,
    required Color accentColor,
    bool isDisabled = false, 
    bool isGold = false, 
    bool showMultiplier = true,
  }) {
    final textColor = currentTheme.getContrastTextColor(accentColor);

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: currentTheme.getCardDecoration(accentColor),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title, 
                        style: TextStyle(
                          color: textColor, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (showMultiplier) _buildMultiplierBadge(multiplier, currentTheme),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle, 
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.8), 
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value, 
              onChanged: isDisabled ? null : onChanged, 
              activeColor: textColor,
              activeTrackColor: textColor.withValues(alpha: 0.4),
              inactiveThumbColor: textColor.withValues(alpha: 0.6),
              inactiveTrackColor: textColor.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}