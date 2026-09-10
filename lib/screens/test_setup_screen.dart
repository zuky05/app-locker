import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'deck_manager_screen.dart';

class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({super.key});

  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  // --- FAREBNÁ PALETA ---
  static const Color bgColor = Color(0xFFEBE8E0);
  static const Color cardColor = Colors.white;
  static const Color primaryText = Color(0xFF2C2241);
  static const Color secondaryText = Color(0xFF7D7789);
  static const Color deepPurple = Color(0xFF352655);
  static const Color goldAccent = Color(0xFFD4A034);
  static const Color positiveGreen = Color(0xFF268B6C);
  static const Color negativeRed = Color(0xFFD66943);

  SharedPreferences? _prefs;
  bool _isLoading = true;
  int? _activeDeckId;
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
  bool _isConfusion = false;
  bool _isHardcore = false;
  bool _isDoubleTest = false; // <-- Nový modifikátor pre Double Test

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
      final cardCount = await DatabaseHelper.instance.getCardCountForDeck(activeDeckId);
      if (cardCount >= 5) {
        _availableCardCount = cardCount;
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
      _isConfusion = _prefs!.getBool('test_isConfusion') ?? false;
      _isHardcore = _prefs!.getBool('test_isHardcore') ?? false;
      _isDoubleTest = _prefs!.getBool('test_isDoubleTest') ?? false; // Načítanie stavu

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

  double get _effectiveLockoutMultiplier {
    double realRatio = _requiredCorrectQuestions / _questionCount;
    
    // 50% -> 1.0x | 100% -> 1.5x
    double mult = 1.0 + (realRatio - 0.5);
    
    if (mult < 0.6) return 0.6;
    if (mult > 1.5) return 1.5;
    
    return mult;
  }

  double get _currentMultiplier {
    double mult = 1.0;
    mult *= _timeMultipliers[_timeLimitIndex.toInt()];
    mult *= _effectiveLockoutMultiplier;
    if (_is3Options && !_isHardcore) mult *= 0.7;
    if (_isSecondChance) mult *= 0.8;
    if (_isConfusion && !_isHardcore) mult *= 1.1;
    if (_isHardcore) mult *= 1.5;
    if (_isDoubleTest) mult *= 1.75; // <-- Zapracovaný Double Test násobič
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
    if (_isLoading) {
      return const Scaffold(backgroundColor: bgColor, body: Center(child: CircularProgressIndicator(color: deepPurple)));
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryText),
        title: const Text('Nastavenie Testu', style: TextStyle(color: primaryText, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          if (_activeDeckId == null)
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
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: negativeRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: negativeRed, width: 1.5),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: negativeRed, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nemáš vybraný žiadny balíček!",
                              style: TextStyle(color: negativeRed, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Klikni sem pre výber aktívneho balíčka (min. 5 kariet).",
                              style: TextStyle(color: primaryText, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: negativeRed, size: 16),
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
              isGold: true,
              showMultiplier: false,
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
                decoration: BoxDecoration(color: deepPurple, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    const Text('ODMENA ZA 1 SPRÁVNU ODPOVEĎ', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(_formatTime(_timePerQuestion), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Celkový násobič', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('x${_currentMultiplier.toStringAsFixed(2)}', style: TextStyle(color: _currentMultiplier >= 1.0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Max potenciál testu', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(_formatTime(_totalTimePotential), style: const TextStyle(color: goldAccent, fontWeight: FontWeight.bold, fontSize: 18)),
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
                  const Text('ZÁKLADNÉ NASTAVENIA KVÍZU', style: TextStyle(color: secondaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSliderCard(
                    title: 'Počet otázok', 
                    valueLabel: '${_questionCount.toInt()} otázok', 
                    value: _questionCount, 
                    min: minQuestions, 
                    max: maxQuestions, 
                    divisions: questionDivisions, 
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
                    onChanged: (val) { 
                      setState(() => _lockoutIndex = val); 
                      _saveDouble('test_lockoutIndex', val); 
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('MODIFIKÁTORY', style: TextStyle(color: secondaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSwitchCard(
                    title: '3 Možnosti', 
                    subtitle: 'O jednu nesprávnu odpoveď menej.', 
                    multiplier: 0.7, 
                    value: _is3Options, 
                    isDisabled: _isHardcore, 
                    onChanged: (val) { 
                      setState(() => _is3Options = val); 
                      _saveBool('test_is3Options', val); 
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchCard(
                    title: 'Druhá šanca', 
                    subtitle: 'Prvá nesprávna odpoveď sa ti odpustí.', 
                    multiplier: 0.8, 
                    value: _isSecondChance, 
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
                    onChanged: (val) { 
                      setState(() => _isConfusion = val); 
                      _saveBool('test_isConfusion', val); 
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchCard(
                    title: 'Double Test', 
                    subtitle: 'Musíš zvládnuť 2 testy po sebe. Odmenu dostaneš až po druhom.', 
                    multiplier: 1.75, 
                    value: _isDoubleTest, 
                    isGold: true,
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
                    isGold: true, 
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
                  const Text('NASTAVENIA UČENIA', style: TextStyle(color: secondaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSliderCard(
                    title: 'Počet kartičiek v dávke',
                    valueLabel: '${currentLearnValue.toInt()} kartičiek',
                    value: currentLearnValue,
                    min: minLearnCards, 
                    max: maxLearnCards, 
                    divisions: learnDivisions,
                    onChanged: (val) { 
                      setState(() => _learnCardCount = val); 
                      _saveDouble('test_learnCardCount', val); 
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSliderCard(
                    title: 'Frekvencia uzamknutia (Pop-up)',
                    valueLabel: 'Každé ${_learnInterval.toInt()} min.',
                    value: _learnInterval,
                    min: 1, max: 5, divisions: 4,
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
    );
  }

  // --- POMOCNÉ WIDGETY ---
  Widget _buildMultiplierBadge(double mult) {
    if (mult == 1.0) return const SizedBox.shrink();
    bool isPositive = mult > 1.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: isPositive ? positiveGreen.withOpacity(0.15) : negativeRed.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text('x$mult', style: TextStyle(color: isPositive ? positiveGreen : negativeRed, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildSliderCard({required String title, required String valueLabel, required double value, required double min, required double max, required int divisions, required ValueChanged<double> onChanged, double? multiplier}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
              if (multiplier != null) _buildMultiplierBadge(multiplier),
            ],
          ),
          const SizedBox(height: 12),
          Text(valueLabel, style: const TextStyle(color: deepPurple, fontWeight: FontWeight.bold, fontSize: 18)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: deepPurple, inactiveTrackColor: bgColor, thumbColor: deepPurple, trackHeight: 6.0),
            child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({required String title, required String subtitle, required double multiplier, required bool value, required ValueChanged<bool> onChanged, bool isDisabled = false, bool isGold = false, bool showMultiplier = true}) {
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: isGold && value ? Border.all(color: goldAccent, width: 2) : null, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(color: isGold ? goldAccent : primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      if (showMultiplier) _buildMultiplierBadge(multiplier),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: secondaryText, fontSize: 13)),
                ],
              ),
            ),
            Switch(value: value, onChanged: isDisabled ? null : onChanged, activeColor: isGold ? goldAccent : deepPurple),
          ],
        ),
      ),
    );
  }
}