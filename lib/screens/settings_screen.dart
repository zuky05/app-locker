import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_flags/country_flags.dart';
import '../themes/app_themes.dart';
import '../themes/theme_provider.dart';
import '../services/revenuecat_service.dart';
import '../themes/themed_background.dart';
import '../services/locale_provider.dart';
import '../services/database_helper.dart';

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

  // 🟢 Zmena jazyka priamo cez Provider + Obnovenie predpripravených balíčkov v DB
  Future<void> _saveLanguageSetting(String langCode) async {
    if (mounted) {
      context.read<LocaleProvider>().setLocale(langCode);
      await DatabaseHelper.instance.refreshPremadeDecks(null, langCode);
    }
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
      final Color activeBorder = isSelected ? const Color(0xFFFF007F) : const Color(0xFF00F0FF);
      return BoxDecoration(
        color: const Color(0xFF050014),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activeBorder,
          width: isSelected ? 3.0 : 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: activeBorder.withValues(alpha: isSelected ? 0.6 : 0.35),
            blurRadius: isSelected ? 16 : 10,
            spreadRadius: isSelected ? 2 : 0,
          ),
          BoxShadow(
            color: const Color(0xFFFF007F).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (cleanName.contains('neumorphism')) {
      return BoxDecoration(
        color: const Color(0xFFE5ECF4),
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: const Color(0xFF2563EB), width: 2.5) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9EAEC6).withValues(alpha: 0.7), 
            offset: const Offset(4, 4), 
            blurRadius: 8,
          ),
          const BoxShadow(
            color: Colors.white, 
            offset: Offset(-4, -4), 
            blurRadius: 8,
          ),
        ],
      );
    } else if (appTheme.id == 2 || cleanName.contains('brutalism') || cleanName.contains('neo')) {
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
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isSelected ? 2.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
        'accent': const Color(0xFF00F0FF),
      };
    } else if (cleanName.contains('neumorphism')) {
      return {
        'text': const Color(0xFF1E293B),
        'subtext': const Color(0xFF64748B),
        'accent': const Color(0xFF2563EB),
      };
    } else if (appTheme.id == 2 || cleanName.contains('brutalism') || cleanName.contains('neo')) {
      return {
        'text': Colors.black,
        'subtext': Colors.black,
        'accent': Colors.black,
      };
    } else if (cleanName.contains('minimal')) {
      return {
        'text': const Color(0xFF0F172A),
        'subtext': const Color(0xFF64748B),
        'accent': const Color(0xFF2563EB),
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

    final localeProvider = Provider.of<LocaleProvider>(context);
    final String currentLanguageCode = localeProvider.locale;

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
            currentLanguageCode == 'sk' ? "Nastavenia" : "Settings",
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
                  // --- SEKCIA: VÝBER JAZYKA (VLAJKY) ---
                  Container(
                    decoration: currentTheme.getCardDecoration(currentTheme.decksColor),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentLanguageCode == 'sk' ? "Jazyk aplikácie" : "Language",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
                            color: isNeo 
                                ? Colors.black 
                                : (isSoft 
                                    ? const Color(0xFF2D3748) 
                                    : (isVibrant ? Colors.white : theme.colorScheme.onSurface)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // SLOVENSKÁ VLAJKA
                            GestureDetector(
                              onTap: () => _saveLanguageSetting('sk'),
                              child: Opacity(
                                opacity: currentLanguageCode == 'sk' ? 1.0 : 0.5,
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: currentLanguageCode == 'sk' 
                                              ? (isNeo ? Colors.black : currentTheme.decksColor) 
                                              : Colors.transparent,
                                          width: 3.0,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: CountryFlag.fromCountryCode(
                                        'SK',
                                        height: 40,
                                        width: 60,
                                        shape: const Rectangle(),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      currentLanguageCode == 'sk' ? "Slovenčina" : "Slovak",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isNeo ? Colors.black : (isVibrant ? Colors.white : theme.colorScheme.onSurface),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // ANGLICKÁ VLAJKA
                            GestureDetector(
                              onTap: () => _saveLanguageSetting('en'),
                              child: Opacity(
                                opacity: currentLanguageCode == 'en' ? 1.0 : 0.5,
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: currentLanguageCode == 'en' 
                                              ? (isNeo ? Colors.black : currentTheme.decksColor) 
                                              : Colors.transparent,
                                          width: 3.0,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: CountryFlag.fromCountryCode(
                                        'GB',
                                        height: 40,
                                        width: 60,
                                        shape: const Rectangle(),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      currentLanguageCode == 'sk' ? "Angličtina" : "English",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isNeo ? Colors.black : (isVibrant ? Colors.white : theme.colorScheme.onSurface),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

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
                        currentLanguageCode == 'sk' ? "Vibrovanie pri chybe" : "Vibration on error",
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
                        currentLanguageCode == 'sk' 
                            ? "Zavibruje pri nesprávnej odpovedi v kvíze a pri otočení kartičky" 
                            : "Vibrates on incorrect quiz answers and card flips",
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
                    currentLanguageCode == 'sk' ? "Vizuálny štýl aplikácie" : "App Visual Style",
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
                      
                      final cleanName = appTheme.name.toLowerCase();
                      final bool isBrutalism = appTheme.id == 2 || cleanName.contains('brutalism') || cleanName.contains('neo');
                      final bool isCyberpunk = cleanName.contains('cyberpunk');
                      final bool isStarlight = cleanName.contains('starlight');
                      final bool isClean = cleanName.contains('minimal');
                      final bool isNeumorphism = cleanName.contains('neumorphism');

                      Color dot1Color;
                      Color dot2Color;
                      Color dot3Color;

                      if (isBrutalism) {
                        dot1Color = Colors.black;
                        dot2Color = const Color(0xFFFF007F);
                        dot3Color = const Color(0xFF00E5FF);
                      } else if (isCyberpunk) {
                        dot1Color = const Color(0xFF00F0FF);
                        dot2Color = const Color(0xFFFF007F);
                        dot3Color = const Color(0xFF00FF66);
                      } else if (isClean) {
                        dot1Color = const Color(0xFF2563EB);
                        dot2Color = const Color(0xFF059669);
                        dot3Color = const Color(0xFFDC2626);
                      } else if (isNeumorphism) {
                        dot1Color = const Color(0xFF2563EB);
                        dot2Color = const Color(0xFF0D9488);
                        dot3Color = const Color(0xFFE11D48);
                      } else {
                        dot1Color = itemTheme.colorScheme.primary;
                        dot2Color = appTheme.decksColor;
                        dot3Color = appTheme.testSetupColor;
                      }

                      return InkWell(
                        onTap: () => _onThemeTap(appTheme, themeProvider),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: previewDeco,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                if (isBrutalism)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: MiniBrutalismDotsPainter(),
                                    ),
                                  ),
                                if (isCyberpunk)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: MiniCyberpunkGridPainter(),
                                    ),
                                  ),
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
                                            color: isBrutalism
                                                ? Colors.black
                                                : (isSelected ? (isCyberpunk ? const Color(0xFFFF007F) : accentColor) : textColor.withValues(alpha: 0.5)),
                                            size: 22,
                                          ),
                                          if (appTheme.isPremium)
                                            Icon(
                                              Icons.star_rounded,
                                              color: isBrutalism
                                                  ? Colors.black
                                                  : (isCyberpunk ? const Color(0xFFFF007F) : accentColor),
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
                                              fontWeight: isBrutalism ? FontWeight.w900 : FontWeight.bold,
                                              fontSize: 14,
                                              fontFamily: isCyberpunk ? 'monospace' : null,
                                              color: isBrutalism ? Colors.black : textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            appTheme.isPremium 
                                                ? (currentLanguageCode == 'sk' ? "Premium štýl" : "Premium style") 
                                                : (currentLanguageCode == 'sk' ? "Základný štýl" : "Basic style"),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isBrutalism ? FontWeight.w900 : FontWeight.normal,
                                              fontFamily: isCyberpunk ? 'monospace' : null,
                                              color: isBrutalism ? Colors.black : subtextColor,
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
                                              color: dot1Color,
                                              shape: BoxShape.circle,
                                              border: isBrutalism ? Border.all(color: Colors.black, width: 1.5) : null,
                                              boxShadow: isCyberpunk ? [const BoxShadow(color: Color(0xFF00F0FF), blurRadius: 4)] : null,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: dot2Color,
                                              shape: BoxShape.circle,
                                              border: isBrutalism ? Border.all(color: Colors.black, width: 1.5) : null,
                                              boxShadow: isCyberpunk ? [const BoxShadow(color: Color(0xFFFF007F), blurRadius: 4)] : null,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: dot3Color,
                                              shape: BoxShape.circle,
                                              border: isBrutalism ? Border.all(color: Colors.black, width: 1.5) : null,
                                              boxShadow: isCyberpunk ? [const BoxShadow(color: Color(0xFF00FF66), blurRadius: 4)] : null,
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

class MiniBrutalismDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    const double spacing = 14.0;
    for (double x = 10; x < size.width; x += spacing) {
      for (double y = 10; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniCyberpunkGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double horizon = size.height * 0.45;

    final Paint glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFF007F).withValues(alpha: 0.6),
          const Color(0xFF00F0FF).withValues(alpha: 0.3),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, horizon + 15));

    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, horizon + 15), glowPaint);

    final Paint horizonLinePaint = Paint()
      ..color = const Color(0xFFFF007F)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, horizon), Offset(size.width, horizon), horizonLinePaint);

    final Paint gridPattern = Paint()
      ..color = const Color(0xFF00FF66).withValues(alpha: 0.55)
      ..strokeWidth = 0.8;

    double vanishingX = size.width / 2;

    for (double x = -size.width; x <= size.width * 2; x += 18) {
      canvas.drawLine(
        Offset(vanishingX, horizon),
        Offset(x, size.height),
        gridPattern,
      );
    }

    for (int i = 1; i <= 6; i++) {
      double t = pow(i / 6, 2.2).toDouble();
      double y = horizon + (size.height - horizon) * t;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPattern,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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