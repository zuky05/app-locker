import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/deck_model.dart';
import 'app_selector_screen.dart';
import 'deck_detail_screen.dart';
//toto je na anki a quizlet keby to nechceme treba to vymazat iba som sa s tym hral este 
// pohoda jahoda, vraj nam nemaju aj tak co spravit xd
import 'anki_playground_screen.dart';
import 'quizlet_playground_screen.dart';
//---------------------------

class DeckManagerScreen extends StatefulWidget {
  const DeckManagerScreen({super.key});

  @override
  // 1. TOTO SME PRIDALI: SingleTickerProviderStateMixin je potrebný pre TabController
  State<DeckManagerScreen> createState() => _DeckManagerScreenState();
}

class _DeckManagerScreenState extends State<DeckManagerScreen> with SingleTickerProviderStateMixin {
  List<Deck> myDecks = [];
  List<Deck> premadeDecks = [];
  bool isLoading = true;
  
  // 2. Vytvoríme vlastný TabController
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializujeme kontrolér s 2 záložkami
    _tabController = TabController(length: 2, vsync: this);
    
    // Povieme mu: Zakaždým, keď sa zmení záložka, prekresli obrazovku (aby sa schovalo/ukázalo tlačidlo)
    _tabController.addListener(() {
      setState(() {}); 
    });
    
    _loadDecks();
  }

  @override
  void dispose() {
    // Keď z obrazovky odídeme, kontrolér musíme "zahodiť" z pamäte
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    final loadedDecks = await DatabaseHelper.instance.getDecks();
    
    setState(() {
      myDecks = loadedDecks.where((d) => d.isPremade == 0 || d.isPremade == false).toList();
      premadeDecks = loadedDecks.where((d) => d.isPremade == 1 || d.isPremade == true).toList();
      isLoading = false;
    });
  }

  void _showAddDeckDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nový balíček'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Názov (napr. Španielčina)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Kategória (napr. Jazyky)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušiť'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && categoryController.text.isNotEmpty) {
                await DatabaseHelper.instance.addNewDeck(
                  nameController.text,
                  categoryController.text,
                );
                Navigator.pop(context);
                _loadDecks();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: const Text('Vytvoriť'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckList(List<Deck> deckList) {
    if (deckList.isEmpty) return const Center(child: Text("You have no custom decks."));
    
    return ListView.builder(
      itemCount: deckList.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final deck = deckList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.style, color: Colors.white),
            ),
            title: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(deck.category),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck)),
              ).then((_) => _loadDecks());
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Všimni si: Vyhodili sme DefaultTabController, už tu máme len Scaffold
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brainlock Decks'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // toto je tiez na anki 
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Playground',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnkiPlaygroundScreen())).then((_) => _loadDecks()),
          ),
          //------------------------------
          // toto je tiez na quizlet
          IconButton(
            icon: const Icon(Icons.language), // Ikonka pre Quizlet web
            tooltip: 'Quizlet Playground',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizletPlaygroundScreen())).then((_) => _loadDecks()),
          ),
          //------------------------------
          IconButton(
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AppSelectorScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController, // 3. Pripojili sme náš kontrolér sem
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'My decks', icon: Icon(Icons.person)),
            Tab(text: 'Premade decks', icon: Icon(Icons.library_books)),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController, // 4. A pripojili sme ho aj sem k zobrazeniu
              children: [
                _buildDeckList(myDecks), 
                _buildDeckList(premadeDecks),
              ],
            ),
            
      // 5. TOTO JE KÚZLO: Tlačidlo sa zobrazí iba ak je aktívny index 0 (Moje balíčky)
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showAddDeckDialog,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null, // Na indexe 1 (Predpripravené) vrátime null, takže tlačidlo zmizne
    );
  }
}