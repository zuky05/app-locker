import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_themes.dart';
import '../themes/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isVibrationEnabled = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      isLoading = false;
    });
  }

  Future<void> _saveVibrationSetting(bool value) async {
    setState(() {
      isVibrationEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
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
                  decoration: currentTheme.getCardDecoration(currentTheme.decksColor),
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.vibration, 
                      color: currentTheme.getIconColor(currentTheme.decksColor),
                    ),
                    title: Text(
                      "Vibrovanie pri chybe",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      "Zavibruje pri nesprávnej odpovedi v kvíze",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    value: isVibrationEnabled,
                    activeColor: currentTheme.decksColor,
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
                const SizedBox(height: 12),

                ...AppThemes.availableThemes.map((appTheme) {
                  final bool isSelected = currentTheme.id == appTheme.id;
                  final itemTheme = appTheme.theme;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: currentTheme.getCardDecoration(
                      appTheme.decksColor,
                      isSelected: isSelected,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected
                            ? currentTheme.decksColor
                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      title: Row(
                        children: [
                          Text(
                            appTheme.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: itemTheme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(currentTheme.buttonBorder.copyWith(width: 1)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: appTheme.decksColor,
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(currentTheme.buttonBorder.copyWith(width: 1)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      subtitle: Text(
                        appTheme.isPremium ? "Premium štýl" : "Základný štýl",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: appTheme.isPremium
                          ? Icon(Icons.star_rounded, color: currentTheme.warningColor, size: 22)
                          : null,
                      onTap: () {
                        themeProvider.setTheme(appTheme.id);
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}