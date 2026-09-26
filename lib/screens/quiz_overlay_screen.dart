import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';
import '../services/database_helper.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';
import '../themes/themed_background.dart';
import '../services/stats_provider.dart';
import '../services/daily_challenge_service.dart';
import '../services/tts_service.dart';
import '../services/locale_provider.dart';

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
  late ConfettiController _confettiController;
  
  // --- SPOLOČNÉ NASTAVENIA ---
  int? _activeDeckId;
  String? _deckFrontLang;
  String? _deckBackLang;
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
  
  // Rekapitulácia pre slepý test
  final List<Map<String, dynamic>> _blindTestRecap = [];

  double _questionCount = 5;
  double _timeLimitIndex = 0;
  double _lockoutIndex = 2;
  bool _is3Options = false;
  bool _isSecondChance = false;
  bool _hasUsedSecondChance = false;
  bool _isSwapQuestion = false;
  bool _hasUsedSwap = false;
  bool _isConfusion = false;
  bool _isBlindTest = false;
  bool _isHardcore = false;
  bool _isDoubleTest = false;
  int _currentTestRound = 1;

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
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _sessionStopwatch.start();
    _loadSettingsAndStart();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    TtsService.stop();
    _timer?.cancel();
    _hardcoreController.dispose();
    super.dispose();
  }

  String _normalizeLangCode(String? lang) {
    if (lang == null || lang.trim().isEmpty) return 'en-US';
    final clean = lang.trim().toLowerCase();
    if (clean.contains('fi') || clean.contains('fín') || clean.contains('finnish')) return 'fi-FI';
    if (clean.contains('sk') || clean.contains('slov')) return 'sk-SK';
    if (clean.contains('en') || clean.contains('ang') || clean.contains('english')) return 'en-US';
    if (clean.contains('de') || clean.contains('nem') || clean.contains('german')) return 'de-DE';
    if (clean.contains('es') || clean.contains('špa') || clean.contains('spanish')) return 'es-ES';
    if (clean.contains('fr') || clean.contains('fra') || clean.contains('french')) return 'fr-FR';
    if (clean.contains('it') || clean.contains('tal') || clean.contains('italian')) return 'it-IT';
    if (clean.contains('ru') || clean.contains('rus') || clean.contains('russian')) return 'ru-RU';
    if (clean.contains('cz') || clean.contains('cs') || clean.contains('čes') || clean.contains('czech')) return 'cs-CZ';
    if (clean.length == 2) return '$clean-${clean.toUpperCase()}';
    return lang;
  }

  bool _isSvg(String? path) {
    if (path == null) return false;
    return path.trim().toLowerCase().endsWith('.svg');
  }

  Widget _buildSvgImage(String path, {double? height, double? width, BoxFit fit = BoxFit.contain}) {
    final cleanPath = path.trim();
    final code = cleanPath.split('/').last.replaceAll('.svg', '').toUpperCase();

    Widget flagWidget;
    if (code.length == 2) {
      flagWidget = CountryFlag.fromCountryCode(
        code,
        height: height ?? 80,
        width: width ?? ((height ?? 80) * 1.4),
        shape: const Rectangle(),
      );
    } else {
      flagWidget = SvgPicture.asset(
        cleanPath,
        height: height,
        width: width,
        fit: fit,
      );
    }

    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final bool isNeo = currentTheme.id == 2;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyber = currentTheme.id == 0 || cleanName.contains('cyberpunk');

    final Color flagBorderColor = isNeo
        ? Colors.black
        : (isCyber
            ? const Color(0xFF00F0FF)
            : currentTheme.theme.colorScheme.onSurface.withValues(alpha: 0.50));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: flagBorderColor,
          width: isNeo ? 7.0 : 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCyber
                ? const Color(0xFF00F0FF).withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: flagWidget,
    );
  }

  void _showThemedSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');
    
    final Color textColor = isCyberpunk
        ? Colors.white
        : (isNeo
            ? Colors.black
            : (isSoft 
                ? const Color(0xFF1E293B) 
                : ((isVibrant || isGlass)
                    ? Colors.white 
                    : currentTheme.getContrastTextColor(backgroundColor))));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: textColor,
            fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold,
            fontFamily: isCyberpunk ? 'monospace' : null,
            fontSize: 14,
          ),
        ),
        backgroundColor: isCyberpunk ? const Color(0xFF120E24) : (isSoft ? const Color(0xFFD1D9E6) : backgroundColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.buttonBorderRadius,
          side: isCyberpunk
              ? const BorderSide(color: Color(0xFFFF007F), width: 1.5)
              : (isNeo
                  ? const BorderSide(color: Colors.black, width: 3.5)
                  : BorderSide.none),
        ),
        elevation: isNeo ? 0 : 4,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadSettingsAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    _blindTestRecap.clear();

    final activeDeckId = widget.practiceDeckId ?? prefs.getInt('active_test_deck_id');

    if (activeDeckId != null) {
      try {
        final deckData = await DatabaseHelper.instance.getDeckById(activeDeckId);
        if (deckData != null) {
            _deckFrontLang = deckData['front_lang']?.toString() ?? deckData['frontLang']?.toString();
            _deckBackLang = deckData['back_lang']?.toString() ?? deckData['backLang']?.toString();
        }
      } catch (_) {}
    }

    setState(() {
      _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _activeDeckId = activeDeckId;
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
        _hasUsedSecondChance = false;
        _isSwapQuestion = prefs.getBool('test_isSwapQuestion') ?? false;
        _isBlindTest = prefs.getBool('test_isBlindTest') ?? false;
        _isDoubleTest = prefs.getBool('test_isDoubleTest') ?? false;
        _maxTime = _timeLimitsInSeconds[_timeLimitIndex.toInt()];
      }
    });

    final currentLocale = context.read<LocaleProvider>().locale;

    if (_isLearningMode) {
      _startLearningMode(currentLocale);
    } else {
      _loadNextQuizQuestion(currentLocale);
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
    final currentLocale = context.read<LocaleProvider>().locale;
    
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

    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final isEn = currentLocale == 'en';
    _showThemedSnackBar(
      isEn 
          ? "Test failed! Review the cards and complete the retake test (min. 80%)."
          : "Test zlyhal! Zopakuj si kartičky a absolvuj opravný test (min. 80 %).",
      currentTheme.errorColor,
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
      _isAnswerChecked = false;
      _selectedAnswer = null;
      _hideCorrectAnswer = false;
      _hardcoreController.clear();
    });

    if (_currentQuestionIndex >= _remedialQuizQuestions.length) {
      _confettiController.play();
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

  Future<void> _startLearningMode([String? locale]) async {
    setState(() => _isLoading = true);
    final currentLocale = locale ?? context.read<LocaleProvider>().locale;
    
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
      if (_isTestFinished) {
        _confettiController.play();
      }
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
            _confettiController.play();
            _isTestFinished = true;
          }
        }
      }
      
      _isCardFlipped = false;
    });
  }

  Future<void> _loadNextQuizQuestion([String? locale]) async {
    _timer?.cancel();
    setState(() {
      _isLoading = true;
      _isAnswerChecked = false;
      _selectedAnswer = null;
      _hideCorrectAnswer = false;
      _hardcoreController.clear();
    });

    final currentLocale = locale ?? context.read<LocaleProvider>().locale;
    final isEn = currentLocale == 'en';

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

    final String noneOption = isEn ? "None of the above" : "Žiadna z odpovedí";

    if (!_isHardcore) {
      if (_isConfusion) {
        bool isNoneCorrect = Random().nextDouble() < 0.4;
        if (isNoneCorrect) {
          options.remove(correct); options.add(noneOption); correct = noneOption;
        } else {
          String wrongOpt = options.firstWhere((opt) => opt != correct);
          options.remove(wrongOpt); options.add(noneOption);
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

    final currentLocale = context.read<LocaleProvider>().locale;
    final isEn = currentLocale == 'en';

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

    final String noneOption = isEn ? "None of the above" : "Žiadna z odpovedí";

    if (!_isHardcore) {
      if (_isConfusion) {
        bool isNoneCorrect = Random().nextDouble() < 0.4;
        if (isNoneCorrect) {
          options.remove(correct); options.add(noneOption); correct = noneOption;
        } else {
          String wrongOpt = options.firstWhere((opt) => opt != correct);
          options.remove(wrongOpt); options.add(noneOption);
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

  void _vibrateOneShot(int durationMs) async {
    if (_isVibrationEnabled && !_isBlindTest) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: durationMs);
      }
    }
  }

  void _triggerFailureVibration() async {
    if (_isVibrationEnabled && !_isBlindTest) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 150, 100, 150]);
      }
    }
  }

  void _checkQuizAnswer(String selectedOption) async {
    if (_isAnswerChecked) return; 
    _timer?.cancel();
    bool isCorrect = false;
    final isEn = context.read<LocaleProvider>().locale == 'en';

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
      String userAns = _isHardcore ? (_selectedAnswer ?? '') : selectedOption;
      if (userAns.isEmpty) userAns = isEn ? "No answer (time expired)" : "Bez odpovede (čas vypršal)";

      _blindTestRecap.add({
        'prompt': _currentQuestion?['prompt'] ?? '',
        'selected': userAns,
        'correct': _actualCorrectAnswer,
        'isCorrect': isCorrect,
      });

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

      _vibrateOneShot(250);

      if (_isSecondChance && !_hasUsedSecondChance) {
        setState(() { 
          _hasUsedSecondChance = true; 
          _hideCorrectAnswer = true; 
        });

        final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
        _showThemedSnackBar(
          isEn ? 'Second chance! Try again.' : 'Druhá šanca! Skús znova.',
          currentTheme.warningColor,
        );

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
        setState(() => _hideCorrectAnswer = false); 
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        _proceedToNextQuiz();
      }
    }
  }

  void _proceedToNextQuiz() {
    _currentQuestionIndex++;
    int totalQuestions = _questionCount.toInt();
    int remainingQuestions = totalQuestions - _currentQuestionIndex;
    int maxPossibleCorrect = _correctAnswersCount + remainingQuestions;
    final isEn = context.read<LocaleProvider>().locale == 'en';

    if (_currentQuestionIndex >= totalQuestions) {
      bool passed = _correctAnswersCount >= _requiredCorrectQuestions;

      if (_isDoubleTest && _currentTestRound == 1 && passed && !_isRemedialQuiz) {
        setState(() {
          _currentTestRound = 2;
          _currentQuestionIndex = 0;
          _correctAnswersCount = 0;
          _hasUsedSwap = false;
          _hasUsedSecondChance = false;
          _excludedCardIds.clear();
          _blindTestRecap.clear();
        });

        final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
        _showThemedSnackBar(
          isEn ? "Round 1 passed! Now complete Round 2." : "1. kolo zvládnuté! Teraz dokonči 2. kolo.",
          currentTheme.warningColor,
        );

        _loadNextQuizQuestion();
      } 
      else if (!passed && !_isRemedialQuiz) {
        _triggerFailureVibration();
        _startRemedialLearning();
      } 
      else {
        setState(() => _isTestFinished = true);
        if (passed) {
          _confettiController.play();
        } else {
          _triggerFailureVibration();
        }
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

      int totalEarnedInPractice = earnedSecondsForPractice + challengeBonusSeconds;

      if (totalEarnedInPractice > 0) {
        const platform = MethodChannel('flashpass.channel');
        try {
          await platform.invokeMethod('unlockApp', {
            'seconds': totalEarnedInPractice,
            'maxCap': totalEarnedInPractice,
            'isFromNotification': false,
            'themeColor': themeColorValue,
          });
        } catch (e) {
          debugPrint("Chyba pri prirátaní času z in-app testu: $e");
        }
      }

      await DatabaseHelper.instance.insertStudySession(
        deckId: _activeDeckId ?? 0,
        durationSeconds: actualStudyTimeSeconds,
        earnedSeconds: totalEarnedInPractice,
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

      const platform = MethodChannel('flashpass.channel');
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

    const platform = MethodChannel('flashpass.channel');
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

  BoxDecoration _getUncheckedOptionDecoration(AppThemeData currentTheme) {
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isClean = currentTheme.id == 3;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');

    if (isCyberpunk) {
      return BoxDecoration(
        color: const Color(0xFF120E24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5), width: 1.5),
      );
    }
    if (isSoft) {
      return BoxDecoration(
        color: const Color(0xFFD1D9E6),
        borderRadius: currentTheme.buttonBorderRadius,
        boxShadow: const [
          BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(4, 4), blurRadius: 8),
          BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
        ],
      );
    }
    if (isGlass) {
      return BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
      );
    }
    if (isVibrant) {
      return BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
      );
    }
    return BoxDecoration(
      color: isNeo ? Colors.white : theme.cardColor,
      borderRadius: currentTheme.buttonBorderRadius,
      border: isNeo
          ? Border.all(color: Colors.black, width: 3.5)
          : Border.all(
              color: isClean ? const Color(0xFF94A3B8) : theme.colorScheme.onSurface.withValues(alpha: 0.15), 
              width: isClean ? 1.2 : 1.0,
            ),
      boxShadow: isNeo ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)] : null,
    );
  }

  Color _getUncheckedOptionTextColor(AppThemeData currentTheme) {
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');

    if (isCyberpunk) return Colors.white;
    if (isSoft) return const Color(0xFF1E293B);
    if (isNeo) return Colors.black;
    return (isVibrant || isGlass) ? Colors.white : currentTheme.theme.colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final bool isPractice = widget.practiceDeckId != null;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final isEn = context.watch<LocaleProvider>().locale == 'en';
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');

    BoxDecoration dialogBgDecoration;
    if (isCyberpunk) {
      dialogBgDecoration = BoxDecoration(
        color: const Color(0xFF050014),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F0FF),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFFFF007F).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (isSoft) {
      dialogBgDecoration = BoxDecoration(
        color: const Color(0xFFD1D9E6),
        borderRadius: currentTheme.cardBorderRadius,
        boxShadow: const [],
      );
    } else if (isNeo) {
      dialogBgDecoration = BoxDecoration(
        color: const Color(0xFFF7EED2),
        borderRadius: currentTheme.cardBorderRadius,
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      );
    } else if (isGlass) {
      dialogBgDecoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: currentTheme.cardBorderRadius,
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.5), 
          width: 1.5,
        ),
        boxShadow: const [],
      );
    } else if (isVibrant) {
      dialogBgDecoration = currentTheme.getCardDecoration(currentTheme.testSetupColor).copyWith(
        boxShadow: const [],
      );
    } else {
      dialogBgDecoration = BoxDecoration(
        color: theme.cardColor,
        borderRadius: currentTheme.cardBorderRadius,
        border: currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
        boxShadow: const [],
        gradient: currentTheme.cardGradient,
      );
    }

    final Widget mainBody = Scaffold(
      backgroundColor: isPractice 
          ? Colors.transparent 
          : Colors.black.withValues(alpha: 0.70),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.92,
                    decoration: dialogBgDecoration,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: _isLoading 
                          ? SizedBox(
                              height: 200, 
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF2563EB) : currentTheme.testSetupColor)),
                                ),
                              ),
                            ) 
                          : _buildContent(currentTheme, isEn),
                    ),
                  ),

                  if (isPractice) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _closeOrExitScreen,
                      icon: Icon(
                        Icons.close_rounded, 
                        color: isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF4A5568) : ((isVibrant || isGlass) ? Colors.white.withValues(alpha: 0.85) : theme.colorScheme.onSurface.withValues(alpha: 0.75)))), 
                        size: 20,
                      ),
                      label: Text(
                        isEn ? "Cancel test" : "Zrušiť test", 
                        style: TextStyle(
                          color: isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF4A5568) : ((isVibrant || isGlass) ? Colors.white.withValues(alpha: 0.85) : theme.colorScheme.onSurface.withValues(alpha: 0.75)))), 
                          fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold, 
                          fontFamily: isCyberpunk ? 'monospace' : null,
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
          
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              minBlastForce: 35,
              maxBlastForce: 90,
              emissionFrequency: 0.01,
              numberOfParticles: 100,
              gravity: 0.35,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.amber,
                Colors.cyan,
                Colors.lime,
              ],
            ),
          ),
        ],
      ),
    );

    if (isPractice) {
      return ThemedBackground(child: mainBody);
    }
    return mainBody;
  }

  Widget _buildContent(AppThemeData currentTheme, bool isEn) {
    if (_isTestFinished) return _buildFinishedScreen(currentTheme, isEn);
    
    if (_isLearningMode || _isRemedialLearning) {
      if (_learningCardsQueue.isEmpty) {
        final bool isVibrant = currentTheme.id == 5;
        final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
        final bool isNeo = currentTheme.id == 2;
        final bool isSoft = currentTheme.id == 1;
        final String cleanName = currentTheme.name.toLowerCase();
        final bool isCyberpunk = cleanName.contains('cyberpunk');

        return Text(
          isEn ? "No cards in database!" : "Žiadne kartičky v databáze!", 
          style: TextStyle(
            fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.normal,
            fontFamily: isCyberpunk ? 'monospace' : null,
            color: isCyberpunk ? Colors.white : (isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : ((isVibrant || isGlass) ? Colors.white : currentTheme.theme.colorScheme.onSurface))),
          ),
        );
      }
      return _buildLearningUI(currentTheme, isEn);
    } else {
      if (_currentQuestion == null) {
        final bool isVibrant = currentTheme.id == 5;
        final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
        final bool isNeo = currentTheme.id == 2;
        final bool isSoft = currentTheme.id == 1;
        final String cleanName = currentTheme.name.toLowerCase();
        final bool isCyberpunk = cleanName.contains('cyberpunk');

        return Text(
          isEn ? "No cards in database!" : "Žiadne kartičky v databáze!",
          style: TextStyle(
            fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.normal,
            fontFamily: isCyberpunk ? 'monospace' : null,
            color: isCyberpunk ? Colors.white : (isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : ((isVibrant || isGlass) ? Colors.white : currentTheme.theme.colorScheme.onSurface))),
          ),
        );
      }
      return _buildQuizUI(currentTheme, isEn);
    }
  }

  Widget _buildRecapAnswerRow({
    required String label,
    required String value,
    required Color valueColor,
    required Color mainTextColor,
    required bool isCyberpunk,
  }) {
    final bool isSvg = _isSvg(value);

    if (isSvg) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: isCyberpunk ? 'monospace' : null,
              color: mainTextColor,
            ),
          ),
          const SizedBox(width: 6),
          _buildSvgImage(value, height: 26),
        ],
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          fontFamily: isCyberpunk ? 'monospace' : null,
          color: mainTextColor,
        ),
        children: [
          TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlindTestRecap(AppThemeData currentTheme, bool isEn) {
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';

    final Color mainTextColor = isCyberpunk
        ? Colors.white
        : (isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : ((isVibrant || isGlass) ? Colors.white : currentTheme.theme.colorScheme.onSurface)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Divider(
          color: isCyberpunk
              ? const Color(0xFF00F0FF).withValues(alpha: 0.4)
              : (isNeo ? Colors.black : mainTextColor.withValues(alpha: 0.2)),
          thickness: isNeo ? 2 : 1,
        ),
        const SizedBox(height: 12),
        Text(
          isEn ? "Blind Test Recap:" : "Rekapitulácia slepého testu:",
          style: TextStyle(
            fontSize: 16,
            fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold,
            fontFamily: isCyberpunk ? 'monospace' : null,
            color: isCyberpunk ? const Color(0xFF00F0FF) : mainTextColor,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: _blindTestRecap.map((item) {
                final bool isCorrect = item['isCorrect'] as bool;
                final Color statusColor = isCorrect ? currentTheme.successColor : currentTheme.errorColor;
                final String promptStr = item['prompt'].toString();
                final String selectedStr = item['selected'].toString();
                final String correctStr = item['correct'].toString();

                final Color cardBg = isCyberpunk
                    ? const Color(0xFF120E24)
                    : (isSoft
                        ? const Color(0xFFC8D3E6)
                        : (isNeo
                            ? Colors.white
                            : (isGlass ? Colors.white.withValues(alpha: 0.1) : currentTheme.theme.cardColor)));

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: currentTheme.cardBorderRadius,
                    border: Border.all(
                      color: isCyberpunk
                          ? (isCorrect ? const Color(0xFF00F0FF) : const Color(0xFFFF007F))
                          : (isNeo ? Colors.black : statusColor.withValues(alpha: 0.6)),
                      width: isNeo ? 2.5 : 1.2,
                    ),
                    boxShadow: isNeo ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)] : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isCyberpunk
                                ? (isCorrect ? const Color(0xFF00F0FF) : const Color(0xFFFF007F))
                                : (isNeo ? Colors.black : statusColor),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isSvg(promptStr)
                                ? Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildSvgImage(promptStr, height: 38),
                                  )
                                : Text(
                                    promptStr,
                                    style: TextStyle(
                                      fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold,
                                      fontSize: 14,
                                      fontFamily: isCyberpunk ? 'monospace' : null,
                                      color: mainTextColor,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRecapAnswerRow(
                        label: isEn ? "Your answer: " : "Tvoja odpoveď: ",
                        value: selectedStr,
                        valueColor: isCyberpunk
                            ? (isCorrect ? const Color(0xFF00F0FF) : const Color(0xFFFF007F))
                            : (isNeo ? Colors.black : statusColor),
                        mainTextColor: mainTextColor,
                        isCyberpunk: isCyberpunk,
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 4),
                        _buildRecapAnswerRow(
                          label: isEn ? "Correct answer: " : "Správna odpoveď: ",
                          value: correctStr,
                          valueColor: isCyberpunk
                              ? const Color(0xFF00F0FF)
                              : (isNeo ? Colors.black : (isSoft ? const Color(0xFF0D9488) : currentTheme.successColor)),
                          mainTextColor: mainTextColor,
                          isCyberpunk: isCyberpunk,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedScreen(AppThemeData currentTheme, bool isEn) {
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');
    final Color textColor = isCyberpunk ? Colors.white : (isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : ((isVibrant || isGlass) ? Colors.white : theme.colorScheme.onSurface)));

    if (_isLearningMode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isCyberpunk
              ? const Icon(Icons.school_rounded, size: 60, color: Color(0xFF00F0FF))
              : (isSoft
                  ? Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCCFBF1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
                          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                        ],
                      ),
                      child: const Icon(Icons.school_rounded, size: 38, color: Color(0xFF0D9488)),
                    )
                  : const Icon(Icons.school_rounded, size: 60, color: Colors.green)),
          const SizedBox(height: 16),
          Text(
            isEn ? "Learning Completed!" : "Učenie dokončené!", 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold, 
              fontFamily: isCyberpunk ? 'monospace' : null,
              color: isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : ((isVibrant || isGlass) ? Colors.white : theme.colorScheme.primary))),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isEn ? "You have reviewed all cards in this deck." : "Prešiel si všetky kartičky z balíčka.", 
            textAlign: TextAlign.center, 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.bold : FontWeight.normal,
              fontFamily: isCyberpunk ? 'monospace' : null,
              color: isCyberpunk ? Colors.white70 : (isNeo ? Colors.black87 : (isSoft ? const Color(0xFF64748B) : textColor)),
            ),
          ),
          const SizedBox(height: 24),
          _buildCustomButton(
            text: isEn ? "Close" : "Zatvoriť",
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

    String titleText = isEn ? "Test Completed!" : "Test Dokončený!";
    if (_isRemedialQuiz) {
      titleText = isEn ? "Retake Test Completed!" : "Opravný test dokončený!";
    } else if (_isDoubleTest) {
      titleText = isEn ? "Double Test Completed!" : "Double Test Dokončený!";
    }

    final Color accentResultColor = isSuccess ? currentTheme.successColor : currentTheme.errorColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isCyberpunk
            ? Icon(
                isSuccess ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                size: 60,
                color: isSuccess ? const Color(0xFF00F0FF) : const Color(0xFFFF007F),
              )
            : (isSoft
                ? Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isSuccess ? const Color(0xFFCCFBF1) : const Color(0xFFFFE4E6),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
                        BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                      ],
                    ),
                    child: Icon(
                      isSuccess ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                      size: 38,
                      color: isSuccess ? const Color(0xFF0D9488) : const Color(0xFFE11D48),
                    ),
                  )
                : Icon(
                    isSuccess ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded, 
                    size: 60, 
                    color: isSuccess ? (isNeo ? Colors.black : currentTheme.getIconColor(currentTheme.successColor)) : textColor.withValues(alpha: 0.4),
                  )),
        const SizedBox(height: 16),
        Text(
          titleText, 
          style: TextStyle(
            fontSize: 24, 
            fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold, 
            fontFamily: isCyberpunk ? 'monospace' : null,
            color: isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : ((isVibrant || isGlass) ? Colors.white : theme.colorScheme.primary))),
          ), 
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "${isEn ? 'Score' : 'Úspešnosť'}: $_correctAnswersCount / ${_questionCount.toInt()}", 
          style: TextStyle(
            fontSize: 16, 
            fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.bold : FontWeight.normal,
            fontFamily: isCyberpunk ? 'monospace' : null,
            color: isCyberpunk ? Colors.white : (isNeo ? Colors.black87 : (isSoft ? const Color(0xFF1E293B) : textColor)),
          ),
        ),
        Text(
          "${isEn ? 'Required score' : 'Požadovaný prah'}: $_requiredCorrectQuestions / ${_questionCount.toInt()}", 
          style: TextStyle(
            fontSize: 16, 
            fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.bold : FontWeight.normal,
            fontFamily: isCyberpunk ? 'monospace' : null,
            color: isCyberpunk ? Colors.white70 : (isNeo ? Colors.black54 : (isSoft ? const Color(0xFF64748B) : textColor.withValues(alpha: 0.7))),
          ),
        ),
        
        if (!isPractice) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: isCyberpunk
                ? BoxDecoration(
                    color: const Color(0xFF120E24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSuccess ? const Color(0xFF00F0FF) : const Color(0xFFFF007F), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: (isSuccess ? const Color(0xFF00F0FF) : const Color(0xFFFF007F)).withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  )
                : (isSoft
                    ? BoxDecoration(
                        color: const Color(0xFFD1D9E6),
                        borderRadius: currentTheme.cardBorderRadius,
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(4, 4), blurRadius: 8),
                          BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
                        ],
                      )
                    : (isNeo
                        ? BoxDecoration(
                            color: accentResultColor,
                            borderRadius: currentTheme.cardBorderRadius,
                            border: Border.all(color: Colors.black, width: 3.5),
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                          )
                        : currentTheme.getCardDecoration(accentResultColor))),
            child: Text(
              isSuccess 
                  ? (isEn ? "Time earned: ${m}m ${s}s" : "Získaný čas: ${m}m ${s}s")
                  : (isEn ? "Requirement not met to earn time." : "Nesplnil si podmienku pre zisk času."), 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold, 
                fontFamily: isCyberpunk ? 'monospace' : null,
                color: isCyberpunk ? (isSuccess ? const Color(0xFF00F0FF) : const Color(0xFFFF007F)) : (isNeo ? Colors.black : (isSoft ? (isSuccess ? const Color(0xFF0D9488) : const Color(0xFFE11D48)) : ((isVibrant || isGlass) ? Colors.white : currentTheme.getContrastTextColor(accentResultColor)))),
              ), 
              textAlign: TextAlign.center,
            ),
          ),
        ],

        if (_isBlindTest && _blindTestRecap.isNotEmpty)
          _buildBlindTestRecap(currentTheme, isEn),

        const SizedBox(height: 24),
        _buildCustomButton(
          text: isSuccess && !isPractice 
              ? (isEn ? "Unlock Apps" : "Odomknúť aplikácie") 
              : (isEn ? "Close Test" : "Zatvoriť test"),
          onPressed: _finishAndUnlock,
          currentTheme: currentTheme,
        ),
      ],
    );
  }

  Widget _buildLearningUI(AppThemeData currentTheme, bool isEn) {
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isClean = currentTheme.id == 3;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');
    final Color textColor = isCyberpunk ? Colors.white : (isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : ((isVibrant || isGlass) ? Colors.white : theme.colorScheme.onSurface)));
    final card = _learningCardsQueue.first;
    int currentIndex = _totalLearnedCards - _learningCardsQueue.length + 1;

    final String btnKnowText = isEn ? "Know" : "Viem";
    final String btnAgainText = isEn ? "Again" : "Znova";

    final Color warningBtnTextColor = isClean
        ? const Color(0xFFDC2626)
        : (isCyberpunk
            ? const Color(0xFFFF007F)
            : (isNeo
                ? Colors.black
                : (isSoft ? const Color(0xFFD97706) : ((isVibrant || isGlass) 
                    ? Colors.white 
                    : currentTheme.getContrastTextColor(currentTheme.warningColor)))));

    final Color successBtnTextColor = isClean
        ? const Color(0xFF059669)
        : (isCyberpunk
            ? const Color(0xFF00F0FF)
            : (isNeo
                ? Colors.black
                : (isSoft ? const Color(0xFF0D9488) : ((isVibrant || isGlass) 
                    ? Colors.white 
                    : currentTheme.getContrastTextColor(currentTheme.successColor)))));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRemedialLearning)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: isCyberpunk
                ? BoxDecoration(
                    color: const Color(0xFF120E24),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF007F), width: 1.5),
                  )
                : (isSoft
                    ? BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: currentTheme.cardBorderRadius,
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(2, 2), blurRadius: 4),
                          BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                        ],
                      )
                    : (isNeo
                        ? BoxDecoration(
                            color: currentTheme.errorColor,
                            borderRadius: currentTheme.cardBorderRadius,
                            border: Border.all(color: Colors.black, width: 3.5),
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                          )
                        : currentTheme.getCardDecoration(currentTheme.errorColor))),
            child: Text(
              isEn ? "MANDATORY PUNISHMENT REVIEW" : "POVINNÉ OPAKOVANIE ZA TREST", 
              style: TextStyle(
                color: isCyberpunk ? const Color(0xFFFF007F) : (isNeo ? Colors.black : (isSoft ? const Color(0xFFE11D48) : ((isVibrant || isGlass) ? Colors.white : currentTheme.getContrastTextColor(currentTheme.errorColor)))), 
                fontWeight: FontWeight.w900, 
                fontFamily: isCyberpunk ? 'monospace' : null,
                fontSize: 12,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: isCyberpunk
                  ? BoxDecoration(
                      color: const Color(0xFF120E24),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFF007F), width: 1.5),
                    )
                  : (isSoft
                      ? BoxDecoration(
                          color: const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(2, 2), blurRadius: 4),
                            BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                          ],
                        )
                      : BoxDecoration(
                          color: isNeo ? currentTheme.warningColor : Colors.transparent, 
                          border: Border.all(color: isClean ? const Color(0xFFDC2626) : Colors.black, width: isNeo ? 3.5 : (isClean ? 1.5 : 2)), 
                          borderRadius: BorderRadius.circular(isNeo ? 12 : 16),
                          boxShadow: isNeo ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)] : null,
                        )),
              child: Text("${_failedCards.length}", style: TextStyle(color: isClean ? const Color(0xFFDC2626) : (isCyberpunk ? const Color(0xFFFF007F) : (isNeo ? Colors.black : (isSoft ? const Color(0xFFE11D48) : currentTheme.warningColor))), fontWeight: FontWeight.w900, fontFamily: isCyberpunk ? 'monospace' : null, fontSize: 16)),
            ),
            Column(
              children: [
                Text(
                  "$currentIndex / $_totalLearnedCards", 
                  style: TextStyle(color: isCyberpunk ? Colors.white : (isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : textColor.withValues(alpha: 0.7))), fontWeight: FontWeight.w900, fontFamily: isCyberpunk ? 'monospace' : null, fontSize: 16),
                ),
                if (_learningRound > 1) 
                  Text("${isEn ? 'Round' : 'Kolo'} $_learningRound", style: TextStyle(color: isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF2563EB) : currentTheme.warningColor)), fontSize: 12, fontWeight: FontWeight.w900, fontFamily: isCyberpunk ? 'monospace' : null)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: isCyberpunk
                  ? BoxDecoration(
                      color: const Color(0xFF120E24),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
                    )
                  : (isSoft
                      ? BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(2, 2), blurRadius: 4),
                            BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                          ],
                        )
                      : BoxDecoration(
                          color: isNeo ? currentTheme.successColor : Colors.transparent, 
                          border: Border.all(color: isClean ? const Color(0xFF059669) : Colors.black, width: isNeo ? 3.5 : (isClean ? 1.5 : 2)), 
                          borderRadius: BorderRadius.circular(isNeo ? 12 : 16),
                          boxShadow: isNeo ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)] : null,
                        )),
              child: Text("$_masteredCount", style: TextStyle(color: isClean ? const Color(0xFF059669) : (isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF0D9488) : currentTheme.successColor))), fontWeight: FontWeight.w900, fontFamily: isCyberpunk ? 'monospace' : null, fontSize: 16)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: currentIndex / _totalLearnedCards, 
          backgroundColor: isCyberpunk ? const Color(0xFF120E24) : (isNeo ? Colors.black12 : (isSoft ? const Color(0xFFC8D3E6) : textColor.withValues(alpha: 0.12))), 
          color: isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF2563EB) : currentTheme.testSetupColor)),
        ),
        const SizedBox(height: 24),

        Dismissible(
          key: ValueKey('${card['id']}_$_learningRound'),
          direction: _isCardFlipped ? DismissDirection.horizontal : DismissDirection.none,
          onDismissed: (direction) => _handleLearningAnswer(direction == DismissDirection.startToEnd),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            decoration: isCyberpunk
                ? BoxDecoration(
                    color: const Color(0xFF120E24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                  )
                : (isSoft
                    ? BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: currentTheme.cardBorderRadius,
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(4, 4), blurRadius: 8),
                          BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
                        ],
                      )
                    : (isNeo
                        ? BoxDecoration(
                            color: currentTheme.successColor,
                            borderRadius: currentTheme.cardBorderRadius,
                            border: Border.all(color: Colors.black, width: 3.5),
                          )
                        : (isClean
                            ? BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: currentTheme.cardBorderRadius,
                                border: Border.all(color: const Color(0xFF059669), width: 1.5),
                              )
                            : currentTheme.getCardDecoration(currentTheme.successColor)))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_rounded, color: successBtnTextColor, size: 50),
                const SizedBox(height: 8),
                Text(
                  btnKnowText.toUpperCase(), 
                  style: TextStyle(
                    color: successBtnTextColor, 
                    fontSize: 24, 
                    fontWeight: isNeo || isSoft || isCyberpunk || isClean ? FontWeight.w900 : FontWeight.bold,
                    fontFamily: isCyberpunk ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            decoration: isCyberpunk
                ? BoxDecoration(
                    color: const Color(0xFF120E24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF007F), width: 2),
                  )
                : (isSoft
                    ? BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: currentTheme.cardBorderRadius,
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(4, 4), blurRadius: 8),
                          BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
                        ],
                      )
                    : (isNeo
                        ? BoxDecoration(
                            color: currentTheme.warningColor,
                            borderRadius: currentTheme.cardBorderRadius,
                            border: Border.all(color: Colors.black, width: 3.5),
                          )
                        : (isClean
                            ? BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: currentTheme.cardBorderRadius,
                                border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
                              )
                            : currentTheme.getCardDecoration(currentTheme.warningColor)))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.close_rounded, color: warningBtnTextColor, size: 50),
                const SizedBox(height: 8),
                Text(
                  btnAgainText.toUpperCase(), 
                  style: TextStyle(
                    color: warningBtnTextColor, 
                    fontSize: 24, 
                    fontWeight: isNeo || isSoft || isCyberpunk || isClean ? FontWeight.w900 : FontWeight.bold,
                    fontFamily: isCyberpunk ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() => _isCardFlipped = !_isCardFlipped);
              _vibrateOneShot(40);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
              child: _isCardFlipped ? _buildCardBack(card, currentTheme) : _buildCardFront(card, currentTheme, isEn),
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isCardFlipped ? () => _handleLearningAnswer(false) : null,
                    borderRadius: isCyberpunk ? BorderRadius.circular(8) : currentTheme.buttonBorderRadius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: isClean
                          ? BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: currentTheme.buttonBorderRadius,
                              border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            )
                          : (isCyberpunk
                              ? BoxDecoration(
                                  color: const Color(0xFF120E24),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFF007F), width: 1.5),
                                )
                              : (isSoft
                                  ? BoxDecoration(
                                      color: const Color(0xFFFFE4E6),
                                      borderRadius: currentTheme.buttonBorderRadius,
                                      boxShadow: const [
                                        BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
                                        BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                                      ],
                                    )
                                  : (isNeo
                                      ? BoxDecoration(
                                          color: currentTheme.warningColor,
                                          borderRadius: currentTheme.buttonBorderRadius,
                                          border: Border.all(color: Colors.black, width: 3.5),
                                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                                        )
                                      : currentTheme.getCardDecoration(currentTheme.warningColor)))),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded, color: warningBtnTextColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            btnAgainText, 
                            style: TextStyle(
                              fontWeight: isNeo || isSoft || isCyberpunk || isClean ? FontWeight.bold : FontWeight.w600, 
                              fontFamily: isCyberpunk ? 'monospace' : null,
                              fontSize: 15,
                              color: warningBtnTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isCardFlipped ? () => _handleLearningAnswer(true) : null,
                    borderRadius: isCyberpunk ? BorderRadius.circular(8) : currentTheme.buttonBorderRadius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: isClean
                          ? BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: currentTheme.buttonBorderRadius,
                              border: Border.all(color: const Color(0xFF059669), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            )
                          : (isCyberpunk
                              ? BoxDecoration(
                                  color: const Color(0xFF00F0FF),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                )
                              : (isSoft
                                  ? BoxDecoration(
                                      color: const Color(0xFFCCFBF1),
                                      borderRadius: currentTheme.buttonBorderRadius,
                                      boxShadow: const [
                                        BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
                                        BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                                      ],
                                    )
                                  : (isNeo
                                      ? BoxDecoration(
                                          color: currentTheme.successColor,
                                          borderRadius: currentTheme.buttonBorderRadius,
                                          border: Border.all(color: Colors.black, width: 3.5),
                                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                                        )
                                      : currentTheme.getCardDecoration(currentTheme.successColor)))),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, color: isCyberpunk ? Colors.black : successBtnTextColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            btnKnowText, 
                            style: TextStyle(
                              fontWeight: isNeo || isSoft || isCyberpunk || isClean ? FontWeight.bold : FontWeight.w600, 
                              fontFamily: isCyberpunk ? 'monospace' : null,
                              fontSize: 15,
                              color: isCyberpunk ? Colors.black : successBtnTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFront(Map<String, dynamic> card, AppThemeData currentTheme, bool isEn) {
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');
    final Color textColor = isCyberpunk ? Colors.white : (isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : ((isVibrant || isGlass) ? Colors.white : theme.colorScheme.onSurface)));

    final cardDecor = isCyberpunk
        ? BoxDecoration(
            color: const Color(0xFF120E24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00F0FF), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                blurRadius: 10,
              ),
            ],
          )
        : (isSoft
            ? BoxDecoration(
                color: const Color(0xFFD1D9E6),
                borderRadius: currentTheme.cardBorderRadius,
                boxShadow: const [
                  BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(6, 6), blurRadius: 12),
                  BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 12),
                ],
              )
            : (isGlass
                ? BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: currentTheme.cardBorderRadius,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  )
                : (isNeo
                    ? BoxDecoration(
                        color: currentTheme.decksColor,
                        borderRadius: currentTheme.cardBorderRadius,
                        border: Border.all(color: Colors.black, width: 3.5),
                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                      )
                    : currentTheme.getCardDecoration(currentTheme.decksColor))));

    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.40,
      padding: const EdgeInsets.all(24),
      decoration: cardDecor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(
                Icons.volume_up_rounded, 
                color: isCyberpunk ? const Color(0xFF00F0FF) : textColor,
                size: 24,
              ),
              onPressed: () => TtsService.speak(
                card['prompt'].toString(),
                targetLanguage: _normalizeLangCode(card['front_lang']?.toString() ?? card['frontLang']?.toString() ?? _deckFrontLang),
              ),
            ),
          ),
          if (_isSvg(card['prompt'].toString()))
            _buildSvgImage(card['prompt'].toString(), height: 100)
          else
            Text(
              card['prompt'], 
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontSize: 24, 
                color: textColor, 
                fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold,
                fontFamily: isCyberpunk ? 'monospace' : null,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            isEn ? "Tap to flip" : "Ťukni pre otočenie", 
            style: TextStyle(
              color: isCyberpunk ? const Color(0xFF00F0FF).withValues(alpha: 0.8) : (isNeo ? Colors.black87 : (isSoft ? const Color(0xFF64748B) : textColor.withValues(alpha: 0.6))), 
              fontSize: 13, 
              fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.bold : FontWeight.normal,
              fontFamily: isCyberpunk ? 'monospace' : null,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Map<String, dynamic> card, AppThemeData currentTheme) {
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');
    final Color textColor = isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF0D9488) : ((isVibrant || isGlass) ? Colors.white : currentTheme.getContrastTextColor(currentTheme.successColor))));

    final cardDecor = isCyberpunk
        ? BoxDecoration(
            color: const Color(0xFF120E24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00F0FF), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          )
        : (isSoft
            ? BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: currentTheme.cardBorderRadius,
                boxShadow: const [
                  BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(6, 6), blurRadius: 12),
                  BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 12),
                ],
              )
            : (isNeo
                ? BoxDecoration(
                    color: currentTheme.successColor,
                    borderRadius: currentTheme.cardBorderRadius,
                    border: Border.all(color: Colors.black, width: 3.5),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                  )
                : currentTheme.getCardDecoration(currentTheme.successColor, isSelected: true)));

    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.40,
      padding: const EdgeInsets.all(24),
      decoration: cardDecor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(
                Icons.volume_up_rounded, 
                color: textColor,
                size: 24,
              ),
              onPressed: () => TtsService.speak(
                card['correct_answer'].toString(),
                targetLanguage: _normalizeLangCode(card['back_lang']?.toString() ?? card['backLang']?.toString() ?? _deckBackLang),
              ),
            ),
          ),
          if (_isSvg(card['prompt'].toString()))
            _buildSvgImage(card['prompt'].toString(), height: 60)
          else
            Text(
              card['prompt'], 
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontSize: 16, 
                color: isCyberpunk ? Colors.white70 : (isNeo ? Colors.black87 : (isSoft ? const Color(0xFF1E293B) : textColor.withValues(alpha: 0.85))), 
                fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.bold : FontWeight.w600,
                fontFamily: isCyberpunk ? 'monospace' : null,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16), 
            child: Divider(color: isCyberpunk ? const Color(0xFF00F0FF).withValues(alpha: 0.3) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF9EAEC6) : textColor.withValues(alpha: 0.4))), thickness: isNeo ? 2 : 1),
          ),
          if (_isSvg(card['correct_answer'].toString()))
            _buildSvgImage(card['correct_answer'].toString(), height: 80)
          else
            Text(
              card['correct_answer'], 
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontSize: 28, 
                color: textColor, 
                fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold,
                fontFamily: isCyberpunk ? 'monospace' : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomButton({
    required String text,
    required VoidCallback? onPressed,
    required AppThemeData currentTheme,
    Color? accentColor,
  }) {
    final Color buttonColor = accentColor ?? currentTheme.testSetupColor;
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isClean = currentTheme.id == 3 || currentTheme.name.toLowerCase().contains('clean');
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');
    final bool isEnabled = onPressed != null;

    final Color textColor = isEnabled
        ? (isCyberpunk 
            ? Colors.black 
            : (isClean
                ? Colors.white
                : (isNeo || isSoft ? (isSoft ? Colors.white : Colors.black) : Colors.white)))
        : (isNeo || isSoft || isClean ? Colors.black38 : Colors.white38);

    BoxDecoration buttonDecor;
    if (isCyberpunk) {
      buttonDecor = BoxDecoration(
        color: const Color(0xFF00F0FF),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      );
    } else if (isClean) {
      buttonDecor = BoxDecoration(
        color: isEnabled ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(color: const Color(0xFF334155), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );
    } else if (isSoft) {
      buttonDecor = BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: currentTheme.buttonBorderRadius,
        boxShadow: const [
          BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(4, 4), blurRadius: 8),
          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
        ],
      );
    } else if (isNeo) {
      buttonDecor = BoxDecoration(
        color: buttonColor,
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
      );
    } else if (isVibrant) {
      buttonDecor = BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF0844),
            Color(0xFFFFB199),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
      );
    } else if (isGlass) {
      buttonDecor = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF38BDF8).withValues(alpha: 0.25),
            const Color(0xFF818CF8).withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
      );
    } else {
      buttonDecor = currentTheme.getCardDecoration(buttonColor);
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: isCyberpunk ? BorderRadius.circular(8) : currentTheme.buttonBorderRadius,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: buttonDecor,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isNeo || isSoft || isCyberpunk || isClean ? FontWeight.w900 : FontWeight.bold,
                fontFamily: isCyberpunk ? 'monospace' : null,
                color: textColor,
                letterSpacing: isCyberpunk ? 1.5 : 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizUI(AppThemeData currentTheme, bool isEn) {
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final bool isClean = currentTheme.id == 3;
    final String cleanName = currentTheme.name.toLowerCase();
    final bool isCyberpunk = cleanName.contains('cyberpunk');
    final Color textColor = isCyberpunk ? Colors.white : (isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : ((isVibrant || isGlass) ? Colors.white : theme.colorScheme.onSurface)));

    Widget? hardcoreFeedbackWidget;

    if (_isHardcore && _isAnswerChecked && !_isBlindTest) {
      String typed = _selectedAnswer ?? "";
      String expected = _actualCorrectAnswer.trim().toLowerCase();
      if (typed == expected && typed.isNotEmpty) {
        hardcoreFeedbackWidget = Text(
          isEn ? "Excellent!" : "Výborne!", 
          style: TextStyle(color: isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? const Color(0xFF0D9488) : (isClean ? const Color(0xFF059669) : Colors.green))), fontWeight: FontWeight.w900, fontFamily: isCyberpunk ? 'monospace' : null),
        );
      } else {
        if (!_hideCorrectAnswer) {
          hardcoreFeedbackWidget = Text(
            isEn ? "Correct answer: $_actualCorrectAnswer" : "Odpoveď bola: $_actualCorrectAnswer", 
            style: TextStyle(color: isCyberpunk ? const Color(0xFFFF007F) : (isSoft ? const Color(0xFFE11D48) : (isClean ? const Color(0xFFDC2626) : currentTheme.errorColor)), fontWeight: FontWeight.w900, fontFamily: isCyberpunk ? 'monospace' : null),
          );
        }
      }
    }

    final String qWord = isEn ? "Question" : "Otázka";
    final String ofWord = isEn ? "of" : "z";

    String topTitleText = "$qWord ${_currentQuestionIndex + 1} $ofWord ${_questionCount.toInt()}";
    if (_isRemedialQuiz) {
      topTitleText = "${isEn ? 'Retake Test' : 'Opravný test'} • $qWord ${_currentQuestionIndex + 1} $ofWord ${_questionCount.toInt()}";
    } else if (_isDoubleTest) {
      topTitleText = "${isEn ? 'Round' : 'Kolo'} $_currentTestRound/2 • $qWord ${_currentQuestionIndex + 1} $ofWord ${_questionCount.toInt()}";
    }

    final BoxDecoration inputDecoration = isCyberpunk
        ? BoxDecoration(
            color: const Color(0xFF120E24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
          )
        : (isSoft
            ? BoxDecoration(
                color: const Color(0xFFC8D3E6),
                borderRadius: currentTheme.cardBorderRadius,
                boxShadow: const [
                  BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
                  BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                ],
              )
            : (isNeo
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: currentTheme.cardBorderRadius,
                    border: Border.all(color: Colors.black, width: 3.5),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                  )
                : (isGlass
                    ? BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: currentTheme.cardBorderRadius,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                      )
                    : ((isVibrant)
                        ? BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                            borderRadius: currentTheme.cardBorderRadius,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                          )
                        : BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: currentTheme.cardBorderRadius,
                            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.15), width: 1.2),
                          )))));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              topTitleText, 
              style: TextStyle(
                color: isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? (_isRemedialQuiz ? const Color(0xFFE11D48) : const Color(0xFF1E293B)) : (_isRemedialQuiz ? currentTheme.errorColor : textColor.withValues(alpha: 0.85)))), 
                fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold,
                fontFamily: isCyberpunk ? 'monospace' : null,
              ),
            ),
            if (_maxTime > 0)
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: isCyberpunk ? const Color(0xFFFF007F) : (isNeo ? Colors.black : (isSoft ? (_timeLeft <= 5 ? const Color(0xFFE11D48) : const Color(0xFF2563EB)) : (_timeLeft <= 5 ? currentTheme.errorColor : currentTheme.testSetupColor)))),
                  const SizedBox(width: 4),
                  Text("$_timeLeft s", style: TextStyle(fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold, fontFamily: isCyberpunk ? 'monospace' : null, color: isCyberpunk ? const Color(0xFFFF007F) : (isNeo ? Colors.black : (isSoft ? (_timeLeft <= 5 ? const Color(0xFFE11D48) : const Color(0xFF2563EB)) : (_timeLeft <= 5 ? currentTheme.errorColor : currentTheme.testSetupColor))))),
                ],
              )
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questionCount, 
          backgroundColor: isCyberpunk ? const Color(0xFF120E24) : (isNeo ? Colors.black12 : (isSoft ? const Color(0xFFC8D3E6) : textColor.withValues(alpha: 0.12))), 
          color: isCyberpunk ? const Color(0xFF00F0FF) : (isNeo ? Colors.black : (isSoft ? (_isRemedialQuiz ? const Color(0xFFE11D48) : const Color(0xFF2563EB)) : (_isRemedialQuiz ? currentTheme.errorColor : currentTheme.testSetupColor))),
        ),
        const SizedBox(height: 24),
        
        if (_isSvg(_currentQuestion!['prompt'].toString()))
          _buildSvgImage(_currentQuestion!['prompt'].toString(), height: 110)
        else
          Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44.0),
                child: Text(
                  _currentQuestion!['prompt'], 
                  textAlign: TextAlign.center, 
                  style: TextStyle(
                    fontSize: 20, 
                    color: textColor, 
                    fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold,
                    fontFamily: isCyberpunk ? 'monospace' : null,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.volume_up_rounded,
                    color: isCyberpunk ? const Color(0xFF00F0FF) : textColor,
                    size: 22,
                  ),
                  onPressed: () => TtsService.speak(
                    _currentQuestion!['prompt'].toString(),
                    targetLanguage: _normalizeLangCode(
                      _currentQuestion!['front_lang']?.toString() ??
                      _currentQuestion!['frontLang']?.toString() ??
                      _deckFrontLang,
                    ),
                  ),
                ),
              ),
            ],
          ),
        
        if (_isSwapQuestion && !_isRemedialQuiz && !_hasUsedSwap && !_isAnswerChecked) ...[
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _swapCurrentQuestion,
              borderRadius: isCyberpunk ? BorderRadius.circular(8) : currentTheme.buttonBorderRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: isCyberpunk
                    ? BoxDecoration(
                        color: const Color(0xFF120E24),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
                      )
                    : (isSoft
                        ? BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: currentTheme.buttonBorderRadius,
                            boxShadow: const [
                              BoxShadow(color: Color(0xFF1D4ED8), offset: Offset(2, 2), blurRadius: 4),
                              BoxShadow(color: Color(0xFF93C5FD), offset: Offset(-2, -2), blurRadius: 4),
                            ],
                          )
                        : (isGlass
                            ? BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: currentTheme.buttonBorderRadius,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                              )
                            : (isNeo
                                ? BoxDecoration(
                                    color: const Color(0xFFFFB6C1),
                                    borderRadius: currentTheme.buttonBorderRadius,
                                    border: Border.all(color: Colors.black, width: 3.5),
                                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                                  )
                                : currentTheme.getCardDecoration(currentTheme.testSetupColor)))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded, 
                      size: 18, 
                      color: isCyberpunk 
                          ? const Color(0xFF00F0FF) 
                          : (isNeo ? Colors.black : (isSoft ? Colors.white : ((isVibrant || isGlass) ? Colors.white : currentTheme.getContrastTextColor(currentTheme.testSetupColor)))),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEn ? "Swap card (1x)" : "Vymeň kartu (1x)", 
                      style: TextStyle(
                        fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold,
                        fontFamily: isCyberpunk ? 'monospace' : null,
                        color: isCyberpunk 
                            ? const Color(0xFF00F0FF) 
                            : (isNeo ? Colors.black : (isSoft ? Colors.white : ((isVibrant || isGlass) ? Colors.white : currentTheme.getContrastTextColor(currentTheme.testSetupColor)))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
        
        if (_isHardcore) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: inputDecoration,
            child: TextField(
              controller: _hardcoreController,
              textAlign: TextAlign.center,
              enabled: !_isAnswerChecked, 
              style: TextStyle(fontSize: 18, fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold, fontFamily: isCyberpunk ? 'monospace' : null, color: textColor),
              decoration: InputDecoration(
                hintText: isEn ? "Type answer here..." : "Napíš odpoveď sem...",
                hintStyle: TextStyle(color: isCyberpunk ? Colors.white38 : (isSoft ? const Color(0xFF64748B) : textColor.withValues(alpha: 0.4)), fontFamily: isCyberpunk ? 'monospace' : null),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _checkQuizAnswer(""), 
            ),
          ),
          if (hardcoreFeedbackWidget != null) ...[const SizedBox(height: 8), hardcoreFeedbackWidget],
          const SizedBox(height: 16),
          _buildCustomButton(
            text: isEn ? "Submit" : "Potvrdiť",
            onPressed: _isAnswerChecked ? null : () => _checkQuizAnswer(""),
            currentTheme: currentTheme,
          ),
        ] else ...[
          ..._currentOptions.map((option) {
            BoxDecoration decoration;
            Color optionTextColor;
            double opacity = 1.0;

            if (_isAnswerChecked) {
              if (_isBlindTest) {
                if (option == _selectedAnswer) {
                  decoration = isClean
                      ? BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: currentTheme.buttonBorderRadius,
                          border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                        )
                      : (isCyberpunk
                          ? BoxDecoration(
                              color: const Color(0xFF00F0FF),
                              borderRadius: BorderRadius.circular(8),
                            )
                          : (isSoft
                              ? BoxDecoration(
                                  color: const Color(0xFFD6E4FF),
                                  borderRadius: currentTheme.buttonBorderRadius,
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
                                    BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                                  ],
                                )
                              : (isGlass
                                  ? BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                          const Color(0xFF818CF8).withValues(alpha: 0.3),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: currentTheme.buttonBorderRadius,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                                    )
                                  : (isNeo
                                      ? BoxDecoration(
                                          color: const Color(0xFFFFB6C1),
                                          borderRadius: currentTheme.buttonBorderRadius,
                                          border: Border.all(color: Colors.black, width: 3.5),
                                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                                        )
                                      : currentTheme.getCardDecoration(currentTheme.testSetupColor)))));
                  optionTextColor = isClean
                      ? const Color(0xFF2563EB)
                      : (isCyberpunk ? Colors.black : (isNeo ? Colors.black : (isSoft ? const Color(0xFF2563EB) : ((isVibrant || isGlass) ? Colors.white : currentTheme.getContrastTextColor(currentTheme.testSetupColor)))));
                } else {
                  decoration = _getUncheckedOptionDecoration(currentTheme);
                  optionTextColor = _getUncheckedOptionTextColor(currentTheme);
                  opacity = 0.45;
                }
              } else {
                if (option == _actualCorrectAnswer && !_hideCorrectAnswer) {
                  decoration = isClean
                      ? BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: currentTheme.buttonBorderRadius,
                          border: Border.all(color: const Color(0xFF059669), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.10),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        )
                      : (isCyberpunk
                          ? BoxDecoration(
                              color: const Color(0xFF00F0FF),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            )
                          : (isSoft
                              ? BoxDecoration(
                                  color: const Color(0xFFCCFBF1),
                                  borderRadius: currentTheme.buttonBorderRadius,
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
                                    BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                                  ],
                                )
                              : (isNeo
                                  ? BoxDecoration(
                                      color: currentTheme.successColor,
                                      borderRadius: currentTheme.buttonBorderRadius,
                                      border: Border.all(color: Colors.black, width: 3.5),
                                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                                    )
                                  : currentTheme.getCardDecoration(currentTheme.successColor))));
                  optionTextColor = isClean
                      ? const Color(0xFF059669)
                      : (isCyberpunk ? Colors.black : (isNeo ? Colors.black : (isSoft ? const Color(0xFF0D9488) : ((isVibrant || isGlass) ? Colors.white : currentTheme.getContrastTextColor(currentTheme.successColor)))));
                } else if (option == _selectedAnswer) {
                  decoration = isClean
                      ? BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: currentTheme.buttonBorderRadius,
                          border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        )
                      : (isCyberpunk
                          ? BoxDecoration(
                              color: const Color(0xFFFF007F),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF007F).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            )
                          : (isSoft
                              ? BoxDecoration(
                                  color: const Color(0xFFFFE4E6),
                                  borderRadius: currentTheme.buttonBorderRadius,
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
                                    BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                                  ],
                                )
                              : (isNeo
                                  ? BoxDecoration(
                                      color: currentTheme.errorColor,
                                      borderRadius: currentTheme.buttonBorderRadius,
                                      border: Border.all(color: Colors.black, width: 3.5),
                                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                                    )
                                  : currentTheme.getCardDecoration(currentTheme.errorColor))));
                  optionTextColor = isClean
                      ? const Color(0xFFDC2626)
                      : (isCyberpunk ? Colors.white : (isNeo ? Colors.black : (isSoft ? const Color(0xFFE11D48) : ((isVibrant || isGlass) ? Colors.white : currentTheme.getContrastTextColor(currentTheme.errorColor)))));
                } else {
                  decoration = _getUncheckedOptionDecoration(currentTheme);
                  optionTextColor = _getUncheckedOptionTextColor(currentTheme);
                  opacity = 0.4;
                }
              }
            } else {
              decoration = _getUncheckedOptionDecoration(currentTheme);
              optionTextColor = _getUncheckedOptionTextColor(currentTheme);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: opacity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isAnswerChecked ? null : () => _checkQuizAnswer(option),
                    borderRadius: isCyberpunk ? BorderRadius.circular(8) : currentTheme.buttonBorderRadius,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 54),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      alignment: Alignment.center,
                      decoration: decoration,
                      child: _isSvg(option)
                          ? _buildSvgImage(option, height: 35)
                          : Text(
                              option, 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: isNeo || isSoft || isCyberpunk ? FontWeight.w900 : FontWeight.bold,
                                fontFamily: isCyberpunk ? 'monospace' : null,
                                color: optionTextColor,
                              ), 
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}