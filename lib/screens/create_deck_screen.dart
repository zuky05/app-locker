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

  
  void _saveData() async {
    // 1. Get strings from text fields
    String deckName = _deckNameController.text;

    
    await DatabaseHelper.instance.addNewDeck(deckName, "Custom");

    

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