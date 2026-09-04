import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.vibration, color: Colors.deepPurple),
                    title: const Text(
                      "Vibrovanie pri chybe",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Zavibruje pri nesprávnej odpovedi v kvíze"),
                    value: isVibrationEnabled,
                    activeColor: Colors.deepPurple,
                    onChanged: _saveVibrationSetting,
                  ),
                ),
              ],
            ),
    );
  }
}