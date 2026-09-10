import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../models/deck_model.dart';
import 'deck_detail_screen.dart';
import 'quiz_overlay_screen.dart';
import 'quizlet_playground_screen.dart';
import '../services/anki_importer.dart';

class DeckManagerScreen extends StatefulWidget {
  const DeckManagerScreen({super.key});

  @override
  State<DeckManagerScreen> createState() => _DeckManagerScreenState();
}

class _DeckManagerScreenState extends State<DeckManagerScreen> with SingleTickerProviderStateMixin {
  List<Deck> myDecks = [];
  List<Deck> premadeDecks = [];
  bool isLoading = true;
  
  int? expandedDeckId;
  int? activeBlockerDeckId; // <--- Uloží ID balíčka pre zámok

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
    final prefs = await SharedPreferences.getInstance();
    int? activeId = prefs.getInt('active_test_deck_id');

    // SKONTROLUJEME, ČI JE AKTÍVNY BALÍČEK STÁLE PLATNÝ (MÁ ASPOŇ 5 KARTOČIEK)
    if (activeId != null) {
      final activeCardCount = await DatabaseHelper.instance.getCardCountForDeck(activeId);
      if (activeCardCount < 5) {
        await prefs.remove('active_test_deck_id');
        activeId = null;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Aktívny balíček bol odznačený, pretože má menej ako 5 kariet."),
            ),
          );
        }
      }
    }
    
    setState(() {
      myDecks = loadedDecks.where((d) => d.isPremade == 0 || d.isPremade == false).toList();
      premadeDecks = loadedDecks.where((d) => d.isPremade == 1 || d.isPremade == true).toList();
      activeBlockerDeckId = activeId;
      isLoading = false;
    });
  }

  String _getCategoryDescription(String category) {
    switch (category.toLowerCase().trim()) {
      case 'geography':
        return 'Otestuj svoje znalosti hlavných miest, vlajok a geografie sveta.';
      case 'language':
        return 'Rozšír si slovnú zásobu v najpoužívanejších svetových jazykoch.';
      case 'technology':
      case 'tech':
      case 'it':
        return 'Ovládni HTTP status kódy, Linux príkazy a základné vývojárske koncepty.';
      default:
        return 'Pripravené kolekcie kartičiek pre rýchle učenie.';
    }
  }

  Future<void> _handleAnkiImport() async {
    final String? result = await AnkiImporter.importApkgDirect();

    if (result == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result)),
    );

    _loadDecks();
  }

  IconData _getCategoryIcon(String category) {
    final cleanCategory = category.trim().toLowerCase();
    if (cleanCategory.contains('geography')) return Icons.public;
    if (cleanCategory.contains('language')) return Icons.translate;
    if (cleanCategory.contains('tech')) return Icons.terminal;
    return Icons.folder_special;
  }

  void _showAddDeckDialog() async {
    final int customCount = await DatabaseHelper.instance.getCustomDeckCount();

    if (customCount >= 3) {
      if (!mounted) return;
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

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pridať nový balíček', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateManualDeckDialog();
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Add new deck", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QuizletPlaygroundScreen()),
                  ).then((_) => _loadDecks());
                },
                icon: const Icon(Icons.school),
                label: const Text("Import from Quizlet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _handleAnkiImport();
                },
                icon: const Icon(Icons.upload_file),
                label: const Text("Import from Anki", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateManualDeckDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nový balíček'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Názov')),
            const SizedBox(height: 10),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Kategória (napr. Jazyky)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zrušiť')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && categoryController.text.isNotEmpty) {
                await DatabaseHelper.instance.addNewDeck(nameController.text, categoryController.text);
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
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Názov balíčka')),
            const SizedBox(height: 10),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Kategória')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zrušiť')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && categoryController.text.isNotEmpty) {
                Navigator.pop(context);
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

  void _showDeleteConfirmDialog(Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Vymazať balíček?'),
        content: Text('Naozaj chceš vymazať balíček "${deck.name}"? Táto akcia je nenávratná a vymaže aj všetky kartičky v ňom.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zrušiť', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.removeDeck(deck.id!);
              
              if (activeBlockerDeckId == deck.id) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('active_test_deck_id');
              }
              _loadDecks();
            },
            child: const Text('Vymazať'),
          ),
        ],
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  Widget _buildDeckCard(Deck deck) {
    final isExpanded = expandedDeckId == deck.id;
    final bool isCustom = deck.isPremade == 0 || deck.isPremade == false;

    return FutureBuilder<int>(
      future: DatabaseHelper.instance.getCardCountForDeck(deck.id!),
      builder: (context, snapshot) {
        final cardCount = snapshot.data ?? 0;
        final bool hasEnoughCards = cardCount >= 5;
        
        // BALÍČEK JE AKTÍVNY IBA VTDY, AK JE ULOŽENÝ V PREFS A SÚČASNE MÁ ASPOŇ 5 KARTOČIEK
        final bool isActive = (activeBlockerDeckId == deck.id) && hasEnoughCards;

        return Card(
          elevation: isActive ? 4 : 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isActive ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.style, color: Colors.white),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                        child: const Text('AKTÍVNY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                ),
                subtitle: Text("${deck.category} • Karty: $cardCount"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!hasEnoughCards) ...[
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    expandedDeckId = isExpanded ? null : deck.id;
                  });
                },
              ),
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
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(
                            icon: isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                            label: isActive ? "Aktívny" : "Zvoliť",
                            color: isActive ? Colors.green : Colors.grey.shade600,
                            onTap: () async {
                              if (!hasEnoughCards) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Na blokovanie musíte mať aspoň 5 kariet.")),
                                );
                                return;
                              }
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setInt('active_test_deck_id', deck.id!);
                              setState(() => activeBlockerDeckId = deck.id);
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.style,
                            label: "View",
                            color: Colors.orange.shade800,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck, isReadOnly: true)),
                            ).then((_) => _loadDecks()),
                          ),
                          Opacity(
                            opacity: hasEnoughCards ? 1.0 : 0.4,
                            child: _buildActionButton(
                              icon: Icons.quiz,
                              label: "Test",
                              color: Colors.deepPurple,
                              onTap: hasEnoughCards ? () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => QuizOverlayScreen(practiceDeckId: deck.id)),
                              ) : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Na spustenie testu musíte mať aspoň 5 kariet.")),
                                );
                              },
                            ),
                          ),
                          _buildActionButton(
                            icon: Icons.share,
                            label: "Share",
                            color: Colors.blueAccent,
                            onTap: () async {
                              final cards = await DatabaseHelper.instance.getCardsForDeck(deck.id!);

                              final mapData = {
                                'title': deck.name,
                                'category': deck.category,
                                'cards': cards.map((c) => {
                                  'q': c['question'] ?? c['front'] ?? c['prompt'] ?? '',
                                  'a': c['answer'] ?? c['back'] ?? c['correct_answer'] ?? '',
                                }).toList(),
                              };

                              String jsonString = jsonEncode(mapData);
                              String base64Data = base64Url.encode(utf8.encode(jsonString));

                              final String shareLink = 'brainlock://share?data=$base64Data';
                              final String message = 'Poď sa učiť balíček "${deck.name}" v Brainlocku! Klikni pre import: $shareLink';

                              Share.share(message);
                            },
                          ),
                        ],
                      ),
                      
                      if (isCustom) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.add_circle_outline_outlined,
                              label: "Edit Cards",
                              color: Colors.pink,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck)),
                              ).then((_) => _loadDecks()), // <--- TUTO sa pri návrate zavolá _loadDecks() a validuje počet
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

  Widget _buildCustomDeckList(List<Deck> deckList) {
    if (deckList.isEmpty) {
      return const Center(child: Text("Nenašli sa žiadne vlastné balíčky. Skús nejaký vytvoriť!"));
    }
    return ListView.builder(
      itemCount: deckList.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) => _buildDeckCard(deckList[index]),
    );
  }

  Widget _buildGroupedPremadeDeckList(List<Deck> deckList) {
    if (deckList.isEmpty) return const Center(child: Text("Žiadne predpripravené balíčky."));

    final Map<String, List<Deck>> groupedDecks = {};
    for (var deck in deckList) {
      groupedDecks.putIfAbsent(deck.category, () => []).add(deck);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      children: groupedDecks.entries.map((entry) {
        final categoryName = entry.key;
        final categoryDecks = entry.value;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: Icon(_getCategoryIcon(categoryName), color: Colors.deepPurple, size: 28),
              ),
            ),
            iconColor: Colors.deepPurple,
            collapsedIconColor: Colors.deepPurple,
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              categoryName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _getCategoryDescription(categoryName),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: categoryDecks.map((deck) => _buildDeckCard(deck)).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brainlock Decks'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                _buildCustomDeckList(myDecks), 
                _buildGroupedPremadeDeckList(premadeDecks),
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