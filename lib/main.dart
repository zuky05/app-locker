import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';

import 'screens/block_choice_screen.dart';
import 'screens/permission_screen.dart';
import 'services/permission_guard.dart';
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
  bool isFromNotification = false;
  String? initialData;

  try {
    final info = await platform.invokeMethod('getOverlayInfo');
    if (info != null) {
      isOverlay = info['isOverlay'] ?? false;
      isTimeout = info['isTimeout'] ?? false;
      isFromNotification = info['isFromNotification'] ?? false;
      initialData = info['data'];
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
    initialFromNotification: isFromNotification,
    initialData: initialData,
  ));
}

class MyApp extends StatefulWidget {
  final bool initialOverlay;
  final bool initialTimeout;
  final bool initialFromNotification;
  final String? initialData;

  const MyApp({
    super.key,
    required this.initialOverlay,
    required this.initialTimeout,
    required this.initialFromNotification,
    this.initialData,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isOverlay;
  late bool isTimeout;
  late bool isFromNotification;
  static const platform = MethodChannel('brainlock.channel');

  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    isOverlay = widget.initialOverlay;
    isTimeout = widget.initialTimeout;
    isFromNotification = widget.initialFromNotification;

    // 1. Ak sa appka spustila priamo cez deep link v stave Cold Start
    if (widget.initialData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _importDeckFromData(widget.initialData!);
      });
    } 
    // 2. Alebo ak sa spustila ako overlay
    else if (isOverlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => BlockChoiceScreen(
              isTimeout: isTimeout,
              isFromNotification: isFromNotification,
            ),
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
        final bool incomingFromNotif = args['isFromNotification'] ?? false;

        // KĽÚČOVÁ ZMENA: Ak sme už otvorili test z notifikácie a sme zablokovaní,
        // nesmie to žiadny iný signál z Kotlinu prepísať späť na false!
        final bool resolvedFromNotification = (isOverlay && isFromNotification) ? true : incomingFromNotif;

        if (shouldBlock != isOverlay || timeout != isTimeout || resolvedFromNotification != isFromNotification) {
          setState(() {
            isOverlay = shouldBlock;
            isTimeout = timeout;
            isFromNotification = resolvedFromNotification; // Použijeme poistenú premennú
          });

          if (shouldBlock) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => BlockChoiceScreen(
                  isTimeout: timeout,
                  isFromNotification: resolvedFromNotification, // Pošleme poistenú premennú
                ),
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
        }
      } else if (call.method == 'handleDeepLink') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final rawData = args['data'];
        
        if (rawData != null) {
          Future.delayed(const Duration(milliseconds: 350), () {
            _importDeckFromData(rawData);
          });
        }
      }
    });

    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    _appLinks.uriLinkStream.listen((uri) {
      Future.delayed(const Duration(milliseconds: 350), () {
        _handleDeepLink(uri);
      });
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'brainlock' && uri.host == 'share') {
      final rawData = uri.queryParameters['data'];
      
      if (rawData != null) {
        _importDeckFromData(rawData);
      }
    }
  }

  Future<void> _importDeckFromData(String base64Data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      String jsonString = utf8.decode(base64Url.decode(base64Data));
      Map<String, dynamic> deckData = jsonDecode(jsonString);

      String title = deckData['title'] ?? 'Zdieľaný balíček';
      String category = deckData['category'] ?? 'Shared';
      List cards = deckData['cards'] ?? [];

      final int customCount = await DatabaseHelper.instance.getCustomDeckCount();
      final int remainingDecks = 3 - customCount;

      if (customCount >= 3) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
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
                onPressed: () => Navigator.pop(dialogContext),
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
                  Navigator.pop(dialogContext);
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

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Importovať '$title'?"),
          content: Text(
            "Tento zdieľaný balíček obsahuje ${cards.length} kartičiek.\n\nVoľné sloty na custom balíčky: $remainingDecks/3",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Zrušiť", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                final int newDeckId = await DatabaseHelper.instance.addNewDeck(title, category);

                for (var card in cards) {
                  await DatabaseHelper.instance.addNewCard(
                    newDeckId,
                    card['q'] ?? '',
                    card['a'] ?? '',
                  );
                }

                debugPrint("Balíček '$title' s ${cards.length} kartami úspešne pridaný!");

                navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: const Text("Importovať"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Chyba pri rozkódovaní zdieľaného balíčka: $e");
    }
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
          ? BlockChoiceScreen(isTimeout: isTimeout, isFromNotification: isFromNotification)
          : const PermissionScreen(),
      routes: {
        '/permissions': (context) => const PermissionScreen(),
      },
    );
  }
}