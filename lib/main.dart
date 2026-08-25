import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/deck_manager_screen.dart';
import 'screens/quiz_overlay_screen.dart';
import 'screens/block_choice_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const platform = MethodChannel('brainlock.channel');
  
  bool isOverlay = false;
  try {
    isOverlay = await platform.invokeMethod('isOverlayMode');
  } catch (e) {
    debugPrint("Chyba komunikácie: $e");
  }

  runApp(MyApp(initialOverlay: isOverlay));
}

// Zmenili sme MyApp na StatefulWidget, aby vedel reagovať na zmeny za jazdy
class MyApp extends StatefulWidget {
  final bool initialOverlay;
  const MyApp({super.key, required this.initialOverlay});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isOverlay;
  static const platform = MethodChannel('brainlock.channel');

  @override
  void initState() {
    super.initState();
    isOverlay = widget.initialOverlay;
    
    // TOTO JE KÚZLO: Neustále počúvame, či na nás Kotlin nezakričal
    platform.setMethodCallHandler((call) async {
      if (call.method == 'updateOverlayMode') {
        // Ak Kotlin zavelí "Zmena!", okamžite prekreslíme obrazovku
        setState(() {
          isOverlay = call.arguments as bool;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brainlock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Prepína sa to úplne samo podľa toho, čo povie Kotlin!
      home: isOverlay ? const BlockChoiceScreen() : const DeckManagerScreen(),
    );
  }
}