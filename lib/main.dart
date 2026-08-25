import 'package:flutter/material.dart';
import 'screens/deck_manager_screen.dart'; // This will show a red error until we do the next step!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brainlock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // This is where the app starts now instead of the counter page
      home: const DeckManagerScreen(), 
    );
  }
}