import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/theme_provider.dart';

// 1. IMPORT REVENUECAT
import '../services/revenuecat_service.dart';

class AppSelectorScreen extends StatefulWidget {
  const AppSelectorScreen({super.key});

  @override
  State<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends State<AppSelectorScreen> {
  List<AppInfo> installedApps = [];
  Set<String> blockedPackages = {};
  bool isLoading = true;
  bool isPremium = false; // 2. PRIDANÁ PREMENNÁ PRE PREMIUM
  static const platform = MethodChannel('brainlock.channel');

  @override
  void initState() {
    super.initState();
    _loadAppsAndSettings();
  }

  Future<void> _loadAppsAndSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('blocked_apps') ?? ['com.android.chrome'];
    blockedPackages = savedList.toSet();

    List<AppInfo> apps = await InstalledApps.getInstalledApps(
      excludeNonLaunchableApps: true, 
      excludeSystemApps: false, 
      withIcon: true,
    );
    
    apps.removeWhere((app) => app.packageName == 'com.example.brainlock');
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // 3. NAČÍTAME STAV PREDPLATNÉHO
    final premiumStatus = await RevenueCatService.isPremium();

    setState(() {
      installedApps = apps;
      isPremium = premiumStatus;
      isLoading = false;
    });
  }

  Future<void> _toggleApp(String packageName) async {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;

    setState(() {
      if (blockedPackages.contains(packageName)) {
        blockedPackages.remove(packageName);
      } else if (isPremium || blockedPackages.length < 3) { 
        // 4. KĽÚČOVÁ ZMENA: Ak má Premium, limit 3 sa ignoruje!
        blockedPackages.add(packageName);
      } else {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: currentTheme.theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: currentTheme.cardBorderRadius),
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
              "Dosiahol si limit 3 zablokovaných aplikácií zadarmo.\n\nPre neobmedzené blokovanie aplikácií si aktivuj Premium.",
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
                onPressed: () async {
                  Navigator.pop(dialogContext); // Zatvoríme dialóg
                  // 5. TLAČIDLO TERAZ OTVÁRA PAYWALL
                  final success = await RevenueCatService.presentPaywall();
                  if (success) {
                    setState(() {
                      isPremium = true;
                      blockedPackages.add(packageName); // Automaticky mu pridáme appku, keď zaplatil
                    });
                  }
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
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_apps', blockedPackages.toList());

    try {
      await platform.invokeMethod('setBlockedApps', {'apps': blockedPackages.toList()});
    } catch (e) {
      debugPrint("Chyba synchronizácie s Kotlinom: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final Color activeColor = currentTheme.blockedAppsColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Blokované aplikácie'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: installedApps.length,
                itemBuilder: (context, index) {
                  final app = installedApps[index];
                  final isBlocked = blockedPackages.contains(app.packageName);

                  final Color cardBgColor = isBlocked
                      ? (currentTheme.id == 2 ? activeColor : activeColor.withValues(alpha: 0.18))
                      : theme.cardColor;

                  final Border cardBorder = currentTheme.id == 2
                      ? Border.all(color: Colors.black, width: 3.5)
                      : Border.all(color: activeColor, width: isBlocked ? 2.0 : 1.5);

                  return GestureDetector(
                    onTap: () => _toggleApp(app.packageName),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: currentTheme.cardBorderRadius,
                        border: cardBorder,
                        boxShadow: isBlocked && currentTheme.id != 2
                            ? [BoxShadow(color: activeColor.withValues(alpha: 0.35), blurRadius: 8)]
                            : (isBlocked ? currentTheme.cardShadows : null),
                        gradient: isBlocked ? null : currentTheme.cardGradient,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              app.icon != null
                                  ? Image.memory(app.icon!, width: 48, height: 48)
                                  : Icon(Icons.android, size: 48, color: theme.colorScheme.onSecondaryContainer),
                              if (isBlocked)
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: currentTheme.id == 2 ? Colors.black : activeColor,
                                  child: Icon(
                                    Icons.check, 
                                    size: 12, 
                                    color: currentTheme.id == 2 ? activeColor : Colors.white,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            app.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isBlocked ? FontWeight.bold : FontWeight.normal,
                              color: currentTheme.id == 2 && isBlocked
                                  ? Colors.black
                                  : (isBlocked ? Colors.white : theme.colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}