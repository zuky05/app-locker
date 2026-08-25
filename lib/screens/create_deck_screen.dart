import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  // Controllers to read text from the input fields
  final _deckNameController = TextEditingController();
  final _promptController = TextEditingController();
  final _answerController = TextEditingController();
  final _wrong1Controller = TextEditingController();
  final _wrong2Controller = TextEditingController();
  final _wrong3Controller = TextEditingController();

  void _saveData() async {
    // 1. Get strings from text fields
    String deckName = _deckNameController.text;
    String prompt = _promptController.text;
    String answer = _answerController.text;

    // 2. Put wrong answers into a List (exactly how your new function wants it)
    List<String> distractors = [
      _wrong1Controller.text,
      _wrong2Controller.text,
      _wrong3Controller.text,
    ];

    // 3. Save the new deck using YOUR custom function and get the ID
    int newDeckId = await DatabaseHelper.instance.addNewDeck(deckName, "Custom");

    // 4. Save the first card to this new deck using YOUR custom function
    await DatabaseHelper.instance.addNewCard(newDeckId, prompt, answer, distractors);

    // 5. Close this screen and go back to the manager
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Deck"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _deckNameController, 
              decoration: const InputDecoration(labelText: "Deck Name (e.g. History)")
            ),
            const Divider(height: 40),
            const Text(
              "First Card:", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _promptController, 
              decoration: const InputDecoration(labelText: "Question (Prompt)")
            ),
            TextField(
              controller: _answerController, 
              decoration: const InputDecoration(labelText: "Correct Answer")
            ),
            TextField(
              controller: _wrong1Controller, 
              decoration: const InputDecoration(labelText: "Wrong Answer 1")
            ),
            TextField(
              controller: _wrong2Controller, 
              decoration: const InputDecoration(labelText: "Wrong Answer 2")
            ),
            TextField(
              controller: _wrong3Controller, 
              decoration: const InputDecoration(labelText: "Wrong Answer 3")
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveData,
                child: const Text("Save Deck & Card"),
              ),
            )
          ],
        ),
      ),
    );
  }
}