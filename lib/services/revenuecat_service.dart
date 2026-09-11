import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class RevenueCatService {
  // Tvoj API Kľúč
  static const String _apiKey = 'test_KTTacZrVSLEsIOoriGChPnLUuAz';
  
  // Tvoje Entitlement ID z dashboardu
  static const String entitlementId = 'shipaton_app_premium';

  // 1. Inicializácia RevenueCat
  static Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid || Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
    }
  }

  // 2. Skontrolovať, či má používateľ zakúpené Premium
  static Future<bool> isPremium() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive == true;
    } catch (e) {
      print("Chyba pri získavaní info o zákazníkovi: $e");
      return false;
    }
  }

  // 3. Počúvanie zmien v predplatnom na pozadí
  static void addCustomerInfoListener(Function(CustomerInfo) onUpdate) {
    Purchases.addCustomerInfoUpdateListener(onUpdate);
  }

  // 4. Zobrazenie moderného Paywallu
  static Future<bool> presentPaywall() async {
    try {
      // ZMENA TU: Iba samotné "entitlementId" bez pomenovania parametra
      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
      );

      return paywallResult == PaywallResult.purchased || 
             paywallResult == PaywallResult.restored;
    } catch (e) {
      print("Chyba pri zobrazovaní Paywallu: $e");
      return false;
    }
  }

  // 5. Zobrazenie Customer Center (kde si môže zrušiť predplatné, vidieť faktúry...)
  static Future<void> showCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      print("Chyba pri zobrazovaní Customer Center: $e");
    }
  }

  // 6. Manuálne obnovenie nákupov
  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive == true;
    } on PlatformException catch (e) {
      print("Chyba pri obnove nákupov: ${e.message}");
      return false;
    }
  }
}