import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/deck_model.dart';
import 'create_deck_screen.dart';

class DeckManagerScreen extends StatefulWidget {
  const DeckManagerScreen({super.key});

  @override
  State<DeckManagerScreen> createState() => _DeckManagerScreenState();
}

class _DeckManagerScreenState extends State<DeckManagerScreen> {
  // 1. Premenná, do ktorej uložíme náš sľub (Future)
  late Future<List<Deck>> _myDecksFuture;

  @override
  void initState() {
    super.initState();
    // 2. Hneď na začiatku požiadame databázu o dáta (dostaneme bloček)
    _myDecksFuture = DatabaseHelper.instance.getDecks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Decks"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // 3. FutureBuilder automaticky čaká na dáta a kreslí podľa toho UI
      body: FutureBuilder<List<Deck>>(
        future: _myDecksFuture,
        builder: (context, snapshot) {
          // Kým sa dáta načítavajú, ukážeme točiace sa koliesko
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Ak by náhodou niečo spadlo
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Ak je databáza prázdna
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No decks found. Database is empty!"));
          }

          // Ak máme dáta, rozbalíme si ich do premennej
          final decks = snapshot.data!;

          // Vykreslíme ich ako pekný scrollovateľný zoznam
          return ListView.builder(
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return ListTile(
                leading: Icon(deck.isPremade ? Icons.auto_awesome : Icons.person),
                title: Text(deck.name),
                subtitle: Text(deck.category),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  debugPrint("Klikol si na balíček: ${deck.name}");
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 1. Zistíme, koľko vlastných balíčkov už máme (tie, čo majú isPremade: 0)
          int pocetVlastnych = await DatabaseHelper.instance.getCustomDeckCount();

          if (pocetVlastnych >= 2) {
            // LIMIT DOSIAHNUTÝ (Free Tier limit)
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Limit dosiahnutý"),
                  content: const Text("Vo Free verzii môžeš mať maximálne 2 vlastné balíčky. Kúp si Premium!"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
                  ],
                ),
              );
            }
          } else {
            // Máme menej ako 2, ideme na novú obrazovku!
            if (context.mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateDeckScreen()),
              );
              // Keď sa vrátime späť, prikážeme obrazovke, aby sa načítala znova (aby ukázala nový balíček)
              setState(() {
                _myDecksFuture = DatabaseHelper.instance.getDecks();
              });
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}