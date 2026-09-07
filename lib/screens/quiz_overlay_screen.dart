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
  bool _isLoading = true;
  bool _isTestFinished = false;
  
  // --- SPOLOČNÉ NASTAVENIA ---
  int? _activeDeckId;
  bool _isVibrationEnabled = true;
  bool _isLearningMode = false;

  // --- STAV PRE KLASICKÝ KVÍZ ---
  Map<String, dynamic>? _currentQuestion;
  List<String> _currentOptions = [];
  String _actualCorrectAnswer = "";
  int _currentQuestionIndex = 0;
  int _correctAnswersCount = 0;
  bool _isAnswerChecked = false;
  String? _selectedAnswer; 
  bool _hideCorrectAnswer = false; 
  
  double _questionCount = 5;
  double _timeLimitIndex = 0;
  double _lockoutIndex = 2;
  bool _is3Options = false;
  bool _isSecondChance = false;
  bool _isConfusion = false;
  bool _isHardcore = false;
  bool _usedSecondChanceThisQuestion = false;

  Timer? _timer;
  int _timeLeft = 0;
  int _maxTime = 0;
  final TextEditingController _hardcoreController = TextEditingController();

  final List<int> _timeLimitsInSeconds = [0, 30, 25, 20, 15, 10];
  final List<double> _timeMultipliers = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5];
  final List<double> _lockoutThresholds = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
  final List<double> _lockoutMultipliers = [0.6, 0.8, 1.0, 1.1, 1.15, 1.2, 1.25, 1.35];

  // --- STAV PRE LEARNING MODE ---
  List<Map<String, dynamic>> _learningCardsQueue = [];
  List<Map<String, dynamic>> _failedCards = [];
  int _learningRound = 1;
  bool _isCardFlipped = false;
  double _learnCardCount = 10;
  double _learnInterval = 1;
  bool _learnRepeat = true;
  int _totalLearnedCards = 0;
  int _masteredCount = 0; // Pridané pre zelené počítadlo v Quizlet štýle

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

  Future<void> _loadSettingsAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _activeDeckId = widget.practiceDeckId ?? prefs.getInt('active_test_deck_id'); 
      _isLearningMode = prefs.getBool('test_isLearningMode') ?? false;

      if (_isLearningMode) {
        _learnCardCount = prefs.getDouble('test_learnCardCount') ?? 10;
        _learnInterval = prefs.getDouble('test_learnInterval') ?? 1;
        _learnRepeat = prefs.getBool('test_learnRepeat') ?? true;
      } else {
        _questionCount = prefs.getDouble('test_questionCount') ?? 5;
        _timeLimitIndex = prefs.getDouble('test_timeLimitIndex') ?? 0;
        _lockoutIndex = prefs.getDouble('test_lockoutIndex') ?? 2;
        _isHardcore = prefs.getBool('test_isHardcore') ?? false;
        _is3Options = _isHardcore ? false : (prefs.getBool('test_is3Options') ?? false);
        _isConfusion = _isHardcore ? false : (prefs.getBool('test_isConfusion') ?? false);
        _isSecondChance = prefs.getBool('test_isSecondChance') ?? false;
        _maxTime = _timeLimitsInSeconds[_timeLimitIndex.toInt()];
      }
    });

    if (_isLearningMode) {
      _startLearningMode();
    } else {
      _loadNextQuizQuestion();
    }
  }

  // ==========================================
  //         LOGIKA PRE LEARNING MODE
  // ==========================================

  Future<void> _startLearningMode() async {
    setState(() => _isLoading = true);
    final cards = await DatabaseHelper.instance.getLearningCards(_learnCardCount.toInt(), deckId: _activeDeckId);
    
    setState(() {
      // Dôležité: Vytvárame upraviteľnú kópiu zoznamu
      _learningCardsQueue = List<Map<String, dynamic>>.from(cards);
      _totalLearnedCards = _learningCardsQueue.length;
      _failedCards.clear();
      _masteredCount = 0;
      _learningRound = 1;
      _isCardFlipped = false;
      _isLoading = false;
      if (_learningCardsQueue.isEmpty) _isTestFinished = true;
    });
  }

  void _handleLearningAnswer(bool knewIt) {
    setState(() {
      if (_learningCardsQueue.isEmpty) return;

      final card = _learningCardsQueue.removeAt(0);
      
      if (knewIt) {
        _masteredCount++; // Úspešne zvládnutá karta
      } else if (_learnRepeat) {
        _failedCards.add(card); // Odložíme do zlej kôpky na ďalšie kolo
      }

      // Ak sme došli na koniec aktuálnej kôpky
      if (_learningCardsQueue.isEmpty) {
        if (_failedCards.isNotEmpty) {
          // Začíname ďalšie kolo s kartami, ktoré nevedel
          _learningCardsQueue = List.from(_failedCards);
          _learningCardsQueue.shuffle();
          _totalLearnedCards = _learningCardsQueue.length; // Upravíme počet pre nové kolo
          _failedCards.clear();
          _learningRound++;
        } else {
          _isTestFinished = true; // Všetko zvládol!
        }
      }
      
      _isCardFlipped = false; // Ďalšia karta je zase otázkou hore
    });
  }


  // ==========================================
  //         LOGIKA PRE KLASICKÝ KVÍZ
  // ==========================================

  Future<void> _loadNextQuizQuestion() async {
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
      setState(() { _currentQuestion = null; _isLoading = false; });
      return;
    }

    String correct = questionData['correct_answer'].toString();
    List<String> options = List<String>.from(questionData['options']);

    if (!_isHardcore) {
      if (_isConfusion) {
        bool isNoneCorrect = Random().nextDouble() < 0.4;
        if (isNoneCorrect) {
          options.remove(correct); options.add("Žiadna z odpovedí"); correct = "Žiadna z odpovedí";
        } else {
          String wrongOpt = options.firstWhere((opt) => opt != correct);
          options.remove(wrongOpt); options.add("Žiadna z odpovedí");
        }
      }
      if (_is3Options && !_isConfusion) {
        List<String> wrongOptions = options.where((opt) => opt != correct).toList();
        wrongOptions.shuffle(); options = [correct, wrongOptions[0], wrongOptions[1]];
      }
      options.shuffle();
    }

    setState(() {
      _currentQuestion = questionData;
      _currentOptions = options;
      _actualCorrectAnswer = correct;
      _isLoading = false;
      if (_maxTime > 0) { _timeLeft = _maxTime; _startTimer(); }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        _checkQuizAnswer(""); 
      }
    });
  }

  void _checkQuizAnswer(String selectedOption) async {
    if (_isAnswerChecked) return; 
    _timer?.cancel();
    bool isCorrect = false;

    setState(() => _isAnswerChecked = true);

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
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _proceedToNextQuiz();
    } else {
      if (_isVibrationEnabled) HapticFeedback.vibrate();

      if (_isSecondChance && !_usedSecondChanceThisQuestion) {
        setState(() { _usedSecondChanceThisQuestion = true; _hideCorrectAnswer = true; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Druhá šanca! Skús znova.'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)));
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        setState(() { _isAnswerChecked = false; _selectedAnswer = null; _hideCorrectAnswer = false; _hardcoreController.clear(); });
        if (_maxTime > 0 && _timeLeft > 0) _startTimer();
      } else {
        setState(() => _hideCorrectAnswer = false); 
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        _proceedToNextQuiz();
      }
    }
  }

  void _proceedToNextQuiz() {
    _currentQuestionIndex++;
    if (_currentQuestionIndex >= _questionCount.toInt()) {
      setState(() => _isTestFinished = true);
    } else {
      _loadNextQuizQuestion();
    }
  }

  void _finishAndUnlock() async {
    // Ak je to Learning Mode
    if (_isLearningMode) {
      if (widget.practiceDeckId == null) {
        // Nie je to tréning = pošleme odomykací príkaz do Androidu!
        int earnedSeconds = (_learnInterval * 60).round(); // Minúty na sekundy
        const platform = MethodChannel('brainlock.channel');
        try { 
          await platform.invokeMethod('unlockApp', {'seconds': earnedSeconds}); 
        } catch (e) { 
          print("Chyba pri odomykaní: $e"); 
        }
        SystemNavigator.pop(); // Zavrie test a pustí ťa do appky
      } else {
        // Je to len tréning v appke, vrátime sa späť do menu
        Navigator.pop(context);
      }
      return; // Tu končíme, aby sa nespúšťala logika kvízu nižšie
    }

    // Klasický Kvíz logika
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
      try { await platform.invokeMethod('unlockApp', {'seconds': earnedSeconds}); } catch (e) { print("Chyba: $e"); }
      SystemNavigator.pop(); 
    } else {
      Navigator.pop(context); 
    }
  }


  // ==========================================
  //                   UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)]),
            child: _isLoading 
                ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.deepPurple))) 
                : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isTestFinished) {
      return _buildFinishedScreen();
    }
    
    if (_isLearningMode) {
      if (_learningCardsQueue.isEmpty) return const Text("Žiadne kartičky v databáze!");
      return _buildLearningUI();
    } else {
      if (_currentQuestion == null) return const Text("Žiadne kartičky v databáze!");
      return _buildQuizUI();
    }
  }

  Widget _buildFinishedScreen() {
    if (_isLearningMode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.school_rounded, size: 60, color: Colors.green),
          const SizedBox(height: 16),
          const Text("Učenie dokončené!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 16),
          const Text("Prešiel si všetky kartičky z balíčka.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _finishAndUnlock,
            child: const Text("Zatvoriť"),
          ),
        ],
      );
    }

    // Klasický test finished screen
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
        Icon(isSuccess ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded, size: 60, color: isSuccess ? Colors.amber : Colors.grey),
        const SizedBox(height: 16),
        const Text("Test Dokončený!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 16),
        Text("Úspešnosť: $_correctAnswersCount / ${_questionCount.toInt()} (${(successRate * 100).toInt()}%)", style: const TextStyle(fontSize: 16)),
        Text("Lockout Prah: ${(requiredRate * 100).toInt()}%", style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isSuccess ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
          child: Text(isSuccess ? "Získaný čas: ${m}m ${s}s" : "Nesplnil si podmienku pre zisk času.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSuccess ? Colors.green.shade700 : Colors.red.shade700), textAlign: TextAlign.center),
        ),
        if (isPractice) const Padding(padding: EdgeInsets.only(top: 8.0), child: Text("(Tréningový mód - čas nebol pripísaný)", style: TextStyle(fontSize: 12, color: Colors.grey))),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _finishAndUnlock,
          child: Text(isSuccess && !isPractice ? "Odomknúť aplikácie" : "Zatvoriť test"),
        ),
      ],
    );
  }

  // --- LEARNING UI (QUIZLET ŠTÝL) ---
  Widget _buildLearningUI() {
    final card = _learningCardsQueue.first;
    int currentIndex = _totalLearnedCards - _learningCardsQueue.length + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QUIZLET TOP COUNTERS (Znova | Progres | Viem)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Oranžový obdĺžnik vľavo (Ešte sa učím)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text("${_failedCards.length}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            // Progres v strede
            Column(
              children: [
                Text("$currentIndex / $_totalLearnedCards", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16)),
                if (_learningRound > 1) 
                  Text("Kolo $_learningRound", style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            // Zelený obdĺžnik vpravo (Už to viem)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text("$_masteredCount", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: currentIndex / _totalLearnedCards,
          backgroundColor: Colors.grey.shade200,
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 24),

        // OBROVSKÁ KARTIČKA (Swipe a Tap)
        Dismissible(
          key: ValueKey('${card['id']}_$_learningRound'),
          // Swipovať dovoľujeme až keď je karta otočená!
          direction: _isCardFlipped ? DismissDirection.horizontal : DismissDirection.none,
          onDismissed: (direction) {
            // startToEnd je Swipe Doprava (VIEM TO -> true)
            _handleLearningAnswer(direction == DismissDirection.startToEnd);
          },
          // POZADIE PRI SWIPOVANÍ DOPRAVA (VIEM)
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.green, width: 2)),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check, color: Colors.green, size: 50),
                SizedBox(height: 8),
                Text("VIEM", style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // POZADIE PRI SWIPOVANÍ DOĽAVA (ZNOVA)
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.orange, width: 2)),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.close, color: Colors.orange, size: 50),
                SizedBox(height: 8),
                Text("ZNOVA", style: TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() => _isCardFlipped = !_isCardFlipped);
              if (_isVibrationEnabled) HapticFeedback.selectionClick();
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: _isCardFlipped
                  ? _buildCardBack(card)
                  : _buildCardFront(card),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // KRÁSNE TLAČIDLÁ (Iba ak je karta otočená)
        AnimatedOpacity(
          opacity: _isCardFlipped ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16), 
                    backgroundColor: Colors.orange.shade50, 
                    foregroundColor: Colors.orange, 
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.orange.shade200, width: 1.5))
                  ),
                  // False = Pôjde do nevedomostí
                  onPressed: _isCardFlipped ? () => _handleLearningAnswer(false) : null,
                  icon: const Icon(Icons.close),
                  label: const Text("Znova", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16), 
                    backgroundColor: Colors.green.shade50, 
                    foregroundColor: Colors.green.shade800, 
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.green.shade300, width: 1.5))
                  ),
                  // True = Správna odpoveď
                  onPressed: _isCardFlipped ? () => _handleLearningAnswer(true) : null,
                  icon: const Icon(Icons.check),
                  label: const Text("Viem", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- DIZAJN PREDNEJ STRANY KARTY ---
  Widget _buildCardFront(Map<String, dynamic> card) {
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.40, // Výška prispôsobená pre vizuál veľkej kartičky
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.deepPurple.shade100, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card['prompt'].toString().endsWith('.svg'))
            SvgPicture.asset(card['prompt'], height: 100, fit: BoxFit.contain)
          else
            Text(card['prompt'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, color: Colors.black87, fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 40),
          const Text("Ťukni pre otočenie", style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  // --- DIZAJN ZADNEJ STRANY KARTY (S ODPOVEĎOU) ---
  Widget _buildCardBack(Map<String, dynamic> card) {
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.40,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.deepPurple, width: 2),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.15), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card['prompt'].toString().endsWith('.svg'))
            SvgPicture.asset(card['prompt'], height: 60, fit: BoxFit.contain)
          else
            Text(card['prompt'], textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.deepPurple.shade300, fontWeight: FontWeight.w600)),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(color: Colors.deepPurple, thickness: 1)),
          
          Text(card['correct_answer'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, color: Colors.deepPurple, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  // --- QUIZ UI (Starý dobrý kvíz so spätnou väzbou) ---
  Widget _buildQuizUI() {
    Color hardcoreFillCol = Colors.grey.shade100;
    Color hardcoreBorderCol = Colors.transparent;
    Widget? hardcoreFeedbackWidget;

    if (_isHardcore && _isAnswerChecked) {
      String typed = _selectedAnswer ?? "";
      String expected = _actualCorrectAnswer.trim().toLowerCase();
      if (typed == expected && typed.isNotEmpty) {
        hardcoreFillCol = Colors.green.shade50; hardcoreBorderCol = Colors.green;
        hardcoreFeedbackWidget = const Text("Výborne!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
      } else {
        hardcoreFillCol = Colors.red.shade50; hardcoreBorderCol = Colors.red;
        if (!_hideCorrectAnswer) hardcoreFeedbackWidget = Text("Odpoveď bola: $_actualCorrectAnswer", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Otázka ${_currentQuestionIndex + 1} z ${_questionCount.toInt()}", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
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
        LinearProgressIndicator(value: (_currentQuestionIndex) / _questionCount, backgroundColor: Colors.grey.shade200, color: Colors.deepPurple),
        const SizedBox(height: 24),
        
        if (_currentQuestion!['prompt'].toString().endsWith('.svg'))
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SvgPicture.asset(_currentQuestion!['prompt'], height: 110, fit: BoxFit.contain))
        else
          Text(_currentQuestion!['prompt'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.bold)),
        
        const SizedBox(height: 32),
        
        if (_isHardcore) ...[
          TextField(
            controller: _hardcoreController,
            textAlign: TextAlign.center,
            enabled: !_isAnswerChecked, 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "Napíš odpoveď sem...",
              filled: true, fillColor: hardcoreFillCol,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hardcoreBorderCol, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hardcoreBorderCol, width: 2)),
            ),
            onSubmitted: (_) => _checkQuizAnswer(""), 
          ),
          if (hardcoreFeedbackWidget != null) ...[const SizedBox(height: 8), hardcoreFeedbackWidget],
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: _isAnswerChecked ? Colors.grey : Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _isAnswerChecked ? () {} : () => _checkQuizAnswer(""),
            child: const Text("Potvrdiť", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ] else ...[
          ..._currentOptions.map((option) {
            Color btnColor = Colors.deepPurple.shade50;
            Color textColor = Colors.deepPurple;
            BorderSide borderSide = BorderSide.none;

            if (_isAnswerChecked) {
              if (option == _actualCorrectAnswer && !_hideCorrectAnswer) {
                btnColor = Colors.green.shade50; textColor = Colors.green.shade800; borderSide = const BorderSide(color: Colors.green, width: 2);
              } else if (option == _selectedAnswer) {
                btnColor = Colors.red.shade50; textColor = Colors.red.shade800; borderSide = const BorderSide(color: Colors.red, width: 2);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55), backgroundColor: btnColor, foregroundColor: textColor, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: borderSide),
                ),
                onPressed: _isAnswerChecked ? () {} : () => _checkQuizAnswer(option),
                child: Text(option, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ),
            );
          }),
        ],
      ],
    );
  }
}