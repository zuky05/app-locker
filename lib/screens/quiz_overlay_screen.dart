import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';
import '../services/stats_provider.dart';
import '../services/daily_challenge_service.dart';

class QuizOverlayScreen extends StatefulWidget {
  final int? practiceDeckId; 
  final bool isFromNotification;

  const QuizOverlayScreen({
    super.key, 
    this.practiceDeckId,
    this.isFromNotification = false,
  });

  @override
  State<QuizOverlayScreen> createState() => _QuizOverlayScreenState();
}

class _QuizOverlayScreenState extends State<QuizOverlayScreen> {
  bool _isLoading = true;
  bool _isTestFinished = false;
  final List<int> _excludedCardIds = [];
  final Stopwatch _sessionStopwatch = Stopwatch();
  
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
  bool _isSwapQuestion = false;
  bool _hasUsedSwap = false;
  bool _isConfusion = false;
  bool _isBlindTest = false;
  bool _isHardcore = false;
  bool _isDoubleTest = false;
  int _currentTestRound = 1;
  bool _usedSecondChanceThisQuestion = false;

  // --- STAV PRE OPRAVNÝ/TRESTNÝ REŽIM (REMEDIAL) ---
  bool _isRemedialLearning = false;
  bool _isRemedialQuiz = false;
  List<Map<String, dynamic>> _remedialPool = [];
  List<Map<String, dynamic>> _remedialQuizQuestions = [];

  Timer? _timer;
  int _timeLeft = 0;
  int _maxTime = 0;
  final TextEditingController _hardcoreController = TextEditingController();

  final List<int> _timeLimitsInSeconds = [0, 30, 25, 20, 15, 10];
  final List<double> _timeMultipliers = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5];
  final List<double> _lockoutPercentages = [0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00];

  // --- STAV PRE LEARNING MODE ---
  List<Map<String, dynamic>> _learningCardsQueue = [];
  final List<Map<String, dynamic>> _failedCards = [];
  int _learningRound = 1;
  bool _isCardFlipped = false;
  double _learnCardCount = 10;
  double _learnInterval = 1;
  bool _learnRepeat = true;
  int _totalLearnedCards = 0;
  int _masteredCount = 0;

  @override
  void initState() {
    super.initState();
    _sessionStopwatch.start();
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
        _isSwapQuestion = prefs.getBool('test_isSwapQuestion') ?? false;
        _isBlindTest = prefs.getBool('test_isBlindTest') ?? false;
        _isDoubleTest = prefs.getBool('test_isDoubleTest') ?? false;
        _maxTime = _timeLimitsInSeconds[_timeLimitIndex.toInt()];
      }
    });

    if (_isLearningMode) {
      _startLearningMode();
    } else {
      _loadNextQuizQuestion();
    }
  }

  int get _requiredCorrectQuestions {
    if (_isRemedialQuiz) {
      return (_questionCount * 0.8).ceil();
    }
    double targetPct = _lockoutPercentages[_lockoutIndex.toInt()];
    return (targetPct * _questionCount).round();
  }

  double get _effectiveLockoutMultiplier {
    double realRatio = _requiredCorrectQuestions / _questionCount;
    double mult = 1.0 + (realRatio - 0.5);
    if (mult < 0.6) return 0.6;
    if (mult > 1.5) return 1.5;
    return mult;
  }

  double get _calculatedTotalMultiplier {
    if (_isRemedialQuiz) return 1.0;

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

  Future<int> _reportDailyChallengeProgress() async {
    int totalChallengeBonus = 0;
    if (_isLearningMode) {
      if (_masteredCount > 0) {
        totalChallengeBonus += await DailyChallengeService.reportProgress(
          type: ChallengeType.learnCards,
          amount: _masteredCount,
        );
      }
    } else {
      bool isSuccess = _correctAnswersCount >= _requiredCorrectQuestions;
      if (isSuccess && !_isRemedialQuiz) {
        double accuracy = _correctAnswersCount / _questionCount;
        double mult = _calculatedTotalMultiplier;
        int earnedSeconds = (_correctAnswersCount * 30 * mult).round();

        totalChallengeBonus += await DailyChallengeService.reportProgress(
          type: ChallengeType.completeQuizzes,
          accuracy: accuracy,
          is3Options: _is3Options,
          isSwapQuestion: _isSwapQuestion,
          isSecondChance: _isSecondChance,
          isConfusion: _isConfusion,
          isBlindTest: _isBlindTest,
          isDoubleTest: _isDoubleTest,
          isHardcore: _isHardcore,
        );

        if (earnedSeconds > 0) {
          totalChallengeBonus += await DailyChallengeService.reportProgress(
            type: ChallengeType.earnMinutes,
            amount: earnedSeconds,
          );
        }
      }
    }
    return totalChallengeBonus;
  }

  Future<void> _startRemedialLearning() async {
    setState(() => _isLoading = true);
    
    final cards = await DatabaseHelper.instance.getLearningCards(
      20, 
      deckId: _activeDeckId,
      excludeCardIds: [],
    );

    setState(() {
      _remedialPool = List<Map<String, dynamic>>.from(cards);
      _learningCardsQueue = List<Map<String, dynamic>>.from(cards);
      _totalLearnedCards = _learningCardsQueue.length;
      _failedCards.clear();
      _masteredCount = 0;
      _learningRound = 1;
      _isCardFlipped = false;
      
      _isRemedialLearning = true;
      _isLoading = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Test zlyhal! Zopakuj si kartičky a absolvuj opravný test (min. 80 %)."),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _startRemedialQuiz() {
    setState(() {
      _isRemedialLearning = false;
      _isRemedialQuiz = true;
      _isLoading = true;

      _is3Options = false;
      _isConfusion = false;
      _isHardcore = false;
      _isSecondChance = false;
      _isSwapQuestion = false;
      _isBlindTest = false;
      _isDoubleTest = false;
    });

    _remedialPool.shuffle();
    _remedialQuizQuestions = _remedialPool.take(5).toList();

    setState(() {
      _questionCount = _remedialQuizQuestions.length.toDouble();
      _currentQuestionIndex = 0;
      _correctAnswersCount = 0;
      _excludedCardIds.clear();
    });

    _loadNextRemedialQuizQuestion();
  }

  void _loadNextRemedialQuizQuestion() {
    _timer?.cancel();
    setState(() {
      _isLoading = true;
      _usedSecondChanceThisQuestion = false;
      _isAnswerChecked = false;
      _selectedAnswer = null;
      _hideCorrectAnswer = false;
      _hardcoreController.clear();
    });

    if (_currentQuestionIndex >= _remedialQuizQuestions.length) {
      setState(() => _isTestFinished = true);
      return;
    }

    final questionData = _remedialQuizQuestions[_currentQuestionIndex];
    String correct = (questionData['correct_answer'] ?? questionData['prompt'] ?? "").toString();

    List<String> options = [correct];
    var otherCards = List<Map<String, dynamic>>.from(_remedialPool)..shuffle();
    for (var c in otherCards) {
      String wrong = (c['correct_answer'] ?? c['prompt'] ?? "").toString();
      if (wrong != correct && !options.contains(wrong) && options.length < 4) {
        options.add(wrong);
      }
    }
    options.shuffle();

    setState(() {
      _currentQuestion = questionData;
      _currentOptions = options;
      _actualCorrectAnswer = correct;
      _isLoading = false;
      if (_maxTime > 0) { _timeLeft = _maxTime; _startTimer(); }
    });
  }

  Future<void> _startLearningMode() async {
    setState(() => _isLoading = true);
    
    final List<int> excludedLearningIds = [];
    final cards = await DatabaseHelper.instance.getLearningCards(
      _learnCardCount.toInt(), 
      deckId: _activeDeckId,
      excludeCardIds: excludedLearningIds,
    );
    
    setState(() {
      _learningCardsQueue = List<Map<String, dynamic>>.from(cards);
      for (var card in cards) {
        if (card['id'] != null) excludedLearningIds.add(card['id'] as int);
      }

      _totalLearnedCards = _learningCardsQueue.length;
      _failedCards.clear();
      _masteredCount = 0;
      _learningRound = 1;
      _isCardFlipped = false;
      _isLoading = false;
      _isTestFinished = _learningCardsQueue.isEmpty;
    });
  }

  void _handleLearningAnswer(bool knewIt) {
    setState(() {
      if (_learningCardsQueue.isEmpty) return;

      final card = _learningCardsQueue.removeAt(0);
      
      if (knewIt) {
        if (_learningRound == 1) {
          _masteredCount++;
        }
      } else {
        if (card['id'] != null) {
          DatabaseHelper.instance.incrementCardWrongCount(card['id'] as int);
        }
        if (_learnRepeat || _isRemedialLearning) {
          _failedCards.add(card);
        }
      }

      if (_learningCardsQueue.isEmpty) {
        if (_failedCards.isNotEmpty) {
          _learningCardsQueue = List.from(_failedCards);
          _learningCardsQueue.shuffle();
          _failedCards.clear();
          _learningRound++;
        } else {
          if (_isRemedialLearning) {
            _startRemedialQuiz();
          } else {
            _isTestFinished = true;
          }
        }
      }
      
      _isCardFlipped = false;
    });
  }

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

    var questionData = await DatabaseHelper.instance.getRandomQuizQuestion(
      deckId: _activeDeckId, 
      excludeCardIds: _excludedCardIds,
    );
    
    if (questionData == null && _excludedCardIds.isNotEmpty) {
      _excludedCardIds.clear();
      questionData = await DatabaseHelper.instance.getRandomQuizQuestion(
        deckId: _activeDeckId, 
        excludeCardIds: _excludedCardIds,
      );
    }

    if (questionData == null) {
      setState(() { _currentQuestion = null; _isLoading = false; });
      return;
    }

    if (questionData['id'] != null) {
      _excludedCardIds.add(questionData['id'] as int);
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

  Future<void> _swapCurrentQuestion() async {
    if (_hasUsedSwap || _isAnswerChecked) return;
    _timer?.cancel();
    setState(() {
      _isLoading = true;
      _hasUsedSwap = true;
      _hardcoreController.clear();
    });

    var questionData = await DatabaseHelper.instance.getRandomQuizQuestion(
      deckId: _activeDeckId,
      excludeCardIds: _excludedCardIds,
    );

    if (questionData == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (questionData['id'] != null) {
      _excludedCardIds.add(questionData['id'] as int);
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

    if (_isBlindTest) {
      if (isCorrect) {
        _correctAnswersCount++;
      } else {
        if (_currentQuestion != null && _currentQuestion!['id'] != null) {
          DatabaseHelper.instance.incrementCardWrongCount(_currentQuestion!['id'] as int);
        }
      }
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _proceedToNextQuiz();
      return;
    }

    if (isCorrect) {
      _correctAnswersCount++;
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _proceedToNextQuiz();
    } else {
      if (_currentQuestion != null && _currentQuestion!['id'] != null) {
        DatabaseHelper.instance.incrementCardWrongCount(_currentQuestion!['id'] as int);
      }

      if (_isVibrationEnabled) HapticFeedback.vibrate();

      if (_isSecondChance && !_usedSecondChanceThisQuestion) {
        setState(() { _usedSecondChanceThisQuestion = true; _hideCorrectAnswer = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Druhá šanca! Skús znova.'), backgroundColor: Colors.orange, duration: Duration(seconds: 2))
        );
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

  void _triggerFailureVibration() {
    if (_isVibrationEnabled) {
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.vibrate());
    }
  }

  void _proceedToNextQuiz() {
    _currentQuestionIndex++;
    int totalQuestions = _questionCount.toInt();
    int remainingQuestions = totalQuestions - _currentQuestionIndex;
    int maxPossibleCorrect = _correctAnswersCount + remainingQuestions;

    if (_currentQuestionIndex >= totalQuestions) {
      bool passed = _correctAnswersCount >= _requiredCorrectQuestions;

      if (_isDoubleTest && _currentTestRound == 1 && passed && !_isRemedialQuiz) {
        setState(() {
          _currentTestRound = 2;
          _currentQuestionIndex = 0;
          _correctAnswersCount = 0;
          _hasUsedSwap = false;
          _excludedCardIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("1. kolo zvládnuté! Teraz dokonči 2. kolo."), backgroundColor: Colors.orange, duration: Duration(seconds: 3)),
        );
        _loadNextQuizQuestion();
      } 
      else if (!passed && !_isRemedialQuiz) {
        _triggerFailureVibration();
        _startRemedialLearning();
      } 
      else {
        if (!passed) _triggerFailureVibration();
        setState(() => _isTestFinished = true);
      }
    } 
    else if (maxPossibleCorrect < _requiredCorrectQuestions) {
      _triggerFailureVibration();
      if (!_isRemedialQuiz) {
        _startRemedialLearning();
      } else {
        setState(() => _isTestFinished = true);
      }
    } 
    else {
      if (_isRemedialQuiz) {
        _loadNextRemedialQuizQuestion();
      } else {
        _loadNextQuizQuestion();
      }
    }
  }

  void _closeOrExitScreen() {
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else {
        SystemNavigator.pop();
      }
    }
  }

  void _finishAndUnlock() async {
    _sessionStopwatch.stop();
    int actualStudyTimeSeconds = _sessionStopwatch.elapsed.inSeconds;
    if (actualStudyTimeSeconds < 1) actualStudyTimeSeconds = 1;

    int challengeBonusSeconds = await _reportDailyChallengeProgress();

    // Získame farbu z aktuálnej témy pre systémovú notifikáciu
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    int themeColorValue = currentTheme.testSetupColor.toARGB32();

    if (widget.practiceDeckId != null) {
      int earnedSecondsForPractice = 0;
      if (!_isLearningMode) {
        bool isSuccess = _correctAnswersCount >= _requiredCorrectQuestions;
        if (isSuccess) {
          double mult = _calculatedTotalMultiplier;
          earnedSecondsForPractice = (_correctAnswersCount * 30 * mult).round();
        }
      } else {
        earnedSecondsForPractice = (_learnInterval * 60).round();
      }

      await DatabaseHelper.instance.insertStudySession(
        deckId: _activeDeckId ?? 0,
        durationSeconds: actualStudyTimeSeconds,
        earnedSeconds: earnedSecondsForPractice + challengeBonusSeconds,
        correctCount: _isLearningMode ? _masteredCount : _correctAnswersCount,
        totalQuestions: _isLearningMode ? (_totalLearnedCards > 0 ? _totalLearnedCards : 1) : _questionCount.toInt(),
      );

      if (mounted) {
        Provider.of<StatsProvider>(context, listen: false).refreshStats();
      }

      _closeOrExitScreen();
      return;
    }

    if (_isLearningMode) {
      int earnedSeconds = (_learnInterval * 60).round();
      int totalEarned = earnedSeconds + challengeBonusSeconds;
      int actualAddedSeconds = 0;

      const platform = MethodChannel('brainlock.channel');
      try { 
        final dynamic result = await platform.invokeMethod('unlockApp', {
          'seconds': totalEarned, 
          'maxCap': totalEarned,
          'isFromNotification': widget.isFromNotification,
          'themeColor': themeColorValue,
        }); 

        if (result is int) {
          actualAddedSeconds = result;
        } else {
          actualAddedSeconds = totalEarned;
        }
      } catch (e) { 
        debugPrint("Chyba pri odomykaní: $e"); 
        actualAddedSeconds = totalEarned;
      }

      await DatabaseHelper.instance.insertStudySession(
        deckId: _activeDeckId ?? 0,
        durationSeconds: actualStudyTimeSeconds,
        earnedSeconds: actualAddedSeconds,
        correctCount: _masteredCount,
        totalQuestions: _totalLearnedCards > 0 ? _totalLearnedCards : 1,
      );

      if (mounted) {
        Provider.of<StatsProvider>(context, listen: false).refreshStats();
      }

      SystemNavigator.pop();
      return;
    }

    double mult = _calculatedTotalMultiplier;
    bool isSuccess = _correctAnswersCount >= _requiredCorrectQuestions;

    int quizEarnedSeconds = 0;
    if (isSuccess) {
      quizEarnedSeconds = (_correctAnswersCount * 30 * mult).round();
    }
    
    int totalEarnedWithChallenge = quizEarnedSeconds + challengeBonusSeconds;
    int maxCapSeconds = (_questionCount * 30 * mult).round() + challengeBonusSeconds; 
    int actualAddedSeconds = 0;

    // 🟢 Voláme unlockApp VŽDY (aj pri 0 sekundách), aby sa nastavila ochranná lehota (grace period) a test nevyskakoval dookola
    const platform = MethodChannel('brainlock.channel');
    try { 
      final dynamic result = await platform.invokeMethod('unlockApp', {
        'seconds': totalEarnedWithChallenge, 
        'maxCap': maxCapSeconds,
        'isFromNotification': widget.isFromNotification,
        'themeColor': themeColorValue,
      }); 

      if (result is int) {
        actualAddedSeconds = result;
      } else {
        actualAddedSeconds = totalEarnedWithChallenge;
      }
    } catch (e) { 
      debugPrint("Chyba: $e"); 
      actualAddedSeconds = totalEarnedWithChallenge;
    }

    await DatabaseHelper.instance.insertStudySession(
      deckId: _activeDeckId ?? 0,
      durationSeconds: actualStudyTimeSeconds,
      earnedSeconds: actualAddedSeconds,
      correctCount: _correctAnswersCount,
      totalQuestions: _questionCount.toInt(),
    );

    if (mounted) {
      Provider.of<StatsProvider>(context, listen: false).refreshStats();
    }
    
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPractice = widget.practiceDeckId != null;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    return Scaffold(
      backgroundColor: isPractice 
          ? theme.scaffoldBackgroundColor 
          : Colors.black.withValues(alpha: 0.3),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: currentTheme.cardBorderRadius,
                  border: currentTheme.id == 2 
                      ? Border.all(color: Colors.black, width: 3.5) 
                      : (currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                  boxShadow: currentTheme.id == 2 
                      ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4))] 
                      : const [BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 2)],
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: currentTheme.cardBorderRadius,
                    gradient: currentTheme.id == 2 ? null : currentTheme.cardGradient,
                  ),
                  child: _isLoading 
                      ? SizedBox(
                          height: 200, 
                          child: Center(
                            child: CircularProgressIndicator(color: theme.colorScheme.primary),
                          ),
                        ) 
                      : _buildContent(currentTheme),
                ),
              ),

              if (isPractice) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _closeOrExitScreen,
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                  label: const Text(
                    "Zrušiť test", 
                    style: TextStyle(
                      color: Colors.white70, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                    ),
                  ),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppThemeData currentTheme) {
    if (_isTestFinished) return _buildFinishedScreen(currentTheme);
    
    if (_isLearningMode || _isRemedialLearning) {
      if (_learningCardsQueue.isEmpty) {
        return Text(
          "Žiadne kartičky v databáze!", 
          style: TextStyle(color: currentTheme.theme.colorScheme.onSurface),
        );
      }
      return _buildLearningUI(currentTheme);
    } else {
      if (_currentQuestion == null) {
        return Text(
          "Žiadne kartičky v databáze!",
          style: TextStyle(color: currentTheme.theme.colorScheme.onSurface),
        );
      }
      return _buildQuizUI(currentTheme);
    }
  }

  Widget _buildFinishedScreen(AppThemeData currentTheme) {
    final theme = currentTheme.theme;

    if (_isLearningMode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.school_rounded, size: 60, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            "Učenie dokončené!", 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            "Prešiel si všetky kartičky z balíčka.", 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 24),
          _buildCustomButton(
            text: "Zatvoriť",
            onPressed: _finishAndUnlock,
            currentTheme: currentTheme,
          ),
        ],
      );
    }

    bool isSuccess = _correctAnswersCount >= _requiredCorrectQuestions;
    double mult = _calculatedTotalMultiplier;
    
    int earnedSeconds = isSuccess ? (_correctAnswersCount * 30 * mult).round() : 0;
    int m = earnedSeconds ~/ 60;
    int s = earnedSeconds % 60;
    bool isPractice = widget.practiceDeckId != null;

    String titleText = "Test Dokončený!";
    if (_isRemedialQuiz) {
      titleText = "Opravný test dokončený!";
    } else if (_isDoubleTest) titleText = "Double Test Dokončený!";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSuccess ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded, 
          size: 60, 
          color: isSuccess ? theme.colorScheme.tertiary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text(
          titleText, 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary), 
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Úspešnosť: $_correctAnswersCount / ${_questionCount.toInt()}", 
          style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
        ),
        Text(
          "Požadovaný prah: $_requiredCorrectQuestions / ${_questionCount.toInt()}", 
          style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSuccess 
                ? Colors.green.withValues(alpha: 0.12) 
                : Colors.red.withValues(alpha: 0.12), 
            borderRadius: currentTheme.cardBorderRadius,
            border: Border.all(color: isSuccess ? Colors.green : Colors.red, width: currentTheme.id == 2 ? 3.5 : 1.5),
            boxShadow: currentTheme.id == 2 ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))] : null,
          ),
          child: Text(
            isSuccess ? "Získaný čas: ${m}m ${s}s" : "Nesplnil si podmienku pre zisk času.", 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: isSuccess ? Colors.green.shade700 : Colors.red,
            ), 
            textAlign: TextAlign.center,
          ),
        ),
        if (isPractice) 
          Padding(
            padding: const EdgeInsets.only(top: 8.0), 
            child: Text(
              "(Tréningový mód - čas nebol pripísaný)", 
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        const SizedBox(height: 24),
        _buildCustomButton(
          text: isSuccess && !isPractice ? "Odomknúť aplikácie" : "Zatvoriť test",
          onPressed: _finishAndUnlock,
          currentTheme: currentTheme,
        ),
      ],
    );
  }

  Widget _buildLearningUI(AppThemeData currentTheme) {
    final theme = currentTheme.theme;
    final card = _learningCardsQueue.first;
    int currentIndex = _totalLearnedCards - _learningCardsQueue.length + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRemedialLearning)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12), 
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red, width: currentTheme.id == 2 ? 3.5 : 1),
            ),
            child: const Text(
              "POVINNÉ OPAKOVANIE ZA TREST", 
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent, 
                border: Border.all(color: Colors.orange, width: currentTheme.id == 2 ? 3.5 : 2), 
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text("${_failedCards.length}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Column(
              children: [
                Text(
                  "$currentIndex / $_totalLearnedCards", 
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_learningRound > 1) 
                  Text("Kolo $_learningRound", style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent, 
                border: Border.all(color: Colors.green, width: currentTheme.id == 2 ? 3.5 : 2), 
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text("$_masteredCount", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: currentIndex / _totalLearnedCards, 
          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12), 
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),

        Dismissible(
          key: ValueKey('${card['id']}_$_learningRound'),
          direction: _isCardFlipped ? DismissDirection.horizontal : DismissDirection.none,
          onDismissed: (direction) => _handleLearningAnswer(direction == DismissDirection.startToEnd),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15), 
              borderRadius: currentTheme.cardBorderRadius, 
              border: Border.all(color: Colors.green, width: currentTheme.id == 2 ? 3.5 : 2),
            ),
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
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15), 
              borderRadius: currentTheme.cardBorderRadius, 
              border: Border.all(color: Colors.orange, width: currentTheme.id == 2 ? 3.5 : 2),
            ),
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
              transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
              child: _isCardFlipped ? _buildCardBack(card, currentTheme) : _buildCardFront(card, currentTheme),
            ),
          ),
        ),
        const SizedBox(height: 24),
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
                    backgroundColor: Colors.orange.withValues(alpha: 0.12), 
                    foregroundColor: Colors.orange, 
                    elevation: currentTheme.id == 2 ? 0 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: currentTheme.buttonBorderRadius, 
                      side: BorderSide(color: Colors.orange, width: currentTheme.id == 2 ? 3.5 : 1.5),
                    ),
                  ),
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
                    backgroundColor: Colors.green.withValues(alpha: 0.12), 
                    foregroundColor: Colors.green, 
                    elevation: currentTheme.id == 2 ? 0 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: currentTheme.buttonBorderRadius, 
                      side: BorderSide(color: Colors.green, width: currentTheme.id == 2 ? 3.5 : 1.5),
                    ),
                  ),
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

  Widget _buildCardFront(Map<String, dynamic> card, AppThemeData currentTheme) {
    final theme = currentTheme.theme;
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.40,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor, 
        borderRadius: currentTheme.cardBorderRadius, 
        border: currentTheme.id == 2 
            ? Border.all(color: Colors.black, width: 3.5) 
            : (currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2)),
        boxShadow: currentTheme.id == 2 ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4))] : currentTheme.cardShadows,
        gradient: currentTheme.cardGradient,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card['prompt'].toString().endsWith('.svg'))
            SvgPicture.asset(card['prompt'], height: 100, fit: BoxFit.contain)
          else
            Text(
              card['prompt'], 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 24, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 40),
          Text(
            "Ťukni pre otočenie", 
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Map<String, dynamic> card, AppThemeData currentTheme) {
    final theme = currentTheme.theme;
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.40,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12), 
        borderRadius: currentTheme.cardBorderRadius, 
        border: Border.all(color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.primary, width: currentTheme.id == 2 ? 3.5 : 2),
        boxShadow: currentTheme.id == 2 ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4))] : currentTheme.cardShadows,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card['prompt'].toString().endsWith('.svg'))
            SvgPicture.asset(card['prompt'], height: 60, fit: BoxFit.contain)
          else
            Text(
              card['prompt'], 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 16, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24), 
            child: Divider(color: theme.colorScheme.primary, thickness: 1),
          ),
          Text(
            card['correct_answer'], 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 28, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomButton({
    required String text,
    required VoidCallback? onPressed,
    required AppThemeData currentTheme,
  }) {
    final theme = currentTheme.theme;
    final bool isNeo = currentTheme.id == 2;
    
    final Color bgColor = isNeo 
        ? (onPressed == null ? Colors.grey.shade300 : const Color(0xFFFFDE59))
        : (onPressed == null ? theme.colorScheme.onSurface.withValues(alpha: 0.3) : theme.colorScheme.primary);

    final Color fgColor = isNeo 
        ? (onPressed == null ? Colors.grey.shade600 : Colors.black)
        : currentTheme.getContrastTextColor(bgColor);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(
          color: isNeo ? Colors.black : Colors.transparent,
          width: isNeo ? 3.5 : 0,
        ),
        boxShadow: isNeo && onPressed != null
            ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: currentTheme.buttonBorderRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizUI(AppThemeData currentTheme) {
    final theme = currentTheme.theme;
    Color hardcoreFillCol = Colors.white.withValues(alpha: 0.9);
    Color hardcoreBorderCol = currentTheme.id == 2 ? Colors.black : Colors.black.withValues(alpha: 0.1);
    Widget? hardcoreFeedbackWidget;

    if (_isHardcore && _isAnswerChecked && !_isBlindTest) {
      String typed = _selectedAnswer ?? "";
      String expected = _actualCorrectAnswer.trim().toLowerCase();
      if (typed == expected && typed.isNotEmpty) {
        hardcoreFillCol = Colors.green.shade600; 
        hardcoreBorderCol = currentTheme.id == 2 ? Colors.black : Colors.green;
        hardcoreFeedbackWidget = const Text("Výborne!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
      } else {
        hardcoreFillCol = Colors.red.shade600; 
        hardcoreBorderCol = currentTheme.id == 2 ? Colors.black : Colors.red;
        if (!_hideCorrectAnswer) hardcoreFeedbackWidget = Text("Odpoveď bola: $_actualCorrectAnswer", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
      }
    }

    String topTitleText = "Otázka ${_currentQuestionIndex + 1} z ${_questionCount.toInt()}";
    if (_isRemedialQuiz) {
      topTitleText = "Opravný test • Otázka ${_currentQuestionIndex + 1} z ${_questionCount.toInt()}";
    } else if (_isDoubleTest) topTitleText = "Kolo $_currentTestRound/2 • Otázka ${_currentQuestionIndex + 1} z ${_questionCount.toInt()}";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              topTitleText, 
              style: TextStyle(
                color: _isRemedialQuiz ? Colors.red : theme.colorScheme.onSurface.withValues(alpha: 0.8), 
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_maxTime > 0)
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: _timeLeft <= 5 ? Colors.red : theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text("$_timeLeft s", style: TextStyle(fontWeight: FontWeight.bold, color: _timeLeft <= 5 ? Colors.red : theme.colorScheme.primary)),
                ],
              )
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questionCount, 
          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12), 
          color: _isRemedialQuiz ? Colors.redAccent : theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        
        if (_currentQuestion!['prompt'].toString().endsWith('.svg'))
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SvgPicture.asset(_currentQuestion!['prompt'], height: 110, fit: BoxFit.contain))
        else
          Text(
            _currentQuestion!['prompt'], 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 20, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
          ),
        
        if (_isSwapQuestion && !_isRemedialQuiz && !_hasUsedSwap && !_isAnswerChecked) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _swapCurrentQuestion,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text("Vymeň kartu (1x)", style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: currentTheme.buttonBorderRadius),
            ),
          ),
        ],

        const SizedBox(height: 24),
        
        if (_isHardcore) ...[
          TextField(
            controller: _hardcoreController,
            textAlign: TextAlign.center,
            enabled: !_isAnswerChecked, 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: (_isAnswerChecked && !_isBlindTest) ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: "Napíš odpoveď sem...",
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              filled: true, 
              fillColor: hardcoreFillCol,
              border: OutlineInputBorder(borderRadius: currentTheme.cardBorderRadius, borderSide: BorderSide(color: hardcoreBorderCol, width: currentTheme.id == 2 ? 3.5 : 1)),
              enabledBorder: OutlineInputBorder(borderRadius: currentTheme.cardBorderRadius, borderSide: BorderSide(color: hardcoreBorderCol, width: currentTheme.id == 2 ? 3.5 : 1)),
            ),
            onSubmitted: (_) => _checkQuizAnswer(""), 
          ),
          if (hardcoreFeedbackWidget != null) ...[const SizedBox(height: 8), hardcoreFeedbackWidget],
          const SizedBox(height: 16),
          _buildCustomButton(
            text: "Potvrdiť",
            onPressed: _isAnswerChecked ? null : () => _checkQuizAnswer(""),
            currentTheme: currentTheme,
          ),
        ] else ...[
          ..._currentOptions.map((option) {
            Color btnColor = Colors.white.withValues(alpha: 0.92);
            Color textColor = Colors.black87;
            BorderSide borderSide = currentTheme.id == 2 
                ? const BorderSide(color: Colors.black, width: 3.5) 
                : BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1);

            if (_isAnswerChecked) {
              if (_isBlindTest) {
                if (option == _selectedAnswer) {
                  btnColor = theme.colorScheme.primary.withValues(alpha: 0.8);
                  textColor = Colors.white;
                }
              } else {
                if (option == _actualCorrectAnswer && !_hideCorrectAnswer) {
                  btnColor = Colors.green.shade600; 
                  textColor = Colors.white; 
                  borderSide = const BorderSide(color: Colors.green, width: 2);
                } else if (option == _selectedAnswer) {
                  btnColor = Colors.red.shade600; 
                  textColor = Colors.white; 
                  borderSide = const BorderSide(color: Colors.red, width: 2);
                }
              }
            } else if (currentTheme.id == 2) {
              btnColor = Colors.white;
              textColor = Colors.black;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55), 
                  backgroundColor: btnColor, 
                  foregroundColor: textColor, 
                  elevation: currentTheme.id == 2 ? 0 : 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.buttonBorderRadius, 
                    side: borderSide,
                  ),
                ),
                onPressed: _isAnswerChecked ? () {} : () => _checkQuizAnswer(option),
                child: Text(option, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            );
          }),
        ],
      ],
    );
  }
}