import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/theme_provider.dart';
import '../services/revenuecat_service.dart';
import '../themes/themed_background.dart';

class AppSelectorScreen extends StatefulWidget {
  const AppSelectorScreen({super.key});

  @override
  State<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends State<AppSelectorScreen> {
  List<AppInfo> installedApps = [];
  List<AppInfo> filteredApps = [];
  Set<String> blockedPackages = {};
  bool isLoading = true;
  bool isPremium = false;
  final TextEditingController _searchController = TextEditingController();
  static const platform = MethodChannel('brainlock.channel');

  @override
  void initState() {
    super.initState();
    _loadAppsAndSettings();
    _searchController.addListener(_filterApps);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppsAndSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('blocked_apps') ?? [];
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
      filteredApps = apps;
      isPremium = premiumStatus;
      isLoading = false;
    });
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredApps = installedApps.where((app) {
        return app.name.toLowerCase().contains(query);
      }).toList();
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

    final headerDecoration = BoxDecoration(
      color: theme.cardColor,
      borderRadius: currentTheme.cardBorderRadius,
      border: currentTheme.id == 2
          ? Border.all(color: Colors.black, width: 3.5)
          : (currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
      boxShadow: currentTheme.id == 2
          ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]
          : currentTheme.cardShadows,
      gradient: currentTheme.cardGradient,
    );

    final searchDecoration = BoxDecoration(
      color: theme.cardColor,
      borderRadius: currentTheme.cardBorderRadius,
      border: currentTheme.id == 2
          ? Border.all(color: Colors.black, width: 3.5)
          : Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.12)),
      boxShadow: currentTheme.id == 2
          ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]
          : currentTheme.cardShadows,
    );

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Blokované aplikácie'),
          backgroundColor: theme.scaffoldBackgroundColor, // Nepriehľadný AppBar
          foregroundColor: theme.colorScheme.onSurface,
          elevation: theme.appBarTheme.elevation ?? 0,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: accentColor))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: headerDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Ktoré aplikácie zamknúť?",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: currentTheme.id == 2 ? Colors.black : accentColor, 
                                    width: currentTheme.id == 2 ? 2.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  isPremium 
                                      ? "${blockedPackages.length} / ∞" 
                                      : "${blockedPackages.length} / 3",
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Zvolené aplikácie budú prístupné až po úspešnom vyriešení vedomostného testu.",
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      decoration: searchDecoration,
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: "Hľadať aplikáciu...",
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredApps.isEmpty
                        ? Center(
                            child: Text(
                              "Žiadna aplikácia sa nenašla",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredApps.length,
                            itemBuilder: (context, index) {
                              final app = filteredApps[index];
                              final isBlocked = blockedPackages.contains(app.packageName);

                              final itemDecoration = isBlocked
                                  ? currentTheme.getCardDecoration(accentColor, isSelected: true)
                                  : BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: currentTheme.cardBorderRadius,
                                      border: currentTheme.id == 2
                                          ? Border.all(color: Colors.black, width: 3.5)
                                          : (currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
                                      boxShadow: currentTheme.cardShadows,
                                      gradient: currentTheme.cardGradient,
                                    );

                              final textColor = isBlocked
                                  ? currentTheme.getContrastTextColor(accentColor)
                                  : theme.colorScheme.onSurface;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: itemDecoration,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: app.icon != null
                                        ? Image.memory(app.icon!, width: 42, height: 42)
                                        : Icon(Icons.android, size: 42, color: textColor),
                                  ),
                                  title: Text(
                                    app.name,
                                    style: TextStyle(
                                      fontWeight: isBlocked ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 15,
                                      color: textColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isBlocked ? "Zablokovaná" : "Povolená",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isBlocked ? FontWeight.bold : FontWeight.normal,
                                      color: isBlocked 
                                          ? textColor.withValues(alpha: 0.85)
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  trailing: Switch(
                                    value: isBlocked,
                                    activeColor: currentTheme.id == 2 ? Colors.black : accentColor,
                                    activeTrackColor: isBlocked 
                                        ? textColor.withValues(alpha: 0.3) 
                                        : accentColor.withValues(alpha: 0.3),
                                    inactiveThumbColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                    inactiveTrackColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                    onChanged: (_) => _toggleApp(app.packageName),
                                  ),
                                  onTap: () => _toggleApp(app.packageName),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}