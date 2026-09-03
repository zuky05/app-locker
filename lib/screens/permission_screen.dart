import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  static const platform = MethodChannel('brainlock.channel');
  
  bool isOverlayGranted = false;
  bool isAccessibilityGranted = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Deteguje návrat používateľa zo systémových nastavení
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    try {
      // Skontrolujeme OBE povolenia
      final bool overlay = await platform.invokeMethod('isOverlayGranted') ?? false;
      final bool accessibility = await platform.invokeMethod('isAccessibilityGranted') ?? false;

      if (mounted) {
        setState(() {
          isOverlayGranted = overlay;
          isAccessibilityGranted = accessibility;
          isLoading = false;
        });

        // Ak máme OBE povolenia udelené, navigujeme do hlavnej aplikácie
        if (overlay && accessibility) {
          _navigateToMain();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Otvára systémové nastavenia postupne podľa toho, čo chýba
  Future<void> _openSettings() async {
    try {
      if (!isOverlayGranted) {
        await platform.invokeMethod('requestOverlayPermission');
      } else if (!isAccessibilityGranted) {
        await platform.invokeMethod('openAccessibilitySettings');
      }
    } catch (e) {
      debugPrint("Chyba otvárania nastavení: $e");
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
      );
    }

    final bool allGranted = isOverlayGranted && isAccessibilityGranted;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 70,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Vyžaduje sa aktivácia",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Pre správne blokovanie aplikácií je potrebné povoliť vykresľovanie cez iné aplikácie a službu Zjednodušenia prístupu (Accessibility).",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Stav 1: Overlay
              _buildPermissionTile(
                title: "Prekrytie aplikácií (Overlay)",
                isGranted: isOverlayGranted,
              ),

              const SizedBox(height: 12),

              // Stav 2: Accessibility
              _buildPermissionTile(
                title: "Zjednodušenie prístupu (Accessibility)",
                isGranted: isAccessibilityGranted,
              ),

              const SizedBox(height: 32),

              // Hlavné tlačidlo
              ElevatedButton.icon(
                onPressed: allGranted ? _navigateToMain : _openSettings,
                icon: Icon(allGranted ? Icons.arrow_forward : Icons.settings),
                label: Text(
                  allGranted
                      ? "Pokračovať"
                      : (!isOverlayGranted
                          ? "Povoliť prekrytie"
                          : "Povoliť Zjednodušenie prístupu"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({required String title, required bool isGranted}) {
    return Card(
      elevation: 0,
      color: isGranted ? Colors.green.shade50 : Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isGranted ? Colors.green : Colors.amber.shade700,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isGranted ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isGranted ? Colors.green : Colors.amber.shade900,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isGranted ? Colors.green.shade900 : Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}