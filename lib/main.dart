import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/block_choice_screen.dart';
import 'screens/permission_screen.dart';
import 'services/permission_guard.dart';

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

  try {
    final info = await platform.invokeMethod('getOverlayInfo');
    if (info != null) {
      isOverlay = info['isOverlay'] ?? false;
      isTimeout = info['isTimeout'] ?? false;
    }
  } catch (e) {
    debugPrint("Chyba komunikácie: $e");
  }

  // Inicializácia a spustenie PermissionGuard
  permissionGuard = PermissionGuard(navigatorKey: navigatorKey);
  permissionGuard.startListening();

  runApp(MyApp(initialOverlay: isOverlay, initialTimeout: isTimeout));
}

class MyApp extends StatefulWidget {
  final bool initialOverlay;
  final bool initialTimeout;

  const MyApp({
    super.key,
    required this.initialOverlay,
    required this.initialTimeout,
  });

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

    // Ak sa aplikácia spúšťa načisto (Cold start) priamo ako blokovacia obrazovka
    if (isOverlay) {
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

        // Násilný presmerovací príkaz na blokovaciu obrazovku
        if (shouldBlock) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => BlockChoiceScreen(isTimeout: timeout),
            ),
            (route) => false,
          );
        } else {
          // NOVÉ: Ak otvoril appku z ikony, vrátime ho na "domovskú" obrazovku
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              // Použijeme PermissionScreen, ktorý si po udelení povolení 
              // automaticky presmeruje používateľa priamo na HomeScreen
              builder: (context) => const PermissionScreen(),
            ),
            (route) => false,
          );
        }
      }
    });
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