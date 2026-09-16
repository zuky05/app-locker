import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prefs_helper.dart';
import '../themes/theme_provider.dart';
import 'quiz_overlay_screen.dart';
import '../services/revenuecat_service.dart';

class BlockChoiceScreen extends StatefulWidget {
  final bool isTimeout;
  final bool isFromNotification;

  const BlockChoiceScreen({
    super.key, 
    required this.isTimeout, 
    this.isFromNotification = false,
  });

  @override
  State<BlockChoiceScreen> createState() => _BlockChoiceScreenState();
}

class _BlockChoiceScreenState extends State<BlockChoiceScreen> {
  int remainingGrace = 0;
  bool isLoading = true;
  bool isPremium = false;
  bool isLearningMode = false;

  @override
  void initState() {
    super.initState();
    _loadGraceCountAndPremium();
  }

  Future<void> _loadGraceCountAndPremium() async {
    int count = await PrefsHelper.getRemainingGraceAttempts();
    bool premiumStatus = await RevenueCatService.isPremium(); 
    
    final prefs = await SharedPreferences.getInstance();
    bool learningMode = prefs.getBool('test_isLearningMode') ?? false;
    
    if (mounted) {
      setState(() {
        remainingGrace = count;
        isPremium = premiumStatus;
        isLearningMode = learningMode;
        isLoading = false;
      });
    }
  }

  void _useGracePeriod() async {
    if (isPremium) {
      const platform = MethodChannel('brainlock.channel');
      try {
        await platform.invokeMethod('unlockApp', {'seconds': 60, 'maxCap': 60});
        if (mounted) SystemNavigator.pop(); 
      } catch (e) {
        debugPrint("Chyba: $e");
      }
      return;
    }

    bool success = await PrefsHelper.useGraceAttempt();
    if (success) {
      const platform = MethodChannel('brainlock.channel');
      try {
        await platform.invokeMethod('unlockApp', {'seconds': 60, 'maxCap': 60});
        if (mounted) SystemNavigator.pop();
      } catch (e) {
        debugPrint("Chyba: $e");
      }
    }
  }

  void _startTest() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => const QuizOverlayScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    final bool isNeo = currentTheme.id == 2;
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4 || currentTheme.id.toString() == '4';
    final bool isSoft = currentTheme.id == 1;

    BoxDecoration cardDecoration;
    if (isSoft) {
      cardDecoration = BoxDecoration(
        color: const Color(0xFFD1D9E6),
        borderRadius: currentTheme.cardBorderRadius,
        // 🟢 ÚPLNE BEZ TIEŇOV A ŽIARE
        boxShadow: const [],
      );
    } else if (isNeo) {
      cardDecoration = BoxDecoration(
        color: const Color(0xFFF7EED2),
        borderRadius: currentTheme.cardBorderRadius,
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      );
    } else if (isGlass) {
      cardDecoration = BoxDecoration(
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
      cardDecoration = currentTheme.getCardDecoration(currentTheme.testSetupColor).copyWith(
        boxShadow: const [],
      );
    } else {
      cardDecoration = BoxDecoration(
        color: theme.cardColor, 
        borderRadius: currentTheme.cardBorderRadius,
        border: currentTheme.cardBorder ?? 
            Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        gradient: currentTheme.cardGradient,
        boxShadow: const [],
      );
    }

    BoxBorder? primaryButtonBorder;
    if (isNeo) {
      primaryButtonBorder = Border.all(color: Colors.black, width: 3.5);
    } else if (isVibrant || isGlass) {
      primaryButtonBorder = Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5);
    } else if (!isSoft && currentTheme.buttonBorder != null) {
      primaryButtonBorder = Border.fromBorderSide(currentTheme.buttonBorder!);
    }

    BoxBorder? secondaryButtonBorder;
    if (isNeo) {
      secondaryButtonBorder = Border.all(color: Colors.black, width: 3.5);
    } else if (isVibrant || isGlass) {
      secondaryButtonBorder = Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5);
    } else if (!isSoft && currentTheme.buttonBorder != null) {
      secondaryButtonBorder = Border.fromBorderSide(currentTheme.buttonBorder!);
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.40),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.92,
                decoration: cardDecoration,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: isLoading
                      ? SizedBox(
                          height: 180,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: isNeo ? Colors.black : (isSoft ? const Color(0xFF3B82F6) : (isVibrant || isGlass ? Colors.white : currentTheme.testSetupColor)),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Neumorfné puzdro varovania
                            isSoft
                                ? Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFEF3C7),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
                                        BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 40,
                                      color: Color(0xFFD97706),
                                    ),
                                  )
                                : Icon(
                                    Icons.warning_amber_rounded, 
                                    size: 54, 
                                    color: isNeo ? Colors.black : (isVibrant || isGlass ? Colors.white : currentTheme.warningColor),
                                  ),
                            const SizedBox(height: 16),
                            Text(
                              "Zablokované!",
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: isNeo || isSoft ? FontWeight.w900 : FontWeight.bold,
                                color: isNeo ? Colors.black : (isSoft ? const Color(0xFF1E293B) : (isVibrant || isGlass ? Colors.white : theme.colorScheme.onSurface)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Hlavné tlačidlo pre Test / Učenie
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _startTest,
                                borderRadius: currentTheme.buttonBorderRadius,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  decoration: isSoft
                                      ? BoxDecoration(
                                          color: const Color(0xFF3B82F6),
                                          borderRadius: currentTheme.buttonBorderRadius,
                                          boxShadow: const [
                                            BoxShadow(color: Color(0xFF1D4ED8), offset: Offset(3, 3), blurRadius: 6),
                                            BoxShadow(color: Color(0xFF93C5FD), offset: Offset(-2, -2), blurRadius: 5),
                                          ],
                                        )
                                      : BoxDecoration(
                                          gradient: isVibrant
                                              ? const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFF0844),
                                                    Color(0xFFFFB199),
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                )
                                              : (isGlass
                                                  ? LinearGradient(
                                                      colors: [
                                                        const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                                        const Color(0xFF818CF8).withValues(alpha: 0.25),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    )
                                                  : null),
                                          color: isNeo 
                                              ? currentTheme.successColor 
                                              : (!isVibrant && !isGlass ? currentTheme.primaryButtonBg : null),
                                          borderRadius: currentTheme.buttonBorderRadius,
                                          border: primaryButtonBorder,
                                          boxShadow: isNeo ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)] : null,
                                        ),
                                  child: Text(
                                    isLearningMode ? "Spustiť UČENIE" : "Spustiť TEST", 
                                    style: TextStyle(
                                      fontSize: 16, 
                                      fontWeight: isNeo || isSoft ? FontWeight.w900 : FontWeight.bold,
                                      color: isNeo ? Colors.black : Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            if (!widget.isFromNotification) ...[
                              const SizedBox(height: 14),

                              if (widget.isTimeout)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    isLearningMode 
                                        ? "Čas vypršal! Teraz ťa zachráni už len učenie." 
                                        : "Čas vypršal! Teraz ťa zachráni už len test.",
                                    style: TextStyle(
                                      color: isNeo ? Colors.black : (isSoft ? const Color(0xFFE11D48) : ((isVibrant || isGlass) ? Colors.white.withValues(alpha: 0.9) : currentTheme.errorColor)), 
                                      fontWeight: isNeo || isSoft ? FontWeight.w900 : FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else if (isPremium || remainingGrace > 0)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _useGracePeriod,
                                    borderRadius: currentTheme.buttonBorderRadius,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      alignment: Alignment.center,
                                      decoration: isSoft
                                          ? BoxDecoration(
                                              color: const Color(0xFFC8D3E6),
                                              borderRadius: currentTheme.buttonBorderRadius,
                                              boxShadow: const [
                                                BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
                                                BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                                              ],
                                            )
                                          : BoxDecoration(
                                              color: isNeo 
                                                  ? Colors.white 
                                                  : (isVibrant || isGlass ? Colors.white.withValues(alpha: 0.12) : currentTheme.circleAvatarBg),
                                              borderRadius: currentTheme.buttonBorderRadius,
                                              border: secondaryButtonBorder,
                                              boxShadow: isNeo ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)] : null,
                                            ),
                                      child: Text(
                                        isPremium 
                                            ? "Odomknúť na 1 minútu"
                                            : "Odpustok na 1 min. ($remainingGrace/3 dnes)", 
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isNeo || isSoft ? FontWeight.w900 : FontWeight.bold,
                                          color: isNeo ? Colors.black : (isSoft ? const Color(0xFF334155) : ((isVibrant || isGlass) ? Colors.white : theme.colorScheme.onSurface)),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    "Dnešné odpustky si už vyčerpal!",
                                    style: TextStyle(
                                      color: isNeo ? Colors.black : (isSoft ? const Color(0xFFE11D48) : ((isVibrant || isGlass) ? Colors.white.withValues(alpha: 0.9) : currentTheme.errorColor)), 
                                      fontWeight: isNeo || isSoft ? FontWeight.w900 : FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}