import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_themes.dart';
import '../themes/theme_provider.dart';
import '../services/revenuecat_service.dart';
import '../themes/themed_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isVibrationEnabled = true;
  bool isLoading = true;
  bool userHasPremium = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasPremium = await RevenueCatService.isPremium();

    if (mounted) {
      setState(() {
        isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        userHasPremium = hasPremium;
        isLoading = false;
      });
    }
  }

  Future<void> _saveVibrationSetting(bool value) async {
    setState(() {
      isVibrationEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
  }

  Future<void> _onThemeTap(AppThemeData appTheme, ThemeProvider themeProvider) async {
    if (!appTheme.isPremium || userHasPremium) {
      themeProvider.setTheme(appTheme.id);
      return;
    }

    final bool purchased = await RevenueCatService.presentPaywall();

    if (purchased && mounted) {
      setState(() {
        userHasPremium = true;
      });
      themeProvider.setTheme(appTheme.id);
    }
  }

  BoxDecoration _getPreviewDecoration(AppThemeData appTheme, bool isSelected) {
    final cleanName = appTheme.name.toLowerCase();

    if (cleanName.contains('cyberpunk')) {
      return BoxDecoration(
        color: const Color(0xFF120E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF007F) : const Color(0xFF00F0FF),
          width: isSelected ? 3.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? const Color(0xFFFF007F) : const Color(0xFF00F0FF)).withValues(alpha: 0.35),
            blurRadius: 10,
          )
        ],
      );
    } else if (cleanName.contains('neumorphism')) {
      // 🟢 SOFT NEUMORPHISM: Zladená farba náhľadu `#D1D9E6` a stieňovanie
      return BoxDecoration(
        color: const Color(0xFFD1D9E6),
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: const Color(0xFF6C5CE7), width: 2.5) : null,
        boxShadow: const [
          BoxShadow(color: Color(0xFF97A7C0), offset: Offset(4, 4), blurRadius: 8),
          BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
        ],
      );
    } else if (cleanName.contains('brutalism')) {
      return BoxDecoration(
        color: const Color(0xFFFFD166),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black, 
            offset: Offset(4, 4), 
            blurRadius: 0,
          ),
        ],
      );
    } else if (cleanName.contains('minimal')) {
      return BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade300,
          width: isSelected ? 3.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      );
    } else if (cleanName.contains('starlight')) {
      return BoxDecoration(
        color: const Color(0xFF030712),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF030712),
            Color(0xFF090D1E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFF38BDF8) 
              : Colors.white.withValues(alpha: 0.25),
          width: isSelected ? 2.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? const Color(0xFF38BDF8) : const Color(0xFFC084FC))
                .withValues(alpha: isSelected ? 0.35 : 0.15),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (cleanName.contains('vibrant')) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00F2FE), Color(0xFF003BB3), Color(0xFF010038)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
          width: isSelected ? 3.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      );
    }

    return appTheme.getCardDecoration(appTheme.decksColor, isSelected: isSelected);
  }

  Map<String, Color> _getPreviewColors(AppThemeData appTheme) {
    final cleanName = appTheme.name.toLowerCase();

    if (cleanName.contains('cyberpunk')) {
      return {
        'text': Colors.white,
        'subtext': const Color(0xFF00F0FF),
        'accent': const Color(0xFFFF007F),
      };
    } else if (cleanName.contains('neumorphism')) {
      return {
        'text': const Color(0xFF2D3748),
        'subtext': const Color(0xFF718096),
        'accent': const Color(0xFF6C5CE7),
      };
    } else if (cleanName.contains('brutalism')) {
      return {
        'text': Colors.black,
        'subtext': Colors.black,
        'accent': Colors.black,
      };
    } else if (cleanName.contains('minimal')) {
      return {
        'text': Colors.black87,
        'subtext': Colors.black54,
        'accent': Colors.black,
      };
    } else if (cleanName.contains('starlight')) {
      return {
        'text': Colors.white,
        'subtext': Colors.white.withValues(alpha: 0.75),
        'accent': const Color(0xFF38BDF8),
      };
    } else {
      return {
        'text': Colors.white,
        'subtext': Colors.white.withValues(alpha: 0.8),
        'accent': Colors.white,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    final bool isNeo = currentTheme.id == 2;
    final bool isVibrant = currentTheme.id == 5;
    final bool isSoft = currentTheme.id == 1;

    final displayedThemes = List<AppThemeData>.from(AppThemes.availableThemes)
      ..sort((a, b) {
        if (!a.isPremium && b.isPremium) return -1;
        if (a.isPremium && !b.isPremium) return 1;
        return 0;
      });

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Settings',
            style: TextStyle(
              fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
              color: isNeo ? Colors.black : theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: isNeo ? Colors.black : theme.colorScheme.onSurface,
          elevation: theme.appBarTheme.elevation ?? 0,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: currentTheme.decksColor))
            : ListView(
                padding: const EdgeInsets.all(16.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  // --- SEKCIA: VIBRÁCIE ---
                  Container(
                    decoration: currentTheme.getCardDecoration(currentTheme.decksColor),
                    child: SwitchListTile(
                      secondary: Icon(
                        Icons.vibration, 
                        color: isNeo 
                            ? Colors.black 
                            : (isSoft 
                                ? currentTheme.decksColor 
                                : (isVibrant ? Colors.white : currentTheme.getIconColor(currentTheme.decksColor))),
                      ),
                      title: Text(
                        "Vibrovanie pri chybe",
                        style: TextStyle(
                          fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
                          color: isNeo 
                              ? Colors.black 
                              : (isSoft 
                                  ? const Color(0xFF2D3748) 
                                  : (isVibrant ? Colors.white : theme.colorScheme.onSurface)),
                        ),
                      ),
                      subtitle: Text(
                        "Zavibruje pri nesprávnej odpovedi v kvíze",
                        style: TextStyle(
                          fontWeight: isNeo ? FontWeight.bold : FontWeight.normal,
                          color: isNeo 
                              ? Colors.black 
                              : (isSoft 
                                  ? const Color(0xFF718096) 
                                  : (isVibrant ? Colors.white.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        ),
                      ),
                      value: isVibrationEnabled,
                      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                      activeColor: isNeo 
                          ? Colors.black 
                          : (isSoft 
                              ? Colors.white 
                              : (isVibrant ? Colors.white : currentTheme.decksColor)),
                      activeTrackColor: isNeo 
                          ? Colors.white 
                          : (isSoft 
                              ? currentTheme.decksColor 
                              : (isVibrant ? Colors.white.withValues(alpha: 0.35) : null)),
                      inactiveThumbColor: isSoft ? const Color(0xFF97A7C0) : null,
                      inactiveTrackColor: isSoft ? const Color(0xFFC8D3E6) : null,
                      onChanged: _saveVibrationSetting,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- SEKCIA: VÝBER TÉMY ---
                  Text(
                    "Vizuálny štýl aplikácie",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
                      color: isNeo ? Colors.black : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: displayedThemes.length,
                    itemBuilder: (context, index) {
                      final appTheme = displayedThemes[index];
                      final bool isSelected = currentTheme.id == appTheme.id;
                      final itemTheme = appTheme.theme;

                      final previewDeco = _getPreviewDecoration(appTheme, isSelected);
                      final colors = _getPreviewColors(appTheme);

                      final Color textColor = colors['text']!;
                      final Color subtextColor = colors['subtext']!;
                      final Color accentColor = colors['accent']!;
                      
                      final bool isItemNeo = appTheme.id == 2;
                      final bool isStarlight = appTheme.id == 4 || appTheme.name.toLowerCase().contains('starlight');

                      return InkWell(
                        onTap: () => _onThemeTap(appTheme, themeProvider),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: previewDeco,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                if (isStarlight)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: MiniStarlightPainter(),
                                    ),
                                  ),

                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                            color: isItemNeo 
                                                ? Colors.black 
                                                : (isSelected ? accentColor : textColor.withValues(alpha: 0.4)),
                                            size: 22,
                                          ),
                                          if (appTheme.isPremium)
                                            Icon(
                                              Icons.star_rounded,
                                              color: isItemNeo ? Colors.black : accentColor,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appTheme.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: isItemNeo ? FontWeight.w900 : FontWeight.bold,
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            appTheme.isPremium ? "Premium štýl" : "Základný štýl",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isItemNeo ? FontWeight.bold : FontWeight.normal,
                                              color: subtextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: isItemNeo ? Colors.black : itemTheme.colorScheme.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isItemNeo ? Colors.black : textColor.withValues(alpha: 0.3), 
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: isItemNeo ? const Color(0xFFFF70A6) : appTheme.decksColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isItemNeo ? Colors.black : textColor.withValues(alpha: 0.3), 
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: isItemNeo ? const Color(0xFF00E5FF) : appTheme.testSetupColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isItemNeo ? Colors.black : textColor.withValues(alpha: 0.3), 
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class MiniStarlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()..style = PaintingStyle.fill;
    final random = Random(42);

    for (int i = 0; i < 14; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = 0.8 + random.nextDouble() * 1.2;
      double opacity = 0.35 + random.nextDouble() * 0.55;

      glowPaint.color = (i % 3 == 0 
          ? const Color(0xFF38BDF8) 
          : const Color(0xFFC084FC)).withValues(alpha: opacity * 0.3);
      canvas.drawCircle(Offset(x, y), radius * 2.2, glowPaint);

      starPaint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}