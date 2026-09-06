import 'package:flutter/material.dart';

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

  // --- STAV PREMENNÝCH ---
  double _questionCount = 5;
  
  // Časový limit (Indexy: 0 = Bez limitu, 1 = 30s, 2 = 25s, 3 = 20s, 4 = 15s, 5 = 10s)
  double _timeLimitIndex = 0;
  final List<String> _timeLabels = ["Bez limitu", "30 s", "25 s", "20 s", "15 s", "10 s"];
  final List<double> _timeMultipliers = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5];

  // Lockout Prah (Indexy: 0 = 30%, ..., 7 = 100%)
  double _lockoutIndex = 2; // Default na 50%
  final List<String> _lockoutLabels = ["30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%"];
  final List<double> _lockoutMultipliers = [0.6, 0.8, 1.0, 1.1, 1.15, 1.2, 1.25, 1.35];

  // Toggles (Prepínače)
  bool _is3Options = false;
  bool _isSecondChance = false;
  bool _isConfusion = false;
  bool _isHardcore = false;

  // --- VÝPOČTY (Math Logic) ---
  double get _currentMultiplier {
    double mult = 1.0;
    mult *= _timeMultipliers[_timeLimitIndex.toInt()];
    mult *= _lockoutMultipliers[_lockoutIndex.toInt()];
    if (_is3Options && !_isHardcore) mult *= 0.7;
    if (_isSecondChance) mult *= 0.8;
    if (_isConfusion && !_isHardcore) mult *= 1.1;
    if (_isHardcore) mult *= 1.5;
    return mult;
  }

  int get _timePerQuestion {
    return (30 * _currentMultiplier).round();
  }

  int get _totalTimePotential {
    return _timePerQuestion * _questionCount.toInt();
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    if (m > 0) {
      return "${m}m ${s}s";
    }
    return "${s}s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryText),
        title: const Text(
          'Nastavenie Testu',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 1. ZAKOTVENÝ DYNAMICKÝ DASHBOARD (Hore, fixný)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: deepPurple,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: deepPurple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'ODMENA ZA 1 SPRÁVNU ODPOVEĎ',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(_timePerQuestion),
                        style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1.0),
                      ),
                    ],
                  ),
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
                            const SizedBox(height: 4),
                            Text(
                              'x${_currentMultiplier.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: _currentMultiplier >= 1.0 ? Colors.greenAccent : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Max potenciál testu', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(_totalTimePotential),
                              style: const TextStyle(color: goldAccent, fontWeight: FontWeight.bold, fontSize: 18),
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
          
          // 2. SCROLLOVATEĽNÁ ČASŤ S NASTAVENIAMI
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              physics: const BouncingScrollPhysics(),
              children: [
                const Text('ZÁKLADNÉ NASTAVENIA', style: TextStyle(color: secondaryText, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),

                // SLIDERS
                _buildSliderCard(
                  title: 'Počet otázok',
                  valueLabel: '${_questionCount.toInt()} otázok',
                  value: _questionCount,
                  min: 3,
                  max: 10,
                  divisions: 7,
                  onChanged: (val) => setState(() => _questionCount = val),
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
                  onChanged: (val) => setState(() => _timeLimitIndex = val),
                ),
                const SizedBox(height: 12),

                _buildSliderCard(
                  title: 'Lockout Prah (Min. úspešnosť)',
                  valueLabel: _lockoutLabels[_lockoutIndex.toInt()],
                  multiplier: _lockoutMultipliers[_lockoutIndex.toInt()],
                  value: _lockoutIndex,
                  min: 0,
                  max: 7,
                  divisions: 7,
                  onChanged: (val) => setState(() => _lockoutIndex = val),
                ),

                const SizedBox(height: 24),
                const Text('MODIFIKÁTORY', style: TextStyle(color: secondaryText, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),

                // TOGGLES
                _buildSwitchCard(
                  title: '3 Možnosti',
                  subtitle: 'O jednu nesprávnu odpoveď menej.',
                  multiplier: 0.7,
                  value: _is3Options,
                  isDisabled: _isHardcore,
                  onChanged: (val) => setState(() => _is3Options = val),
                ),
                const SizedBox(height: 12),

                _buildSwitchCard(
                  title: 'Druhá šanca',
                  subtitle: 'Prvá nesprávna odpoveď sa ti odpustí.',
                  multiplier: 0.8,
                  value: _isSecondChance,
                  onChanged: (val) => setState(() => _isSecondChance = val),
                ),
                const SizedBox(height: 12),

                _buildSwitchCard(
                  title: 'Confusion',
                  subtitle: 'Pridaná možnosť "Žiadna z odpovedí".',
                  multiplier: 1.1,
                  value: _isConfusion,
                  isDisabled: _isHardcore,
                  onChanged: (val) => setState(() => _isConfusion = val),
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
                      if (_isHardcore) {
                        // Hardcore logika - vypne nezlučiteľné módy
                        _is3Options = false;
                        _isConfusion = false;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- POMOCNÉ WIDGETY ---

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
    );
  }

  Widget _buildMultiplierBadge(double mult) {
    if (mult == 1.0) return const SizedBox.shrink(); // Nezobrazovať x1.0
    bool isPositive = mult > 1.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive ? positiveGreen.withOpacity(0.15) : negativeRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'x$mult',
        style: TextStyle(
          color: isPositive ? positiveGreen : negativeRed,
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
    double? multiplier,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: _cardDecoration(),
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
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: deepPurple,
              inactiveTrackColor: bgColor,
              thumbColor: deepPurple,
              overlayColor: deepPurple.withOpacity(0.2),
              trackHeight: 6.0,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
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
    bool isDisabled = false,
    bool isGold = false,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: _cardDecoration().copyWith(
          border: isGold && value ? Border.all(color: goldAccent, width: 2) : null,
        ),
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
                      _buildMultiplierBadge(multiplier),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: secondaryText, fontSize: 13)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: isDisabled ? null : onChanged,
              activeColor: isGold ? goldAccent : deepPurple,
            ),
          ],
        ),
      ),
    );
  }
}