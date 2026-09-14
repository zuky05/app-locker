import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadGraceCountAndPremium();
  }

  Future<void> _loadGraceCountAndPremium() async {
    int count = await PrefsHelper.getRemainingGraceAttempts();
    bool premiumStatus = await RevenueCatService.isPremium(); 
    
    if (mounted) {
      setState(() {
        remainingGrace = count;
        isPremium = premiumStatus;
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

    // Dekorácia karty podľa témy
    BoxDecoration cardDecoration;
    if (isNeo) {
      cardDecoration = BoxDecoration(
        color: currentTheme.testSetupColor,
        borderRadius: currentTheme.cardBorderRadius,
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      );
    } else if (isVibrant) {
      cardDecoration = currentTheme.getCardDecoration(currentTheme.testSetupColor);
    } else {
      cardDecoration = BoxDecoration(
        color: theme.cardColor, 
        borderRadius: currentTheme.cardBorderRadius,
        border: currentTheme.cardBorder ?? 
            Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        boxShadow: currentTheme.cardShadows ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25), 
            blurRadius: 20, 
            spreadRadius: 5,
          ),
        ],
        gradient: currentTheme.cardGradient,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: cardDecoration,
                child: isLoading
                    ? SizedBox(
                        height: 150,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: isVibrant ? Colors.white : (isNeo ? Colors.black : theme.colorScheme.primary),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded, 
                            size: 50, 
                            color: isVibrant ? Colors.white : (isNeo ? Colors.black : currentTheme.warningColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Zablokované!",
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold,
                              color: isVibrant ? Colors.white : (isNeo ? Colors.black : theme.colorScheme.onSurface),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Hlavné tlačidlo pre spustenie testu
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: isVibrant ? Colors.white : currentTheme.primaryButtonBg,
                              foregroundColor: isVibrant ? Colors.black : currentTheme.primaryButtonFg,
                              elevation: isVibrant ? 0 : (currentTheme.cardShadows != null ? 2 : 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: currentTheme.buttonBorderRadius,
                                side: isVibrant 
                                    ? const BorderSide(color: Colors.white, width: 2.0)
                                    : (currentTheme.buttonBorder ?? BorderSide.none),
                              ),
                            ),
                            onPressed: _startTest,
                            child: const Text(
                              "Spustiť TEST", 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),

                          if (!widget.isFromNotification) ...[
                            const SizedBox(height: 12),

                            if (widget.isTimeout)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  "Čas vypršal! Teraz ťa zachráni už len test.",
                                  style: TextStyle(
                                    color: isVibrant ? Colors.white.withValues(alpha: 0.9) : (isNeo ? Colors.black : currentTheme.errorColor), 
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else if (isPremium || remainingGrace > 0)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  backgroundColor: isVibrant 
                                      ? Colors.white.withValues(alpha: 0.2) 
                                      : currentTheme.circleAvatarBg,
                                  foregroundColor: isVibrant 
                                      ? Colors.white 
                                      : (isNeo ? Colors.black : theme.colorScheme.onSurface),
                                  elevation: isVibrant ? 0 : (currentTheme.cardShadows != null ? 1 : 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: currentTheme.buttonBorderRadius,
                                    side: isVibrant 
                                        ? BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5)
                                        : (currentTheme.buttonBorder ?? BorderSide.none),
                                  ),
                                ),
                                onPressed: _useGracePeriod,
                                child: Text(
                                  isPremium 
                                      ? "Odomknúť na 1 minútu"
                                      : "Odpustok na 1 min. ($remainingGrace/3 dnes)", 
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  "Dnešné odpustky si už vyčerpal!",
                                  style: TextStyle(
                                    color: isVibrant ? Colors.white.withValues(alpha: 0.9) : (isNeo ? Colors.black : currentTheme.errorColor), 
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}