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
  bool isBatteryOptimizationGranted = false;
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
      final bool battery = await platform.invokeMethod('isBatteryOptimizationIgnored') ?? false;

      if (mounted) {
        setState(() {
          isOverlayGranted = overlay;
          isAccessibilityGranted = accessibility;
          isNotificationGranted = notification;
          isBatteryOptimizationGranted = battery;
          isLoading = false;
        });

        if (overlay && accessibility && notification && battery) {
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
      } else if (!isBatteryOptimizationGranted) {
        await platform.invokeMethod('requestIgnoreBatteryOptimizations');
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
    final bool isGlass = currentTheme.id == 4;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;

    if (isLoading) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(
              color: isSoft ? const Color(0xFF2563EB) : (isVibrant ? currentTheme.decksColor : currentTheme.theme.primaryColor),
            ),
          ),
        ),
      );
    }

    final bool allGranted = isOverlayGranted && isAccessibilityGranted && isNotificationGranted && isBatteryOptimizationGranted;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                
                // 🟢 Ikona štítu hore (Soft Neumorphic 3D krúžok)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: isSoft
                      ? const BoxDecoration(
                          color: Color(0xFFD1D9E6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(5, 5), blurRadius: 10),
                            BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
                          ],
                        )
                      : (isVibrant
                          ? BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF00F5FF).withValues(alpha: 0.6), width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F5FF).withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            )
                          : (isGlass
                              ? BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF0F172A).withValues(alpha: 0.75),
                                      const Color(0xFF1E1B4B).withValues(alpha: 0.75),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.7),
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFC084FC).withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                )
                              : BoxDecoration(
                                  color: isNeo ? Colors.white : currentTheme.getTileBg(isGranted: false, accentColor: currentTheme.buttonBorder.color),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isNeo ? Colors.black : currentTheme.buttonBorder.color, 
                                    width: isNeo ? 3.5 : 2.0,
                                  ),
                                  boxShadow: isNeo 
                                      ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)]
                                      : currentTheme.cardShadows,
                                ))),
                  child: Icon(
                    Icons.security_rounded,
                    size: 58,
                    color: isSoft 
                        ? const Color(0xFF2563EB) 
                        : (isVibrant 
                            ? const Color(0xFF00F5FF) 
                            : (isGlass 
                                ? const Color(0xFF38BDF8) 
                                : (isNeo ? Colors.black : currentTheme.getIconColor(currentTheme.buttonBorder.color)))),
                  ),
                ),
                const SizedBox(height: 24),

                // 🟢 Neumorfný box pre názov a popis
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: isSoft
                      ? BoxDecoration(
                          color: const Color(0xFFD1D9E6),
                          borderRadius: currentTheme.cardBorderRadius,
                          boxShadow: const [
                            BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(6, 6), blurRadius: 12),
                            BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 12),
                          ],
                        )
                      : (isVibrant
                          ? BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.82),
                              borderRadius: currentTheme.cardBorderRadius,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            )
                          : (isGlass
                              ? BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.55),
                                  borderRadius: currentTheme.cardBorderRadius,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                )
                              : BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: currentTheme.cardBorderRadius,
                                  border: isNeo
                                      ? Border.all(color: Colors.black, width: 3.5)
                                      : Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                                  boxShadow: isNeo
                                      ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)]
                                      : currentTheme.cardShadows,
                                ))),
                  child: Column(
                    children: [
                      Text(
                        "Vyžaduje sa aktivácia",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: isNeo || isSoft ? FontWeight.w900 : FontWeight.bold,
                          color: isSoft ? const Color(0xFF1E293B) : ((isVibrant || isGlass) ? Colors.white : Colors.black),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Pre správne a neprerušované fungovanie blokovania je potrebné povoliť nasledujúce štyri funkcie.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isNeo || isSoft ? FontWeight.bold : FontWeight.normal,
                          color: isSoft 
                              ? const Color(0xFF64748B) 
                              : ((isVibrant || isGlass)
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : (isNeo ? Colors.black87 : theme.colorScheme.onSurface.withValues(alpha: 0.75))),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🟢 Zoznam povolení
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
                const SizedBox(height: 12),
                _buildPermissionTile(
                  title: "Vypnutie šetrenia batérie (Unrestricted)",
                  isGranted: isBatteryOptimizationGranted,
                  currentTheme: currentTheme,
                ),

                const Spacer(),

                // 🟢 Spodné hlavné tlačidlo (Neumorfný 3D štýl)
                _buildCtaButton(
                  allGranted: allGranted,
                  onTap: allGranted ? _navigateToMain : _openSettingsOrRequest,
                  currentTheme: currentTheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCtaButton({
    required bool allGranted,
    required VoidCallback onTap,
    required AppThemeData currentTheme,
  }) {
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;

    String buttonText = allGranted
        ? "Pokračovať"
        : (!isOverlayGranted
            ? "Povoliť prekrytie"
            : (!isAccessibilityGranted
                ? "Povoliť Zjednodušenie prístupu"
                : (!isNotificationGranted
                    ? "Povoliť Upozornenia"
                    : "Vypnúť šetrenie batérie")));

    IconData buttonIcon = allGranted ? Icons.arrow_forward : Icons.settings;

    if (isSoft) {
      final Color softBtnColor = allGranted ? const Color(0xFF0D9488) : const Color(0xFF2563EB);

      return Container(
        decoration: BoxDecoration(
          color: softBtnColor,
          borderRadius: currentTheme.buttonBorderRadius,
          boxShadow: const [
            BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(4, 4), blurRadius: 8),
            BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: currentTheme.buttonBorderRadius,
            child: Container(
              height: 56,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (isVibrant) {
      final List<Color> gradientColors = allGranted
          ? [const Color(0xFF10B981), const Color(0xFF047857)]
          : [const Color(0xFF00F5FF), const Color(0xFF7C3AED)];

      final Color shadowColor = allGranted 
          ? const Color(0xFF10B981) 
          : const Color(0xFF7C3AED);

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: currentTheme.buttonBorderRadius,
            child: Container(
              height: 56,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (isGlass) {
      final Color accent = allGranted ? currentTheme.successColor : currentTheme.theme.primaryColor;

      return Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            accent.withValues(alpha: 0.22),
            const Color(0xFF0F172A).withValues(alpha: 0.55),
          ),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.35),
              accent.withValues(alpha: 0.12),
              const Color(0xFF090D1A).withValues(alpha: 0.50),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(
            color: Color.alphaBlend(accent.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0.4)),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: currentTheme.buttonBorderRadius,
            child: Container(
              height: 56,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (isNeo) {
      final Color buttonBgColor = allGranted ? currentTheme.successColor : currentTheme.decksColor;

      return Container(
        decoration: BoxDecoration(
          color: buttonBgColor,
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(color: Colors.black, width: 3.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: currentTheme.buttonBorderRadius,
            child: Container(
              height: 56,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon, color: Colors.black, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final Color primaryAccent = currentTheme.decksColor;
    final Color buttonBgColor = allGranted ? currentTheme.successColor : primaryAccent;
    final Color buttonFgColor = currentTheme.getContrastTextColor(buttonBgColor);

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(buttonIcon, color: buttonFgColor),
      label: Text(
        buttonText,
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.buttonBorderRadius,
          side: BorderSide(color: currentTheme.buttonBorder.color, width: 2.0),
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
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final Color accentColor = isGranted ? currentTheme.successColor : currentTheme.warningColor;

    BoxDecoration decoration;
    Color textColor;
    Color iconColor;

    if (isSoft) {
      if (isGranted) {
        decoration = BoxDecoration(
          color: const Color(0xFFCCFBF1),
          borderRadius: currentTheme.cardBorderRadius,
          boxShadow: const [
            BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
            BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
          ],
        );
        textColor = const Color(0xFF1E293B);
        iconColor = const Color(0xFF0D9488);
      } else {
        decoration = BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: currentTheme.cardBorderRadius,
          boxShadow: const [
            BoxShadow(color: Color(0xFF9EAEC6), offset: Offset(3, 3), blurRadius: 6),
            BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
          ],
        );
        textColor = const Color(0xFF1E293B);
        iconColor = const Color(0xFFB45309);
      }
    } else if (isVibrant) {
      if (isGranted) {
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF065F46).withValues(alpha: 0.75),
              const Color(0xFF047857).withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: currentTheme.cardBorderRadius,
          border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
        textColor = Colors.white;
        iconColor = const Color(0xFF6EE7B7);
      } else {
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7C2D12).withValues(alpha: 0.75),
              const Color(0xFF9A3412).withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: currentTheme.cardBorderRadius,
          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
        textColor = Colors.white;
        iconColor = const Color(0xFFFDE68A);
      }
    } else if (isNeo) {
      decoration = BoxDecoration(
        color: accentColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
                  fontWeight: isNeo || isSoft ? FontWeight.w900 : FontWeight.bold,
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