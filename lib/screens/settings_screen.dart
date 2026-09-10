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

  // Načítanie uloženého stavu pri otvorení nastavení
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      isLoading = false;
    });
  }

  // Uloženie zmeny pri kliknutí na prepínač
  Future<void> _saveVibrationSetting(bool value) async {
    setState(() {
      isVibrationEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    // Získame prístup k nášmu ThemeProvideru
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- SEKCIA: VIBRÁCIE ---
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    secondary: Icon(Icons.vibration, color: Theme.of(context).colorScheme.primary),
                    title: const Text(
                      "Vibrovanie pri chybe",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Zavibruje pri nesprávnej odpovedi v kvíze"),
                    value: isVibrationEnabled,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: _saveVibrationSetting,
                  ),
                ),
                
                const SizedBox(height: 24),

                // --- SEKCIA: VÝBER TÉMY ---
                const Text(
                  "Vizuálny štýl aplikácie",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Vygenerujeme zoznam všetkých 6 tém z AppThemes
                ...AppThemes.availableThemes.map((appTheme) {
                  final bool isSelected = themeProvider.currentThemeData.id == appTheme.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: isSelected ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          appTheme.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          appTheme.isPremium ? "Premium štýl" : "Základný štýl",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: appTheme.isPremium
                            ? const Icon(Icons.star_rounded, color: Colors.amber, size: 20)
                            : null,
                        onTap: () {
                          // Okamžitá zmena témy cez provider
                          themeProvider.setTheme(appTheme.id);
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}