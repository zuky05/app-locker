import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionGuard with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('flashpass.channel');
  final GlobalKey<NavigatorState> navigatorKey;

  PermissionGuard({required this.navigatorKey});

  void startListening() {
    WidgetsBinding.instance.addObserver(this);
    checkPermissions();
  }

  void stopListening() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPermissions();
    }
  }

  Future<void> checkPermissions() async {
    try {
      final Map<dynamic, dynamic>? info = await _channel.invokeMapMethod('getOverlayInfo');
      final bool isOverlay = info?['isOverlay'] ?? false;

      // Ak ide o overlay, PermissionGuard NEBUDE presmerovávať obrazovky
      if (isOverlay) {
        return;
      }

      
      final bool isGranted = await _channel.invokeMethod('isAccessibilityGranted');
      
      if (!isGranted) {
        // Ak používateľ odobral práva, prepne ho na PermissionScreen
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/permissions', 
          (route) => false,
        );
      }
    } on PlatformException catch (e) {
      debugPrint("Chyba pri kontrole práv: ${e.message}");
    }
  }
}