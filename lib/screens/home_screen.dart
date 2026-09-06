import 'package:flutter/material.dart';
import 'deck_manager_screen.dart';
import 'app_selector_screen.dart';
import 'quizlet_playground_screen.dart';
import 'anki_playground_screen.dart';
import '../services/database_helper.dart';
import 'settings_screen.dart';
import 'test_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int customDeckCount = 0;
  bool isLoading = true;

  // --- FAREBNÁ PALETA (Opravený kontrast!) ---
  static const Color bgColor = Color(0xFFEBE8E0); // Tmavšie, aby biela kričala
  static const Color cardColor = Colors.white; // Čistá biela pre maximálny kontrast
  static const Color primaryText = Color(0xFF2C2241);
  static const Color secondaryText = Color(0xFF7D7789);
  static const Color deepPurple = Color(0xFF352655);
  static const Color goldAccent = Color(0xFFD4A034);

  @override
  void initState() {
    super.initState();
    _checkDeckCount();
  }

  Future<void> _checkDeckCount() async {
    final count = await DatabaseHelper.instance.getCustomDeckCount();
    setState(() {
      customDeckCount = count;
      isLoading = false;
    });
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.star_rounded, size: 50, color: goldAccent),
            SizedBox(height: 10),
            Text(
              "Odomkni Brainlock Premium!",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
            ),
          ],
        ),
        content: const Text(
          "Dosiahol si limit 3 vlastných balíčkov zadarmo.\n\nPre import ďalších balíčkov a neobmedzené vytváranie si aktivuj Premium.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: primaryText),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
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
              backgroundColor: goldAccent,
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
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Brainlock Decks',
          style: TextStyle(
            color: primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_rounded, color: goldAccent, size: 30),
            tooltip: 'Premium',
            onPressed: _showPremiumDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: primaryText, size: 24),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      // STICKY BOTTOM BAR (Kotva na spodku pre Quick Import)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor, // Splýva s pozadím, ale zostáva dole
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -5), // Jemný tieň smerom hore
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 16.0, top: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Zaberá len toľko miesta, koľko musí
              children: [
                const Text(
                  'QUICK IMPORT',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildImportTile(
                        title: 'Quizlet',
                        icon: Icons.language,
                        color: const Color(0xFF4257B2),
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
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildImportTile(
                        title: 'Anki',
                        icon: Icons.view_carousel_rounded,
                        color: const Color(0xFF6C4AB6),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      
      // HLAVNÁ SCROLLOVATEĽNÁ ČASŤ
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: deepPurple))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              physics: const BouncingScrollPhysics(),
              children: [
                
                // 1. DAILY GOAL (Dashboard - Zväčšený!)
                Container(
                  height: 260, // Pevne daná, oveľa väčšia výška
                  padding: const EdgeInsets.all(24),
                  decoration: _cardDecoration(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Vycentruje obsah dnu
                    children: [
                      const Text(
                        'DAILY GOAL',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 14, // Zväčšený text
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('🔥', style: TextStyle(fontSize: 52)), // Zväčšený oheň
                          SizedBox(width: 16),
                          Text(
                            '15 / 20\nCards',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 24, // Zväčšené čísla
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: const LinearProgressIndicator(
                          value: 15 / 20,
                          minHeight: 12, // Tučnejší progress bar
                          backgroundColor: Color(0xFFE5E0D5),
                          valueColor: AlwaysStoppedAnimation<Color>(deepPurple),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. PREMIUM ACCESS BANNER
                InkWell(
                  onTap: _showPremiumDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF7DE9B), Color(0xFFE5B558)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: goldAccent.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.star_rounded, color: Color(0xFF6B4702), size: 26),
                        SizedBox(width: 10),
                        Text(
                          'PREMIUM ACCESS',
                          style: TextStyle(
                            color: Color(0xFF4A3203),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. DECKS (Jeden veľký spojený button)
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DeckManagerScreen()),
                    );
                    _checkDeckCount();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: _cardDecoration(radius: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.style_rounded, size: 64, color: deepPurple),
                        SizedBox(height: 12),
                        Text(
                          'Decks',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. TEST SETUP & BLOCKED APPS (2 vedľa seba)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.settings_suggest_rounded,
                        title: 'Test Setup',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const TestSetupScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.smartphone_rounded,
                        title: 'Blocked Apps',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AppSelectorScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Na spodok ListView už nepridávame Quick import, je zakotvený v bottomNavigationBar
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  // --- POMOCNÉ WIDGETY ---

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: cardColor, // Čistá biela!
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08), // Výraznejší tieň pre lepší 3D efekt
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 125, // Kúsok som ich natiahol do výšky
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: deepPurple),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isLocked ? 0.65 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16), // Zväčšený padding
          decoration: BoxDecoration(
            color: isLocked ? Colors.grey.shade200 : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isLocked ? Border.all(color: goldAccent, width: 1.5) : null,
            boxShadow: isLocked
                ? [] 
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLocked ? Icons.lock : icon,
                color: isLocked ? goldAccent.withOpacity(0.8) : color,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isLocked ? Colors.grey.shade700 : primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}