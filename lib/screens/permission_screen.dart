import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';

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

        // Ak máme VŠETKY TRI povolenia, ideme do hlavnej aplikácie
        if (overlay && accessibility && notification) {
          _navigateToMain();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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
        // Vyvolá štandardný systémový pop-up pre notifikácie
        final status = await Permission.notification.request();
        if (status.isGranted) {
          _checkPermission();
        } else if (status.isPermanentlyDenied) {
          openAppSettings(); // Ak používateľ natvrdo zakázal pop-up
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

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    final bool allGranted = isOverlayGranted && isAccessibilityGranted && isNotificationGranted;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kruhový kontajner pre ikonu bezpečnosti
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: currentTheme.id == 2 ? Colors.white : theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: currentTheme.id == 2 
                      ? Border.all(color: Colors.black, width: 3.5) 
                      : (currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))),
                  boxShadow: currentTheme.id == 2 ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4))] : null,
                ),
                child: Icon(
                  Icons.security_rounded,
                  size: 70,
                  color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.primary,
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
                  fontSize: 15,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Overlay
              _buildPermissionTile(
                title: "Prekrytie aplikácií (Overlay)",
                isGranted: isOverlayGranted,
                currentTheme: currentTheme,
              ),

              const SizedBox(height: 10),

              // 2. Accessibility
              _buildPermissionTile(
                title: "Zjednodušenie prístupu (Accessibility)",
                isGranted: isAccessibilityGranted,
                currentTheme: currentTheme,
              ),

              const SizedBox(height: 10),

              // 3. Notifications (Upozornenia)
              _buildPermissionTile(
                title: "Upozornenia a odpočet času (Notifications)",
                isGranted: isNotificationGranted,
                currentTheme: currentTheme,
              ),

              const SizedBox(height: 32),

              // Dynamické tlačidlo
              ElevatedButton.icon(
                onPressed: allGranted ? _navigateToMain : _openSettingsOrRequest,
                icon: Icon(allGranted ? Icons.arrow_forward : Icons.settings),
                label: Text(
                  allGranted
                      ? "Pokračovať"
                      : (!isOverlayGranted
                          ? "Povoliť prekrytie"
                          : (!isAccessibilityGranted
                              ? "Povoliť Zjednodušenie prístupu"
                              : "Povoliť Upozornenia")),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: currentTheme.id == 2 ? const Color(0xFF00E676) : theme.colorScheme.primary,
                  foregroundColor: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.buttonBorderRadius,
                    side: currentTheme.id == 2 ? const BorderSide(color: Colors.black, width: 3.5) : BorderSide.none,
                  ),
                  elevation: currentTheme.id == 2 ? 0 : 2,
                ),
              ),
            ],
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
    final bool isLight = theme.brightness == Brightness.light;
    
    final Color successAccent = const Color(0xFF00E676);
    final Color successBgLight = Colors.green.shade100;
    final Color successBgDark = successAccent.withValues(alpha: 0.15);

    // Ak je splnené -> zelené pozadie, ak nie -> pevná biela (resp. cardColor ak je tmavý režim), aby nebola priehľadná
    final Color bgColor = isGranted
        ? (currentTheme.id == 2 ? successAccent : (isLight ? successBgLight : successBgDark))
        : (isLight ? Colors.white : theme.cardColor);

    final Color borderColor = isGranted
        ? (currentTheme.id == 2 ? Colors.black : successAccent)
        : (currentTheme.id == 2 ? Colors.black : const Color(0xFFFF9100)); // Výrazná oranžová pre neaktívne

    final Color contentColor = isGranted
        ? (currentTheme.id == 2 ? Colors.black : (isLight ? Colors.green.shade800 : successAccent))
        : theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: currentTheme.cardBorderRadius,
        border: Border.all(
          color: borderColor, 
          width: currentTheme.id == 2 ? 3.5 : 2.0,
        ),
        boxShadow: currentTheme.id == 2 ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))] : currentTheme.cardShadows,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isGranted ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isGranted 
                  ? (currentTheme.id == 2 ? Colors.black : successAccent) 
                  : const Color(0xFFFF9100),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: contentColor,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}