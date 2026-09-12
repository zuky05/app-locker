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

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
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
                ),
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded, 
                            size: 50, 
                            color: currentTheme.warningColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Zablokované!",
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: currentTheme.primaryButtonBg,
                              foregroundColor: currentTheme.primaryButtonFg,
                              elevation: currentTheme.cardShadows != null ? 2 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: currentTheme.buttonBorderRadius,
                                side: currentTheme.buttonBorder,
                              ),
                            ),
                            onPressed: _startTest,
                            child: const Text(
                              "Spustiť TEST (5 minút)", 
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
                                    color: currentTheme.errorColor, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (isPremium || remainingGrace > 0)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  backgroundColor: currentTheme.circleAvatarBg,
                                  foregroundColor: theme.colorScheme.onSurface,
                                  elevation: currentTheme.cardShadows != null ? 1 : 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: currentTheme.buttonBorderRadius,
                                    side: currentTheme.buttonBorder,
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
                                    color: currentTheme.errorColor, 
                                    fontWeight: FontWeight.bold,
                                  ),
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