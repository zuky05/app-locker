import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/block_choice_screen.dart';
import 'screens/permission_screen.dart';
import 'services/permission_guard.dart';
import 'package:app_links/app_links.dart';
import 'services/database_helper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late PermissionGuard permissionGuard;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  const platform = MethodChannel('brainlock.channel');

  try {
    final prefs = await SharedPreferences.getInstance();
    final blocked = prefs.getStringList('blocked_apps') ?? ['com.android.chrome'];
    await platform.invokeMethod('setBlockedApps', {'apps': blocked});
  } catch (e) {
    debugPrint("Chyba syncu pri starte: $e");
  }

  bool isOverlay = false;
  bool isTimeout = false;
  String? initialDeckId;

  try {
    final info = await platform.invokeMethod('getOverlayInfo');
    if (info != null) {
      isOverlay = info['isOverlay'] ?? false;
      isTimeout = info['isTimeout'] ?? false;
      initialDeckId = info['deckId'];
    }
  } catch (e) {
    debugPrint("Chyba komunikácie: $e");
  }

  // Inicializácia a spustenie PermissionGuard
  permissionGuard = PermissionGuard(navigatorKey: navigatorKey);
  permissionGuard.startListening();

  runApp(MyApp(
    initialOverlay: isOverlay,
    initialTimeout: isTimeout,
    initialDeckId: initialDeckId,
  ));
}

class MyApp extends StatefulWidget {
  final bool initialOverlay;
  final bool initialTimeout;
  final String? initialDeckId;

  const MyApp({
    super.key,
    required this.initialOverlay,
    required this.initialTimeout,
    this.initialDeckId,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isOverlay;
  late bool isTimeout;
  static const platform = MethodChannel('brainlock.channel');

  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    isOverlay = widget.initialOverlay;
    isTimeout = widget.initialTimeout;

    // 1. Ak sa appka spustila priamo cez deep link v stave Cold Start
    if (widget.initialDeckId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToDeck(widget.initialDeckId!);
      });
    } 
    // 2. Alebo ak sa spustila ako overlay
    else if (isOverlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => BlockChoiceScreen(isTimeout: isTimeout),
          ),
          (route) => false,
        );
      });
    }

    // Odchytávanie správ pri prebudení aplikácie z pozadia (Warm start)
    platform.setMethodCallHandler((call) async {
      if (call.method == 'updateOverlayInfo') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final bool shouldBlock = args['isOverlay'] ?? false;
        final bool timeout = args['isTimeout'] ?? false;

        setState(() {
          isOverlay = shouldBlock;
          isTimeout = timeout;
        });

        if (shouldBlock) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => BlockChoiceScreen(isTimeout: timeout),
            ),
            (route) => false,
          );
        } else {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const PermissionScreen(),
            ),
            (route) => false,
          );
        }
      } else if (call.method == 'handleDeepLink') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final deckId = args['deckId'];
        
        if (deckId != null) {
          _navigateToDeck(deckId);
        }
      }
    });

    // Inicializácia deep linkov priamo v initState
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'brainlock' && uri.host == 'share') {
      final deckId = uri.queryParameters['deckId'];
      
      if (deckId != null) {
        _navigateToDeck(deckId);
      }
    }
  }

  Future<void> _navigateToDeck(String deckId) async {
  debugPrint("Prijatý pokus o import balíčka s ID: $deckId");

  // 1. Zistíme aktuálny počet custom balíčkov a overíme limit (max 3)
  final int customCount = await DatabaseHelper.instance.getCustomDeckCount();
  final int remainingDecks = 3 - customCount;

  final context = navigatorKey.currentContext;
  if (context == null) return;

  // 2. Ak user prekročil limit (3 a viac), zobrazíme Premium dialóg
  if (customCount >= 3) {
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
          "Dosiahol si limit 3 vlastných balíčkov zadarmo.\n\nPre import ďalších balíčkov a neobmedzené vytváranie si aktivuj Premium.",
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
              debugPrint("Navigovať na nákup Premium");
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

  // 3. Ak je pod limitom, zobrazíme potvrdenie o importovaní s počtom voľných slotov
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Chcete importovať deck?"),
      content: Text(
        "Tento zdieľaný balíček bude pridaný do vašej knižnice.\n\nVoľné sloty na custom balíčky: $remainingDecks/3",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext), // Zruší sa screena
          child: const Text("Nie, nechať tak", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.pop(dialogContext); // Zatvoríme dialóg

            // 4. Uloženie balíčka a ukážkových kartičiek do databázy
            // (Názov a kategóriu môžeš prispôsobiť, prípadne parsovať z linku)
            final int newDeckId = await DatabaseHelper.instance.addNewDeck(
              "Zdieľaný balíček ($deckId)", 
              "Shared",
            );

            // Pridáme vzorovú kartičku (alebo viac kartičiek) do novozaloženého balíčka
            await DatabaseHelper.instance.addNewCard(
              newDeckId, 
              "Imported Deck ID", 
              deckId,
            );

            debugPrint("Balíček $deckId úspešne pridaný do databázy!");

            // 5. Presmerovanie na main screen / DeckManagerScreen
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/', // Alebo tvoja hlavná cesta / obrazovka
              (route) => false,
            );
          },
          child: const Text("Áno, importovať"),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Brainlock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 190, 106, 10),
        ),
        useMaterial3: true,
      ),
      home: isOverlay
          ? BlockChoiceScreen(isTimeout: isTimeout)
          : const PermissionScreen(),
      routes: {
        '/permissions': (context) => const PermissionScreen(),
      },
    );
  }
}