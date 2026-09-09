import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool isNotificationGranted = false;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    try {
      final bool overlay = await platform.invokeMethod('isOverlayGranted') ?? false;
      final bool accessibility = await platform.invokeMethod('isAccessibilityGranted') ?? false;
      final bool notification = await Permission.notification.isGranted;

      if (mounted) {
        setState(() {
          isOverlayGranted = overlay;
          isAccessibilityGranted = accessibility;
          isNotificationGranted = notification;
          isLoading = false;
        });

        // Ak máme VŠETKY TRI povolenia, ideme do hlavnej aplikácie
        if (overlay && accessibility && notification) {
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

  Future<void> _openSettingsOrRequest() async {
    try {
      if (!isOverlayGranted) {
        await platform.invokeMethod('requestOverlayPermission');
      } else if (!isAccessibilityGranted) {
        await platform.invokeMethod('openAccessibilitySettings');
      } else if (!isNotificationGranted) {
        // Vyvolá štandardný systémový pop-up pre notifikácie
        final status = await Permission.notification.request();
        if (status.isGranted) {
          _checkPermission();
        } else if (status.isPermanentlyDenied) {
          openAppSettings(); // Ak používateľ natvrdo zakázal pop-up
        }
      }
    } catch (e) {
      debugPrint("Chyba vyžadovania povolení: $e");
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

    final bool allGranted = isOverlayGranted && isAccessibilityGranted && isNotificationGranted;

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
                "Pre správne fungovanie blokovania a odpočítavania času je potrebné povoliť nasledujúce tri funkcie.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Overlay
              _buildPermissionTile(
                title: "Prekrytie aplikácií (Overlay)",
                isGranted: isOverlayGranted,
              ),

              const SizedBox(height: 10),

              // 2. Accessibility
              _buildPermissionTile(
                title: "Zjednodušenie prístupu (Accessibility)",
                isGranted: isAccessibilityGranted,
              ),

              const SizedBox(height: 10),

              // 3. Notifications (Upozornenia)
              _buildPermissionTile(
                title: "Upozornenia a odpočet času (Notifications)",
                isGranted: isNotificationGranted,
              ),

              const SizedBox(height: 32),

              // Dynamic Button
              ElevatedButton.icon(
                onPressed: allGranted ? _navigateToMain : _openSettingsOrRequest,
                icon: Icon(allGranted ? Icons.arrow_forward : Icons.settings),
                label: Text(
                  allGranted
                      ? "Pokračovať"
                      : (!isOverlayGranted
                          ? "Povoliť prekrytie"
                          : (!isAccessibilityGranted
                              ? "Povoliť Zjednodušenie prístupu"
                              : "Povoliť Upozornenia")),
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