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
      return BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: const Color(0xFF667EEA), width: 3.0) : null,
        boxShadow: const [
          BoxShadow(color: Color(0xFFA3B1C6), offset: Offset(4, 4), blurRadius: 8),
          BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
        ],
      );
    } else if (cleanName.contains('brutalism')) {
      return BoxDecoration(
        color: const Color(0xFFFFDE59),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: isSelected
            ? const [BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0)]
            : const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
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
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF38EF7D) : Colors.white24,
          width: isSelected ? 3.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11998E).withValues(alpha: 0.3),
            blurRadius: 10,
          )
        ],
      );
    } else if (cleanName.contains('vibrant')) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
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
                  color: const Color(0xFF0072FF).withValues(alpha: 0.4),
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
        'accent': const Color(0xFF667EEA),
      };
    } else if (cleanName.contains('brutalism')) {
      return {
        'text': Colors.black,
        'subtext': Colors.black87,
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
        'subtext': Colors.white70,
        'accent': const Color(0xFF38EF7D),
      };
    } else {
      return {
        'text': Colors.white,
        'subtext': Colors.white.withValues(alpha: 0.8),
        'accent': Colors.amberAccent,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    final bool isVibrant = currentTheme.id == 5;

    // Zotriedenie tém pre vykreslenie: ne-prémiové témy pôjdu prvé
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
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor, // Nepriehľadný AppBar
          foregroundColor: theme.colorScheme.onSurface,
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
                    decoration: isVibrant
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: currentTheme.cardBorderRadius,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          )
                        : currentTheme.getCardDecoration(currentTheme.decksColor),
                    child: SwitchListTile(
                      secondary: Icon(
                        Icons.vibration, 
                        color: isVibrant ? Colors.white : currentTheme.getIconColor(currentTheme.decksColor),
                      ),
                      title: Text(
                        "Vibrovanie pri chybe",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isVibrant ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        "Zavibruje pri nesprávnej odpovedi v kvíze",
                        style: TextStyle(
                          color: isVibrant ? Colors.white.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      value: isVibrationEnabled,
                      activeColor: isVibrant ? Colors.white : currentTheme.decksColor,
                      onChanged: _saveVibrationSetting,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- SEKCIA: VÝBER TÉMY ---
                  Text(
                    "Vizuálny štýl aplikácie",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2-STĹPCOVÁ MRIEŽKA (GRID) PRE TÉMY
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

                      return InkWell(
                        onTap: () => _onThemeTap(appTheme, themeProvider),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: previewDeco,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                    color: isSelected ? accentColor : textColor.withValues(alpha: 0.4),
                                    size: 22,
                                  ),
                                  if (appTheme.isPremium)
                                    Icon(
                                      Icons.star_rounded,
                                      color: accentColor,
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    appTheme.isPremium ? "Premium štýl" : "Základný štýl",
                                    style: TextStyle(
                                      fontSize: 11,
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
                                      color: itemTheme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: appTheme.decksColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: appTheme.testSetupColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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