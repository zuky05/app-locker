import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/theme_provider.dart';
import 'services/stats_provider.dart';
import 'services/locale_provider.dart';
import 'services/languages.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'screens/block_choice_screen.dart';
import 'screens/permission_screen.dart';
import 'services/permission_guard.dart';
import 'services/database_helper.dart';
import 'services/revenuecat_service.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late PermissionGuard permissionGuard;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Purchases.setLogLevel(LogLevel.error);
  
  await RevenueCatService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  const platform = MethodChannel('flashpass.channel');

  final prefs = await SharedPreferences.getInstance();

  // 🟢 Východzí jazyk pri prvom spustení je 'en'
  final String savedLanguage = prefs.getString('app_language') ?? 'en';

  try {
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

  permissionGuard = PermissionGuard(navigatorKey: navigatorKey);
  permissionGuard.startListening();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => StatsProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider(savedLanguage)),
      ],
      child: MyApp(
        initialOverlay: isOverlay,
        initialTimeout: isTimeout,
        initialFromNotification: isFromNotification,
        initialData: initialData,
      ),
    ),
  );
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
  static const platform = MethodChannel('flashpass.channel');

  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    isOverlay = widget.initialOverlay;
    isTimeout = widget.initialTimeout;
    isFromNotification = widget.initialFromNotification;

    if (widget.initialData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _importDeckFromData(widget.initialData!);
      });
    } else if (isOverlay) {
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

    platform.setMethodCallHandler((call) async {
      if (call.method == 'updateOverlayInfo') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final bool shouldBlock = args['isOverlay'] ?? false;
        final bool timeout = args['isTimeout'] ?? false;
        final bool incomingFromNotif = args['isFromNotification'] ?? false;

        final bool resolvedFromNotification = (isOverlay && isFromNotification) ? true : incomingFromNotif;

        if (shouldBlock != isOverlay || timeout != isTimeout || resolvedFromNotification != isFromNotification) {
          setState(() {
            isOverlay = shouldBlock;
            isTimeout = timeout;
            isFromNotification = resolvedFromNotification;
          });

          if (shouldBlock) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => BlockChoiceScreen(
                  isTimeout: timeout,
                  isFromNotification: resolvedFromNotification,
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
    if (uri.scheme == 'flashpass' && uri.host == 'share') {
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

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'en';
    final AppTexts texts = lang == 'en' ? textsEn : textsSk;

    try {
      String jsonString = utf8.decode(base64Url.decode(base64Data));
      Map<String, dynamic> deckData = jsonDecode(jsonString);

      String title = deckData['title'] ?? (lang == 'en' ? 'Shared Deck' : 'Zdieľaný balíček');
      String category = deckData['category'] ?? 'Shared';
      List cards = deckData['cards'] ?? [];

      final int customCount = await DatabaseHelper.instance.getCustomDeckCount();
      final int remainingDecks = 3 - customCount;

      final bool isPremium = await RevenueCatService.isPremium();

      if (customCount >= 3 && !isPremium) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                const Icon(Icons.star_rounded, size: 50, color: Colors.amber),
                const SizedBox(height: 10),
                Text(
                  texts.premiumLimitTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              texts.premiumLimitCustomDecks,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
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
                child: Text(texts.buttonCancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final success = await RevenueCatService.presentPaywall();
                  if (success) {
                    debugPrint("Nákup úspešný! Importujem balíček...");
                    _importDeckFromData(base64Data);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(texts.buttonUnlockPremium, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          title: Text(lang == 'en' ? "Import '$title'?" : "Importovať '$title'?"),
          content: Text(
            isPremium 
                ? (lang == 'en' 
                    ? "This shared deck contains ${cards.length} cards.\n\n(Premium user: Slots are unlimited!)" 
                    : "Tento zdieľaný balíček obsahuje ${cards.length} kartičiek.\n\n(Premium používateľ: Voľné sloty sú neobmedzené!)")
                : (lang == 'en' 
                    ? "This shared deck contains ${cards.length} cards.\n\nCustom deck slots left: $remainingDecks/3" 
                    : "Tento zdieľaný balíček obsahuje ${cards.length} kartičiek.\n\nVoľné sloty na custom balíčky: $remainingDecks/3"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(texts.buttonCancel, style: const TextStyle(color: Colors.grey)),
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
              child: Text(lang == 'en' ? "Import" : "Importovať"),
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
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'flashpass',
          locale: Locale(localeProvider.locale),
          theme: themeProvider.theme,
          home: isOverlay
              ? BlockChoiceScreen(isTimeout: isTimeout, isFromNotification: isFromNotification)
              : const PermissionScreen(),
          routes: {
            '/permissions': (context) => const PermissionScreen(),
          },
        );
      },
    );
  }
}