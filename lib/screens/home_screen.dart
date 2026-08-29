import 'package:flutter/material.dart';
import 'deck_manager_screen.dart';
import 'app_selector_screen.dart';
// Odkomentuj tento import, keď to prepojíš s existujúcou obrazovkou
// import 'deck_manager_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Jemné pozadie, aby biele bloky vynikli
      appBar: AppBar(
        title: const Text('Brainlock Decks', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple, // Farba podľa tvojho nákresu
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.star, color: Colors.amber, size: 28),
            tooltip: 'Premium',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tu bude nákup Premium verzie! 🌟')),
              );
            },
          ),
        ],
      ),
      // Použitie ListView zaručí, že obrazovka je VŽDY scrollovateľná
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(), // Moderný "pružinový" efekt rolovania z iOS
        children: [
          
          // 1. DASHBOARD (Zatiaľ len vyhradené miesto)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              height: 250, // Výška vyhradená pre budúce grafy
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
          
          const SizedBox(height: 24), // Medzera medzi dashboardom a tlačidlami

          // 2. TLAČIDLÁ
          _buildMenuCard(
            context: context,
            title: 'Decks',
            icon: Icons.layers,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DeckManagerScreen()));
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildMenuCard(
            context: context,
            title: 'Test settings',
            icon: Icons.settings_suggest,
            onTap: () {
              // TODO: Presmerovanie na Nastavenia testov
              print("Klik na Test settings");
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildMenuCard(
            context: context,
            title: 'Blocked apps',
            icon: Icons.app_blocking,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AppSelectorScreen()));
            },
          ),
          
          // Ak by si chcel nasimulovať scrollovanie, môžeš sem pridať const SizedBox(height: 500),
        ],
      ),
    );
  }

  // Pomocná funkcia na generovanie pekných, jednotných tlačidiel (kartičiek)
  Widget _buildMenuCard({required BuildContext context, required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell( // InkWell pridá pekný efekt kliknutia (vlnku)
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.deepPurple),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}