import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class QuizOverlayScreen extends StatefulWidget {
  final int? practiceDeckId; 
  const QuizOverlayScreen({super.key, this.practiceDeckId});

  @override
  State<QuizOverlayScreen> createState() => _QuizOverlayScreenState();
}

class _QuizOverlayScreenState extends State<QuizOverlayScreen> {
  // --- STAV TESTU ---
  bool _isLoading = true;
  bool _isTestFinished = false;
  Map<String, dynamic>? _currentQuestion;
  List<String> _currentOptions = [];
  String _actualCorrectAnswer = "";

  int _currentQuestionIndex = 0;
  int _correctAnswersCount = 0;

  // --- STAV ODPOVEDE (Pre UI Feedback) ---
  bool _isAnswerChecked = false; // Zámok počas čakania 2 sekúnd
  String? _selectedAnswer; // Uloží si, na čo používateľ klikol
  bool _hideCorrectAnswer = false; // Použijeme pri "Druhej šanci", aby nevidel správnu odpoveď pred 2. pokusom
  
  // --- NASTAVENIA Z PAMÄTE ---
  int? _activeDeckId;
  bool _isVibrationEnabled = true;
  double _questionCount = 5;
  double _timeLimitIndex = 0;
  double _lockoutIndex = 2;
  bool _is3Options = false;
  bool _isSecondChance = false;
  bool _isConfusion = false;
  bool _isHardcore = false;

  bool _usedSecondChanceThisQuestion = false;

  // --- ČASOVAČ ---
  Timer? _timer;
  int _timeLeft = 0;
  int _maxTime = 0;

  // --- HARDCORE ---
  final TextEditingController _hardcoreController = TextEditingController();

  // Tabuľky hodnôt 
  final List<int> _timeLimitsInSeconds = [0, 30, 25, 20, 15, 10];
  final List<double> _timeMultipliers = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5];
  final List<double> _lockoutThresholds = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
  final List<double> _lockoutMultipliers = [0.6, 0.8, 1.0, 1.1, 1.15, 1.2, 1.25, 1.35];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndStart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hardcoreController.dispose();
    super.dispose();
  }

  // 1. NAČÍTANIE NASTAVENÍ
  Future<void> _loadSettingsAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _questionCount = prefs.getDouble('test_questionCount') ?? 5;
      _timeLimitIndex = prefs.getDouble('test_timeLimitIndex') ?? 0;
      _lockoutIndex = prefs.getDouble('test_lockoutIndex') ?? 2;
      
      _isHardcore = prefs.getBool('test_isHardcore') ?? false;
      _is3Options = _isHardcore ? false : (prefs.getBool('test_is3Options') ?? false);
      _isConfusion = _isHardcore ? false : (prefs.getBool('test_isConfusion') ?? false);
      _isSecondChance = prefs.getBool('test_isSecondChance') ?? false;

      _activeDeckId = widget.practiceDeckId ?? prefs.getInt('active_test_deck_id'); 
      _maxTime = _timeLimitsInSeconds[_timeLimitIndex.toInt()];
    });

    _loadNextQuestion();
  }

  // 2. NAČÍTANIE OTÁZKY 
  Future<void> _loadNextQuestion() async {
    _timer?.cancel();
    setState(() {
      _isLoading = true;
      _usedSecondChanceThisQuestion = false;
      _isAnswerChecked = false;
      _selectedAnswer = null;
      _hideCorrectAnswer = false;
      _hardcoreController.clear();
    });

    final questionData = await DatabaseHelper.instance.getRandomQuizQuestion(deckId: _activeDeckId);
    
    if (questionData == null) {
      setState(() {
        _currentQuestion = null;
        _isLoading = false;
      });
      return;
    }

    String correct = questionData['correct_answer'].toString();
    List<String> options = List<String>.from(questionData['options']);

    if (!_isHardcore) {
      if (_isConfusion) {
        bool isNoneCorrect = Random().nextDouble() < 0.4;
        if (isNoneCorrect) {
          options.remove(correct);
          options.add("Žiadna z odpovedí");
          correct = "Žiadna z odpovedí";
        } else {
          String wrongOpt = options.firstWhere((opt) => opt != correct);
          options.remove(wrongOpt);
          options.add("Žiadna z odpovedí");
        }
      }

      if (_is3Options && !_isConfusion) {
        List<String> wrongOptions = options.where((opt) => opt != correct).toList();
        wrongOptions.shuffle();
        options = [correct, wrongOptions[0], wrongOptions[1]];
      }

      options.shuffle();
    }

    setState(() {
      _currentQuestion = questionData;
      _currentOptions = options;
      _actualCorrectAnswer = correct;
      _isLoading = false;
      
      if (_maxTime > 0) {
        _timeLeft = _maxTime;
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        _checkAnswer(""); // Vypršal čas = prázdna odpoveď (Fail)
      }
    });
  }

  // 3. KONTROLA ODPOVEDE (S Feedbackom)
  void _checkAnswer(String selectedOption) async {
    // Ak už čakáme na ďalšiu otázku, ignorujeme ďalšie kliky
    if (_isAnswerChecked) return; 

    _timer?.cancel();
    bool isCorrect = false;

    setState(() {
      _isAnswerChecked = true; // Zapneme UI spätnú väzbu
    });

    if (_isHardcore) {
      String typed = _hardcoreController.text.trim().toLowerCase();
      String expected = _actualCorrectAnswer.trim().toLowerCase();
      isCorrect = (typed == expected) && typed.isNotEmpty;
      setState(() => _selectedAnswer = typed);
    } else {
      isCorrect = (selectedOption == _actualCorrectAnswer);
      setState(() => _selectedAnswer = selectedOption);
    }

    if (isCorrect) {
      _correctAnswersCount++;
      // Čakáme 2 sekundy predtým, než ideme ďalej
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _proceedToNext();
      
    } else {
      // Nesprávna odpoveď
      if (_isVibrationEnabled) HapticFeedback.vibrate();

      if (_isSecondChance && !_usedSecondChanceThisQuestion) {
        setState(() {
          _usedSecondChanceThisQuestion = true;
          _hideCorrectAnswer = true; // Zatajíme mu správnu odpoveď pre 2. pokus
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Druhá šanca použitá! Skús to znova.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          )
        );

        // Pri druhej šanci počkáme len 1.5 sekundy (aby videl, že klikol zle) a odomkneme
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;

        setState(() {
          _isAnswerChecked = false;
          _selectedAnswer = null;
          _hideCorrectAnswer = false;
          _hardcoreController.clear();
        });

        if (_maxTime > 0 && _timeLeft > 0) _startTimer();
      } else {
        // Normálna chyba (Bez 2. šance)
        setState(() => _hideCorrectAnswer = false); // Ukážeme mu zelenú správnu odpoveď
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        _proceedToNext();
      }
    }
  }

  void _proceedToNext() {
    _currentQuestionIndex++;
    if (_currentQuestionIndex >= _questionCount.toInt()) {
      setState(() => _isTestFinished = true);
    } else {
      _loadNextQuestion();
    }
  }

  // 4. VÝPOČET ODMENY A ODOMKNUTIE
  void _finishTestAndUnlock() async {
    double mult = 1.0;
    mult *= _timeMultipliers[_timeLimitIndex.toInt()];
    mult *= _lockoutMultipliers[_lockoutIndex.toInt()];
    if (_is3Options && !_isHardcore) mult *= 0.7;
    if (_isSecondChance) mult *= 0.8;
    if (_isConfusion && !_isHardcore) mult *= 1.1;
    if (_isHardcore) mult *= 1.5;

    double successRate = _correctAnswersCount / _questionCount;
    double requiredRate = _lockoutThresholds[_lockoutIndex.toInt()];

    int earnedSeconds = 0;
    if (successRate >= requiredRate) {
      earnedSeconds = (_correctAnswersCount * 30 * mult).round();
    }

    if (earnedSeconds > 0 && widget.practiceDeckId == null) {
      const platform = MethodChannel('brainlock.channel');
      try {
        await platform.invokeMethod('unlockApp', {'seconds': earnedSeconds});
      } catch (e) {
        print("Chyba pri odomykaní: $e");
      }
      SystemNavigator.pop(); 
    } else {
      Navigator.pop(context); 
    }
  }

  // --- VIZUÁL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.deepPurple)));
    }

    if (_currentQuestion == null) {
      return const Text("Žiadne kartičky v databáze!", textAlign: TextAlign.center, style: TextStyle(fontSize: 16));
    }

    // A. ZOBRAZENIE VÝSLEDKOV (Koniec testu)
    if (_isTestFinished) {
      double successRate = _correctAnswersCount / _questionCount;
      double requiredRate = _lockoutThresholds[_lockoutIndex.toInt()];
      bool isSuccess = successRate >= requiredRate;

      double mult = 1.0;
      mult *= _timeMultipliers[_timeLimitIndex.toInt()];
      mult *= _lockoutMultipliers[_lockoutIndex.toInt()];
      if (_is3Options && !_isHardcore) mult *= 0.7;
      if (_isSecondChance) mult *= 0.8;
      if (_isConfusion && !_isHardcore) mult *= 1.1;
      if (_isHardcore) mult *= 1.5;
      
      int earnedSeconds = isSuccess ? (_correctAnswersCount * 30 * mult).round() : 0;
      int m = earnedSeconds ~/ 60;
      int s = earnedSeconds % 60;
      
      bool isPractice = widget.practiceDeckId != null;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSuccess ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded, 
               size: 60, color: isSuccess ? Colors.amber : Colors.grey),
          const SizedBox(height: 16),
          const Text("Test Dokončený!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 16),
          Text("Úspešnosť: $_correctAnswersCount / ${_questionCount.toInt()} (${(successRate * 100).toInt()}%)", style: const TextStyle(fontSize: 16)),
          Text("Lockout Prah: ${(requiredRate * 100).toInt()}%", style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12)
            ),
            child: Text(
              isSuccess ? "Získaný čas: ${m}m ${s}s" : "Nesplnil si podmienku pre zisk času.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSuccess ? Colors.green.shade700 : Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
          ),
          if (isPractice)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text("(Tréningový mód - čas nebol pripísaný)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _finishTestAndUnlock,
            child: Text(isSuccess && !isPractice ? "Odomknúť aplikácie" : "Zatvoriť test"),
          ),
        ],
      );
    }

    // --- FARBY A FEEDBACK PRE HARDCORE MÓD ---
    Color hardcoreFillCol = Colors.grey.shade100;
    Color hardcoreBorderCol = Colors.transparent;
    Widget? hardcoreFeedbackWidget;

    if (_isHardcore && _isAnswerChecked) {
      String typed = _selectedAnswer ?? "";
      String expected = _actualCorrectAnswer.trim().toLowerCase();
      
      if (typed == expected && typed.isNotEmpty) {
        hardcoreFillCol = Colors.green.shade50;
        hardcoreBorderCol = Colors.green;
        hardcoreFeedbackWidget = const Text("Výborne!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
      } else {
        hardcoreFillCol = Colors.red.shade50;
        hardcoreBorderCol = Colors.red;
        if (!_hideCorrectAnswer) {
          hardcoreFeedbackWidget = Text("Odpoveď bola: $_actualCorrectAnswer", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
        }
      }
    }

    // B. ZOBRAZENIE OTÁZKY
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Otázka ${_currentQuestionIndex + 1} z ${_questionCount.toInt()}", 
                 style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
            if (_maxTime > 0)
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: _timeLeft <= 5 ? Colors.red : Colors.deepPurple),
                  const SizedBox(width: 4),
                  Text("$_timeLeft s", style: TextStyle(fontWeight: FontWeight.bold, color: _timeLeft <= 5 ? Colors.red : Colors.deepPurple)),
                ],
              )
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: (_currentQuestionIndex) / _questionCount,
          backgroundColor: Colors.grey.shade200,
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 24),
        
        if (_currentQuestion!['prompt'].toString().endsWith('.svg')) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SvgPicture.asset(_currentQuestion!['prompt'], height: 110, fit: BoxFit.contain),
          ),
        ] else ...[
          Text(
            _currentQuestion!['prompt'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ],
        
        const SizedBox(height: 32),
        
        // Možnosti (HARDCORE vs KLASIKA)
        if (_isHardcore) ...[
          TextField(
            controller: _hardcoreController,
            textAlign: TextAlign.center,
            enabled: !_isAnswerChecked, // Zamkne pole počas čakania
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "Napíš odpoveď sem...",
              filled: true,
              fillColor: hardcoreFillCol,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hardcoreBorderCol, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hardcoreBorderCol, width: 2)),
            ),
            onSubmitted: (_) => _checkAnswer(""), 
          ),
          if (hardcoreFeedbackWidget != null) ...[
            const SizedBox(height: 8),
            hardcoreFeedbackWidget,
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: _isAnswerChecked ? Colors.grey : Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isAnswerChecked ? () {} : () => _checkAnswer(""),
            child: const Text("Potvrdiť", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ] else ...[
          ..._currentOptions.map((option) {
            
            // LOGIKA PRE FARBY TLAČIDIEL
            Color btnColor = Colors.deepPurple.shade50;
            Color textColor = Colors.deepPurple;
            BorderSide borderSide = BorderSide.none;

            if (_isAnswerChecked) {
              if (option == _actualCorrectAnswer && !_hideCorrectAnswer) {
                // Toto je správna odpoveď (a nezatajujeme ju) -> Zelená
                btnColor = Colors.green.shade50;
                textColor = Colors.green.shade800;
                borderSide = const BorderSide(color: Colors.green, width: 2);
              } else if (option == _selectedAnswer) {
                // Toto je zlá odpoveď, ktorú si zaklikol -> Červená
                btnColor = Colors.red.shade50;
                textColor = Colors.red.shade800;
                borderSide = const BorderSide(color: Colors.red, width: 2);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: btnColor,
                  foregroundColor: textColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: borderSide),
                ),
                onPressed: _isAnswerChecked ? () {} : () => _checkAnswer(option), // Zamkne po kliknutí
                child: Text(option, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ),
            );
          }),
        ],
      ],
    );
  }
}