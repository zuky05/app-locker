import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';
import 'deck_manager_screen.dart';
import '../themes/themed_background.dart';
import '../services/languages.dart';

class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({super.key});

  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  SharedPreferences? _prefs;
  bool _isLoading = true;
  int? _activeDeckId;
  String _activeDeckName = "...";
  int _availableCardCount = 10;
  String _currentLanguageCode = 'sk';

  // --- STAV PRE KVÍZ ---
  double _questionCount = 10;
  double _timeLimitIndex = 0;
  
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
    _currentLanguageCode = _prefs!.getString('app_language') ?? 'sk';
    
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

  int get _requiredCorrectQuestions {
    double targetPct = _lockoutPercentages[_lockoutIndex.toInt()];
    return (targetPct * _questionCount).round();
  }

  double get _effectiveLockoutMultiplier {
    double targetPct = _lockoutPercentages[_lockoutIndex.toInt()];
    double mult = 1.0 + (targetPct - 0.5);
    if (mult < 0.6) return 0.6;
    if (mult > 1.5) return 1.5;
    return mult;
  }

  final List<double> _timeMultipliers = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5];

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

  Widget _buildSectionHeader(String title, bool isNeo, bool isSoft, bool isCyber, ThemeData theme, Color accentColor) {
    if (isCyber) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: UnconstrainedBox(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '// $title',
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isNeo ? Colors.black : (isSoft ? const Color(0xFF718096) : theme.colorScheme.onSurface.withValues(alpha: 0.85)), 
          fontSize: 12, 
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final Color accentColor = currentTheme.decksColor;

    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isCyber = currentTheme.id == 0;

    final AppTexts texts = _currentLanguageCode == 'en' ? textsEn : textsSk;

    final List<String> timeLabels = [texts.timeLabelNoLimit, "30 s", "25 s", "20 s", "15 s", "10 s"];

    if (_isLoading) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent, 
          body: Center(child: CircularProgressIndicator(color: accentColor)),
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
    String lockoutLabel = texts.lockoutLabelFormat(targetPctInt, _requiredCorrectQuestions, _questionCount.toInt());

    final Color headerContrastColor = isNeo 
        ? Colors.black 
        : (isSoft ? const Color(0xFF2D3748) : currentTheme.getContrastTextColor(accentColor));

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: theme.appBarTheme.elevation ?? 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: isNeo ? Colors.black : theme.colorScheme.onSurface),
          title: Text(
            texts.testSetupScreenTitle, 
            style: TextStyle(
              color: isNeo ? Colors.black : theme.colorScheme.onSurface, 
              fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
              fontFamily: isCyber ? 'monospace' : null,
              fontSize: 20,
            ),
          ),
        ),
        body: Column(
          children: [
            // KARTA AKTÍVNEHO BALÍČKA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                    _activeDeckId == null ? currentTheme.errorColor : accentColor,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSoft
                            ? const Color(0xFFC8D3E6)
                            : (isNeo ? Colors.black : Colors.black.withValues(alpha: 0.15)),
                        child: Icon(
                          _activeDeckId == null ? Icons.warning_amber_rounded : Icons.style,
                          color: isSoft
                              ? accentColor
                              : (isNeo ? Colors.white : headerContrastColor),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activeDeckId == null 
                                  ? texts.noDeckSelectedTitle 
                                  : texts.activeDeckLabel,
                              style: TextStyle(
                                color: isNeo 
                                    ? Colors.black 
                                    : (isSoft ? const Color(0xFF718096) : headerContrastColor.withValues(alpha: 0.7)),
                                fontWeight: FontWeight.bold,
                                fontFamily: isCyber ? 'monospace' : null,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _activeDeckId == null 
                                  ? texts.noDeckSelectedSubtitle 
                                  : "$_activeDeckName (${texts.deckCardCount(_availableCardCount)})",
                              style: TextStyle(
                                color: headerContrastColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: isCyber ? 'monospace' : null,
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
                            texts.btnChangeDeck,
                            style: TextStyle(
                              color: isNeo 
                                  ? Colors.black 
                                  : (isSoft ? accentColor : headerContrastColor.withValues(alpha: 0.9)),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded, 
                            color: isNeo 
                                ? Colors.black 
                                : (isSoft ? accentColor : headerContrastColor), 
                            size: 13,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: _buildSwitchCard(
                title: texts.learningModeTitle,
                subtitle: _isLearningMode ? texts.learningModeSubOn : texts.learningModeSubOff,
                multiplier: 1.0, 
                value: _isLearningMode,
                isGold: false,
                showMultiplier: false,
                currentTheme: currentTheme,
                accentColor: accentColor,
                isCyber: isCyber,
                onChanged: (val) {
                  setState(() => _isLearningMode = val);
                  _saveBool('test_isLearningMode', val);
                },
              ),
            ),

            if (!_isLearningMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: currentTheme.getCardDecoration(accentColor),
                  child: Column(
                    children: [
                      Text(
                        texts.rewardPerQuestionLabel, 
                        style: TextStyle(
                          color: isNeo 
                              ? Colors.black 
                              : (isSoft ? const Color(0xFF718096) : headerContrastColor.withValues(alpha: 0.8)), 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          fontFamily: isCyber ? 'monospace' : null,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(_timePerQuestion), 
                        style: TextStyle(
                          color: headerContrastColor, 
                          fontSize: 42, 
                          fontFamily: isCyber ? 'monospace' : null,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: isSoft
                            ? BoxDecoration(
                                color: const Color(0xFFC8D3E6),
                                borderRadius: currentTheme.cardBorderRadius,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF97A7C0),
                                    offset: Offset(3, 3),
                                    blurRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: Colors.white,
                                    offset: Offset(-3, -3),
                                    blurRadius: 6,
                                  ),
                                ],
                              )
                            : BoxDecoration(
                                color: isNeo ? Colors.white : Colors.black.withValues(alpha: 0.2),
                                borderRadius: currentTheme.cardBorderRadius,
                                border: Border.all(
                                  color: isNeo ? Colors.black : (isCyber ? accentColor.withValues(alpha: 0.3) : headerContrastColor.withValues(alpha: 0.3)), 
                                  width: isNeo ? 2.5 : 1.0,
                                ),
                                boxShadow: isNeo ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2))] : null,
                              ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  texts.totalMultiplierLabel, 
                                  style: TextStyle(
                                    color: isNeo 
                                        ? Colors.black87 
                                        : (isSoft ? const Color(0xFF718096) : headerContrastColor.withValues(alpha: 0.8)), 
                                    fontSize: 11,
                                    fontFamily: isCyber ? 'monospace' : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'x${_currentMultiplier.toStringAsFixed(2)}', 
                                  style: TextStyle(
                                    color: headerContrastColor, 
                                    fontWeight: FontWeight.w900, 
                                    fontFamily: isCyber ? 'monospace' : null,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  texts.maxPotentialLabel, 
                                  style: TextStyle(
                                    color: isNeo 
                                        ? Colors.black87 
                                        : (isSoft ? const Color(0xFF718096) : headerContrastColor.withValues(alpha: 0.8)), 
                                    fontSize: 11,
                                    fontFamily: isCyber ? 'monospace' : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTime(_totalTimePotential), 
                                  style: TextStyle(
                                    color: headerContrastColor, 
                                    fontWeight: FontWeight.w900, 
                                    fontFamily: isCyber ? 'monospace' : null,
                                    fontSize: 17,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSectionHeader(texts.sectionBasicSettings, isNeo, isSoft, isCyber, theme, accentColor),
                    _buildSliderCard(
                      title: texts.fieldQuestionCount, 
                      valueLabel: texts.questionCountValue(_questionCount.toInt()), 
                      value: _questionCount, 
                      min: minQuestions, 
                      max: maxQuestions, 
                      divisions: questionDivisions, 
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() => _questionCount = val); 
                        _saveDouble('test_questionCount', val); 
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSliderCard(
                      title: texts.fieldTimeLimit, 
                      valueLabel: timeLabels[_timeLimitIndex.toInt()], 
                      multiplier: _timeMultipliers[_timeLimitIndex.toInt()], 
                      value: _timeLimitIndex, 
                      min: 0, 
                      max: 5, 
                      divisions: 5, 
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() => _timeLimitIndex = val); 
                        _saveDouble('test_timeLimitIndex', val); 
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSliderCard(
                      title: texts.fieldLockoutThreshold, 
                      valueLabel: lockoutLabel, 
                      multiplier: double.parse(_effectiveLockoutMultiplier.toStringAsFixed(2)), 
                      value: _lockoutIndex, 
                      min: 0, 
                      max: 7, 
                      divisions: 7, 
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() => _lockoutIndex = val); 
                        _saveDouble('test_lockoutIndex', val); 
                      },
                    ),
                    _buildSectionHeader(texts.sectionModifiers, isNeo, isSoft, isCyber, theme, accentColor),
                    _buildSwitchCard(
                      title: texts.mod3OptionsTitle, 
                      subtitle: texts.mod3OptionsSub, 
                      multiplier: 0.7, 
                      value: _is3Options, 
                      isDisabled: _isHardcore, 
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() => _is3Options = val); 
                        _saveBool('test_is3Options', val); 
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSwitchCard(
                      title: texts.modSwapCardTitle, 
                      subtitle: texts.modSwapCardSub, 
                      multiplier: 0.85, 
                      value: _isSwapQuestion, 
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() => _isSwapQuestion = val); 
                        _saveBool('test_isSwapQuestion', val); 
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSwitchCard(
                      title: texts.modSecondChanceTitle, 
                      subtitle: texts.modSecondChanceSub, 
                      multiplier: 0.8, 
                      value: _isSecondChance, 
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() => _isSecondChance = val); 
                        _saveBool('test_isSecondChance', val); 
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSwitchCard(
                      title: texts.modConfusionTitle, 
                      subtitle: texts.modConfusionSub, 
                      multiplier: 1.1, 
                      value: _isConfusion, 
                      isDisabled: _isHardcore, 
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() => _isConfusion = val); 
                        _saveBool('test_isConfusion', val); 
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSwitchCard(
                      title: texts.modBlindTestTitle, 
                      subtitle: texts.modBlindTestSub, 
                      multiplier: 1.25, 
                      value: _isBlindTest, 
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() => _isBlindTest = val); 
                        _saveBool('test_isBlindTest', val); 
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSwitchCard(
                      title: texts.modDoubleTestTitle, 
                      subtitle: texts.modDoubleTestSub, 
                      multiplier: 1.75, 
                      value: _isDoubleTest, 
                      isGold: false,
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() {
                          _isDoubleTest = val;
                          _saveBool('test_isDoubleTest', val);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSwitchCard(
                      title: texts.modHardcoreTitle, 
                      subtitle: texts.modHardcoreSub, 
                      multiplier: 1.5, 
                      value: _isHardcore, 
                      isGold: false, 
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSectionHeader(texts.sectionLearnSettings, isNeo, isSoft, isCyber, theme, accentColor),
                    _buildSliderCard(
                      title: texts.learnBatchSizeTitle,
                      valueLabel: texts.learnBatchSizeValue(currentLearnValue.toInt()),
                      value: currentLearnValue,
                      min: minLearnCards, 
                      max: maxLearnCards, 
                      divisions: learnDivisions,
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() => _learnCardCount = val); 
                        _saveDouble('test_learnCardCount', val); 
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSliderCard(
                      title: texts.learnIntervalTitle,
                      valueLabel: () {
                        int totalSeconds = (_learnInterval * 60).round();
                        int minutes = totalSeconds ~/ 60;
                        int seconds = totalSeconds % 60;
                        return texts.learnIntervalValue(minutes, seconds);
                      }(),
                      value: _learnInterval,
                      min: 1, max: 5, divisions: 8,
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
                      onChanged: (val) { 
                        setState(() => _learnInterval = val); 
                        _saveDouble('test_learnInterval', val); 
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSwitchCard(
                      title: texts.learnRepeatTitle,
                      subtitle: texts.learnRepeatSub,
                      multiplier: 1.0,
                      showMultiplier: false,
                      value: _learnRepeat,
                      currentTheme: currentTheme,
                      accentColor: accentColor,
                      isCyber: isCyber,
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

  Widget _buildMultiplierBadge(double mult, AppThemeData currentTheme, bool isCyber) {
    if (mult == 1.0) return const SizedBox.shrink();
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    bool isPositive = mult > 1.0;
    Color badgeColor = isPositive ? currentTheme.successColor : currentTheme.errorColor;

    if (isCyber) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.18),
          border: Border.all(color: badgeColor, width: 1.0),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          'x$mult', 
          style: TextStyle(
            color: badgeColor, 
            fontWeight: FontWeight.bold, 
            fontFamily: 'monospace',
            fontSize: 11,
          ),
        ),
      );
    }

    if (isSoft) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFC8D3E6),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0xFF97A7C0), offset: Offset(2, 2), blurRadius: 4),
            BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
          ],
        ),
        child: Text(
          'x$mult', 
          style: TextStyle(
            color: badgeColor, 
            fontWeight: FontWeight.w900, 
            fontSize: 12,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: isNeo 
          ? BoxDecoration(
              color: badgeColor,
              borderRadius: currentTheme.buttonBorderRadius,
              border: Border.all(color: Colors.black, width: 2.0),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
            ) 
          : currentTheme.getCardDecoration(badgeColor),
      child: Text(
        'x$mult', 
        style: TextStyle(
          color: isNeo ? Colors.black : currentTheme.getContrastTextColor(badgeColor), 
          fontWeight: FontWeight.w900, 
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
    required bool isCyber,
    double? multiplier,
  }) {
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final textColor = isSoft 
        ? const Color(0xFF2D3748) 
        : (isNeo ? Colors.black : currentTheme.getContrastTextColor(accentColor));

    final Color activeTrack = isCyber ? const Color(0xFF00FF66) : (isSoft ? accentColor : textColor);
    final Color inactiveTrack = isCyber ? accentColor.withValues(alpha: 0.25) : (isSoft ? const Color(0xFFB0C0D6) : textColor.withValues(alpha: 0.3));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: currentTheme.getCardDecoration(accentColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title, 
                style: TextStyle(
                  color: textColor, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 15,
                ),
              ),
              if (multiplier != null) _buildMultiplierBadge(multiplier, currentTheme, isCyber),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valueLabel, 
            style: TextStyle(
              color: textColor, 
              fontWeight: FontWeight.bold, 
              fontFamily: isCyber ? 'monospace' : null,
              fontSize: 16,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeTrack, 
              inactiveTrackColor: inactiveTrack, 
              thumbColor: activeTrack, 
              disabledThumbColor: isSoft ? const Color(0xFF97A7C0) : textColor.withValues(alpha: 0.5),
              disabledActiveTrackColor: isSoft ? accentColor.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.3),
              disabledInactiveTrackColor: isSoft ? const Color(0xFFC8D3E6) : textColor.withValues(alpha: 0.2),
              trackHeight: isCyber ? 4.0 : (isSoft ? 8.0 : (isNeo ? 8.0 : 6.0)),
              thumbShape: isSoft ? const RoundSliderThumbShape(enabledThumbRadius: 10.0, elevation: 4) : (isCyber ? const RoundSliderThumbShape(enabledThumbRadius: 8.0) : null),
            ),
            child: Slider(
              value: value, 
              min: min, 
              max: max, 
              divisions: divisions, 
              onChanged: min == max ? null : onChanged,
            ),
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
    required bool isCyber,
    bool isDisabled = false, 
    bool isGold = false, 
    bool showMultiplier = true,
  }) {
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final textColor = isSoft 
        ? const Color(0xFF2D3748) 
        : (isNeo ? Colors.black : currentTheme.getContrastTextColor(accentColor));

    return Opacity(
      opacity: isDisabled ? 0.75 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (showMultiplier) _buildMultiplierBadge(multiplier, currentTheme, isCyber),
                      if (isDisabled && isCyber) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.redAccent, width: 0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'LOCKED',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 9,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: TextStyle(
                      color: isNeo 
                          ? Colors.black87 
                          : (isSoft ? const Color(0xFF718096) : textColor.withValues(alpha: 0.8)), 
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value, 
              onChanged: isDisabled ? null : onChanged, 
              trackOutlineColor: WidgetStateProperty.all(isCyber ? accentColor.withValues(alpha: isDisabled ? 0.25 : 0.5) : Colors.transparent),
              activeColor: isCyber ? const Color(0xFF00FF66) : (isNeo ? Colors.black : (isSoft ? Colors.white : textColor)),
              activeTrackColor: isCyber ? accentColor.withValues(alpha: 0.35) : (isNeo ? Colors.white : (isSoft ? accentColor : textColor.withValues(alpha: 0.4))),
              inactiveThumbColor: isCyber ? (isDisabled ? Colors.grey.shade400 : Colors.grey.shade600) : (isNeo ? Colors.black54 : (isSoft ? const Color(0xFF97A7C0) : textColor.withValues(alpha: 0.6))),
              inactiveTrackColor: isCyber ? (isDisabled ? Colors.black87 : Colors.black54) : (isNeo ? Colors.white54 : (isSoft ? const Color(0xFFC8D3E6) : textColor.withValues(alpha: 0.2))),
            ),
          ],
        ),
      ),
    );
  }
}