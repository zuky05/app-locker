import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';
import '../themes/themed_background.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  static const platform = MethodChannel('brainlock.channel');
  
  bool isOverlayGranted = false;
  bool isAccessibilityGranted = false;
  bool isNotificationGranted = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    try {
      final bool overlay = await platform.invokeMethod('isOverlayGranted') ?? false;
      final bool accessibility = await platform.invokeMethod('isAccessibilityGranted') ?? false;
      final bool notification = await Permission.notification.isGranted;

      if (mounted) {
        setState(() {
          isOverlayGranted = overlay;
          isAccessibilityGranted = accessibility;
          isNotificationGranted = notification;
          isLoading = false;
        });

        if (overlay && accessibility && notification) {
          _navigateToMain();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _openSettingsOrRequest() async {
    try {
      if (!isOverlayGranted) {
        await platform.invokeMethod('requestOverlayPermission');
      } else if (!isAccessibilityGranted) {
        await platform.invokeMethod('openAccessibilitySettings');
      } else if (!isNotificationGranted) {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          _checkPermission();
        } else if (status.isPermanentlyDenied) {
          openAppSettings();
        }
      }
    } catch (e) {
      debugPrint("Chyba vyžadovania povolení: $e");
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;

    if (isLoading) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(
              color: isVibrant ? currentTheme.decksColor : currentTheme.buttonBorder.color,
            ),
          ),
        ),
      );
    }

    final bool allGranted = isOverlayGranted && isAccessibilityGranted && isNotificationGranted;
    final Color primaryAccent = currentTheme.decksColor;
    final Color buttonBgColor = allGranted ? currentTheme.successColor : primaryAccent;
    final Color buttonFgColor = isVibrant ? Colors.white : currentTheme.getContrastTextColor(buttonBgColor);

    // Farby pre hornú kruhovú ikonu
    final Color circleBgColor = isVibrant 
        ? currentTheme.decksColor 
        : (isNeo ? theme.cardColor : currentTheme.getTileBg(isGranted: false, accentColor: currentTheme.buttonBorder.color));
    
    final Color circleIconColor = isVibrant 
        ? Colors.white 
        : currentTheme.getIconColor(currentTheme.buttonBorder.color);

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Ikona zabezpečenia HORE
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: circleBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isVibrant ? Colors.black : currentTheme.buttonBorder.color, 
                      width: isVibrant ? 2.5 : 2.0,
                    ),
                    boxShadow: isVibrant 
                        ? const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] 
                        : currentTheme.cardShadows,
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    size: 64,
                    color: circleIconColor,
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  "Vyžaduje sa aktivácia",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Pre správne fungovanie blokovania a odpočítavania času je potrebné povoliť nasledujúce tri funkcie.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                _buildPermissionTile(
                  title: "Prekrytie aplikácií (Overlay)",
                  isGranted: isOverlayGranted,
                  currentTheme: currentTheme,
                ),
                const SizedBox(height: 12),
                _buildPermissionTile(
                  title: "Zjednodušenie prístupu (Accessibility)",
                  isGranted: isAccessibilityGranted,
                  currentTheme: currentTheme,
                ),
                const SizedBox(height: 12),
                _buildPermissionTile(
                  title: "Upozornenia a odpočet času (Notifications)",
                  isGranted: isNotificationGranted,
                  currentTheme: currentTheme,
                ),

                const Spacer(),

                // Hlavné akčné tlačidlo DOLE
                ElevatedButton.icon(
                  onPressed: allGranted ? _navigateToMain : _openSettingsOrRequest,
                  icon: Icon(
                    allGranted ? Icons.arrow_forward : Icons.settings,
                    color: buttonFgColor,
                  ),
                  label: Text(
                    allGranted
                        ? "Pokračovať"
                        : (!isOverlayGranted
                            ? "Povoliť prekrytie"
                            : (!isAccessibilityGranted
                                ? "Povoliť Zjednodušenie prístupu"
                                : "Povoliť Upozornenia")),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: buttonFgColor,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: buttonBgColor,
                    foregroundColor: buttonFgColor,
                    elevation: isVibrant ? 0 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: currentTheme.buttonBorderRadius,
                      side: BorderSide(
                        color: isVibrant ? Colors.black : currentTheme.buttonBorder.color, 
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title, 
    required bool isGranted,
    required AppThemeData currentTheme,
  }) {
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final Color accentColor = isGranted ? currentTheme.successColor : currentTheme.warningColor;

    BoxDecoration decoration;
    Color textColor;
    Color iconColor;

    if (isVibrant) {
      decoration = BoxDecoration(
        color: accentColor,
        borderRadius: currentTheme.cardBorderRadius,
        border: Border.all(color: Colors.black, width: 2.0),
      );
      textColor = Colors.black;
      iconColor = Colors.black;
    } else {
      decoration = currentTheme.getCardDecoration(accentColor, isSelected: isGranted);
      textColor = theme.colorScheme.onSurface;
      iconColor = currentTheme.getIconColor(accentColor);
    }

    return Container(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              isGranted ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}