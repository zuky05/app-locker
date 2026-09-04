import 'package:flutter/material.dart';
import 'deck_manager_screen.dart';
import 'app_selector_screen.dart';
import 'quizlet_playground_screen.dart';
import 'anki_playground_screen.dart';
import '../services/database_helper.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int customDeckCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDeckCount();
  }

  // Funkcia na načítanie aktuálneho počtu custom balíčkov z databázy
  Future<void> _checkDeckCount() async {
    final count = await DatabaseHelper.instance.getCustomDeckCount();
    setState(() {
      customDeckCount = count;
      isLoading = false;
    });
  }

  // Pomocná metóda na zobrazenie prémiového dialógu
  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.star_rounded, size: 50, color: Colors.amber),
            SizedBox(height: 10),
            Text(
              "Odomkni Brainlock Premium!",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Dosiahol si limit 3 vlastných balíčkov zadarmo.\n\nPre import ďalších balíčkov a neobmedzené vytváranie si aktivuj Premium.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Zrušiť"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              print("Navigovať na nákup Premium");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Odomknúť Premium", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLimitReached = customDeckCount >= 3;

    return Scaffold(
      backgroundColor: Colors.grey[150],
      appBar: AppBar(
        title: const Text('Brainlock Decks', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.star, color: Colors.amber, size: 28),
            tooltip: 'Premium',
            onPressed: _showPremiumDialog,
                ),
                IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. DASHBOARD
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    height: 250,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_customize, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Dashboard WIP\n(pridáme neskôr, iba miesto vyhradené)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // 2. TLAČIDLÁ
                _buildMenuCard(
                  title: 'Decks',
                  icon: Icons.layers,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DeckManagerScreen()),
                    );
                    _checkDeckCount();
                  },
                ),
                
                const SizedBox(height: 12),
                
                _buildMenuCard(
                  title: 'Test settings',
                  icon: Icons.settings_suggest,
                  onTap: () {
                    print("Klik na Test settings");
                  },
                ),
                
                const SizedBox(height: 12),
                
                _buildMenuCard(
                  title: 'Blocked apps',
                  icon: Icons.app_blocking,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AppSelectorScreen()),
                    );
                  },
                ),
                
                const SizedBox(height: 12),

                // Quizlet Import
                _buildMenuCard(
                  title: 'Import from Quizlet',
                  icon: isLimitReached ? Icons.lock : Icons.language,
                  isLocked: isLimitReached,
                  onTap: () {
                    if (isLimitReached) {
                      _showPremiumDialog();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QuizletPlaygroundScreen()),
                      ).then((_) => _checkDeckCount());
                    }
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Anki Import
                _buildMenuCard(
                  title: 'Import from Anki',
                  icon: isLimitReached ? Icons.lock : Icons.style,
                  isLocked: isLimitReached,
                  onTap: () {
                    if (isLimitReached) {
                      _showPremiumDialog();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AnkiPlaygroundScreen()),
                      ).then((_) => _checkDeckCount());
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Card(
        elevation: isLocked ? 0 : 1,
        color: isLocked ? Colors.grey.shade200 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isLocked ? BorderSide(color: Colors.amber.shade700, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isLocked ? Colors.amber.shade800 : Colors.deepPurple,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.grey.shade700 : Colors.black87,
                  ),
                ),
                if (isLocked) ...[
                  const Spacer(),
                  Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}