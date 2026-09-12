import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/theme_provider.dart';
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
  bool isPremium = false;
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
        blockedPackages.add(packageName);
      } else {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: currentTheme.theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: currentTheme.cardBorderRadius),
            title: Column(
              children: [
                Icon(Icons.star_rounded, size: 50, color: currentTheme.warningColor),
                const SizedBox(height: 10),
                Text(
                  "Odomkni Brainlock Premium!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: currentTheme.theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            content: Text(
              "Dosiahol si limit 3 zablokovaných aplikácií zadarmo.\n\nPre neobmedzené blokovanie aplikácií si aktivuj Premium.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: currentTheme.theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTheme.errorColor,
                  foregroundColor: currentTheme.getContrastTextColor(currentTheme.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.buttonBorderRadius,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text("Zrušiť"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final success = await RevenueCatService.presentPaywall();
                  if (success) {
                    setState(() {
                      isPremium = true;
                      blockedPackages.add(packageName);
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTheme.warningColor,
                  foregroundColor: currentTheme.getContrastTextColor(currentTheme.warningColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.buttonBorderRadius,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    final Color accentColor = currentTheme.blockedAppsColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Blokované aplikácie'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: currentTheme.blockedAppsColor))
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

                  final cardDecoration = isBlocked
                      ? currentTheme.getCardDecoration(accentColor, isSelected: true)
                      : BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: currentTheme.cardBorderRadius,
                          border: null,
                          boxShadow: currentTheme.cardShadows,
                          gradient: currentTheme.cardGradient,
                        );

                  final textColor = isBlocked
                      ? currentTheme.getContrastTextColor(accentColor)
                      : theme.colorScheme.onSurface;

                  return GestureDetector(
                    onTap: () => _toggleApp(app.packageName),
                    child: Container(
                      decoration: cardDecoration,
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
                                  backgroundColor: currentTheme.getContrastTextColor(accentColor),
                                  child: Icon(
                                    Icons.check, 
                                    size: 12, 
                                    color: accentColor,
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
                              color: textColor,
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