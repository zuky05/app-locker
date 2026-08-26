import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/deck_manager_screen.dart';
import 'screens/block_choice_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const platform = MethodChannel('brainlock.channel');

  try {
    final prefs = await SharedPreferences.getInstance();
    final blocked = prefs.getStringList('blocked_apps') ?? ['com.android.chrome'];
    await platform.invokeMethod('setBlockedApps', {'apps': blocked});
  } catch (e) {
    print("Chyba syncu pri starte: $e");
  }
  
  bool isOverlay = false;
  bool isTimeout = false; // Nová premenná
  
  try {
    // Ťaháme mapu z Kotlinu
    final info = await platform.invokeMethod('getOverlayInfo');
    if (info != null) {
      isOverlay = info['isOverlay'] ?? false;
      isTimeout = info['isTimeout'] ?? false;
    }
  } catch (e) {
    print("Chyba komunikácie: $e");
  }

  runApp(MyApp(initialOverlay: isOverlay, initialTimeout: isTimeout));
}

class MyApp extends StatefulWidget {
  final bool initialOverlay;
  final bool initialTimeout;
  const MyApp({super.key, required this.initialOverlay, required this.initialTimeout});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isOverlay;
  late bool isTimeout;
  static const platform = MethodChannel('brainlock.channel');

  @override
  void initState() {
    super.initState();
    isOverlay = widget.initialOverlay;
    isTimeout = widget.initialTimeout;
    
    platform.setMethodCallHandler((call) async {
      if (call.method == 'updateOverlayInfo') {
        final args = call.arguments as Map<dynamic, dynamic>;
        setState(() {
          isOverlay = args['isOverlay'] ?? false;
          isTimeout = args['isTimeout'] ?? false;
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
      // Ak je to overlay, posunieme mu informáciu o tom, či je to Timeout!
      home: isOverlay ? BlockChoiceScreen(isTimeout: isTimeout) : const DeckManagerScreen(),
    );
  }
}