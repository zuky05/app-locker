import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/deck_model.dart';
import 'app_selector_screen.dart';
import 'deck_detail_screen.dart';
import 'anki_playground_screen.dart';
import 'quizlet_playground_screen.dart';
import 'quiz_overlay_screen.dart';

class DeckManagerScreen extends StatefulWidget {
  const DeckManagerScreen({super.key});

  @override
  State<DeckManagerScreen> createState() => _DeckManagerScreenState();
}

class _DeckManagerScreenState extends State<DeckManagerScreen> with SingleTickerProviderStateMixin {
  List<Deck> myDecks = [];
  List<Deck> premadeDecks = [];
  bool isLoading = true;
  
  // ID balíčka, ktorý je aktuálne rozbalený
  int? expandedDeckId;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); 
    });
    _loadDecks();
  }

  @override
  void dispose() {
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

  // Dialóg pre nákup Premium / vytvorenie nového balíčka
  void _showAddDeckDialog() {
    if (myDecks.length >= 3) {
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
            "Dosiahol si limit 3 vlastných balíčkov zadarmo.\n\nPre neobmedzené vytváranie kartičiek a prístup ku všetkým balíčkom si aktivuj Premium.",
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
      return;
    }

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
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category (e.g. Languages)'),
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
                if (!context.mounted) return;
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

  // Dialóg pre premenovanie balíčka
  void _showRenameDeckDialog(Deck deck) {
    final nameController = TextEditingController(text: deck.name);
    final categoryController = TextEditingController(text: deck.category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upraviť balíček'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Názov balíčka'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Kategória'),
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
                Navigator.pop(context);
                print(nameController.text); 
                print(categoryController.text);
                await DatabaseHelper.instance.updateDeck(deck.id!, nameController.text, categoryController.text);
                _loadDecks();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: const Text('Uložiť'),
          ),
        ],
      ),
    );
  }

  // Dialóg na potvrdenie zmazania balíčka
  void _showDeleteConfirmDialog(Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Vymazať balíček?'),
        content: Text('Naozaj chceš vymazať balíček "${deck.name}"? Táto akcia je nenávratná a vymaže aj všetky kartičky v ňom.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušiť', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.removeDeck(deck.id!);
              _loadDecks();
            },
            child: const Text('Vymazať'),
          ),
        ],
      ),
    );
  }

  // Pomocný widget pre akčné minitlačidlá s ikonou a textom
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckList(List<Deck> deckList) {
    if (deckList.isEmpty) return const Center(child: Text("No custom decks found. Try creating new ones!"));

    return ListView.builder(
      itemCount: deckList.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final deck = deckList[index];
        final isExpanded = expandedDeckId == deck.id;
        final bool isCustom = deck.isPremade == 0 || deck.isPremade == false;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // HLAVNÝ RIADOK BALÍČKA
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.style, color: Colors.white),
                ),
                title: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(deck.category),
                trailing: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.deepPurple,
                ),
                onTap: () {
                  setState(() {
                    expandedDeckId = isExpanded ? null : deck.id;
                  });
                },
              ),

              // ANIMOVANÉ VYSUNUTIE MOŽNOSTÍ (INLINE)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  width: double.infinity,
                  color: Colors.deepPurple.shade50.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // Riadok 1: Štúdium, Test, Share
                      if (!isCustom) ... [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(
                            icon: Icons.style,
                            label: "View",
                            color:  Colors.orange.shade800,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck, isReadOnly: true,)),
                            ).then((_) => _loadDecks()),
                          ),
                          _buildActionButton(
                            icon: Icons.quiz,
                            label: "Test",
                            color:  Colors.green.shade700,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QuizOverlayScreen()),
                            ),
                          ),
                        ],
                      ),
                      ]

                      // Riadok 2: Editácia, Rename, Delete (Iba pre custom balíčky)
                      else if (isCustom) ...[
                        const SizedBox(height: 12),
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(
                            icon: Icons.style,
                            label: "View",
                            color:  Colors.orange.shade800,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck, isReadOnly: true,)),
                            ).then((_) => _loadDecks()),
                          ),
                          _buildActionButton(
                            icon: Icons.quiz,
                            label: "Test",
                            color:  Colors.green.shade700,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QuizOverlayScreen()),
                            ),
                          ),
                          _buildActionButton(
                            icon: Icons.share,
                            label: "Share",
                            color: Colors.blueAccent,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Zdieľanie zatiaľ nie je dostupné.")),
                              );
                            },
                          ),
                        ],
                      ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              icon: Icons.add_circle_outline_outlined,
                              label: "Edit Cards",
                              color:  Colors.pink,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck)),
                              ).then((_) => _loadDecks()),
                            ),
                            _buildActionButton(
                              icon: Icons.edit,
                              label: "Rename",
                              color: Colors.orangeAccent,
                              onTap: () => _showRenameDeckDialog(deck),
                            ),
                            _buildActionButton(
                              icon: Icons.delete,
                              label: "Delete",
                              color: Colors.redAccent,
                              onTap: () => _showDeleteConfirmDialog(deck),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brainlock Decks'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Playground',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnkiPlaygroundScreen())).then((_) => _loadDecks()),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Quizlet Playground',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizletPlaygroundScreen())).then((_) => _loadDecks()),
          ),
          IconButton(
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AppSelectorScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
              controller: _tabController,
              children: [
                _buildDeckList(myDecks), 
                _buildDeckList(premadeDecks),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showAddDeckDialog,
              backgroundColor: myDecks.length >= 3 ? Colors.amber : Colors.deepPurple,
              foregroundColor: Colors.white,
              child: Icon(myDecks.length >= 3 ? Icons.block : Icons.add),
            )
          : null,
    );
  }
}