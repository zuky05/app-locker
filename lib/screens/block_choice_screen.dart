import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/prefs_helper.dart';
import '../themes/theme_provider.dart';
import 'quiz_overlay_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadGraceCount();
  }

  Future<void> _loadGraceCount() async {
    int count = await PrefsHelper.getRemainingGraceAttempts();
    setState(() {
      remainingGrace = count;
      isLoading = false;
    });
  }

  void _useGracePeriod() async {
    bool success = await PrefsHelper.useGraceAttempt();
    if (success) {
      const platform = MethodChannel('brainlock.channel');
      try {
        await platform.invokeMethod('unlockApp', {'minutes': 1});
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
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: currentTheme.cardBorderRadius,
                  border: currentTheme.id == 2 
                      ? Border.all(color: Colors.black, width: 3.5) 
                      : (currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                  boxShadow: currentTheme.id == 2 
                      ? const [BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0)]
                      : (currentTheme.cardShadows ?? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25), 
                            blurRadius: 20, 
                            spreadRadius: 5,
                          )
                        ]),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: currentTheme.cardBorderRadius,
                    gradient: currentTheme.id == 2 ? null : currentTheme.cardGradient,
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
                              color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.tertiary,
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
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                elevation: currentTheme.id == 2 ? 0 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: currentTheme.buttonBorderRadius,
                                  side: currentTheme.id == 2 
                                      ? const BorderSide(color: Colors.black, width: 2.5) 
                                      : BorderSide.none,
                                ),
                              ),
                              onPressed: _startTest,
                              child: const Text("Spustiť TEST (5 minút)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),

                            if (!widget.isFromNotification) ...[
                              const SizedBox(height: 12),

                              if (widget.isTimeout)
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Text(
                                    "Čas vypršal! Teraz ťa zachráni už len test.",
                                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else if (remainingGrace > 0)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                                    foregroundColor: Colors.black87,
                                    elevation: currentTheme.id == 2 ? 0 : 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: currentTheme.buttonBorderRadius,
                                      side: currentTheme.id == 2 
                                          ? const BorderSide(color: Colors.black, width: 2.5)
                                          : BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1),
                                    ),
                                  ),
                                  onPressed: _useGracePeriod,
                                  child: Text("Odpustok na 1 min. ($remainingGrace/3 dnes)", style: const TextStyle(fontWeight: FontWeight.bold)),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Text(
                                    "Dnešné odpustky si už vyčerpal!",
                                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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