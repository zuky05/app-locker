import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_themes.dart';
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

  Future<void> _syncBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_apps', blockedPackages.toList());

    try {
      await platform.invokeMethod('setBlockedApps', {'apps': blockedPackages.toList()});
    } catch (e) {
      debugPrint("Chyba synchronizácie s Kotlinom: $e");
    }
  }

  Widget _buildDialogButton({
    required String label,
    required Color accentColor,
    required AppThemeData currentTheme,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final theme = currentTheme.theme;

    BoxDecoration decoration;
    Color textColor;

    if (isSoft) {
      // 🟢 SOFT NEUMORPHISM DIALÓGOVÉ TLAČIDLÁ
      if (isSecondary) {
        decoration = BoxDecoration(
          color: const Color(0xFFD1D9E6),
          borderRadius: currentTheme.buttonBorderRadius,
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF97A7C0),
              offset: Offset(3, 3),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-3, -3),
              blurRadius: 6,
            ),
          ],
        );
        textColor = const Color(0xFF2D3748);
      } else {
        decoration = BoxDecoration(
          color: accentColor,
          borderRadius: currentTheme.buttonBorderRadius,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.45),
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              offset: const Offset(-2, -2),
              blurRadius: 6,
            ),
          ],
        );
        textColor = Colors.white;
      }
    } else if (isSecondary) {
      if (isVibrant) {
        decoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF64748B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
        textColor = Colors.white;
      } else if (currentTheme.id == 0) {
        decoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF334155), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(color: const Color(0xFF00F5FF).withValues(alpha: 0.5), width: 1.5),
        );
        textColor = Colors.white;
      } else if (isNeo) {
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(color: Colors.black, width: 3.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          ],
        );
        textColor = Colors.black;
      } else {
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.cardColor,
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1.5,
          ),
        );
        textColor = theme.colorScheme.onSurface;
      }
    } else {
      decoration = isNeo 
          ? BoxDecoration(
              color: accentColor,
              borderRadius: currentTheme.buttonBorderRadius,
              border: Border.all(color: Colors.black, width: 3.5),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
            )
          : currentTheme.getCardDecoration(accentColor);
      textColor = isNeo ? Colors.black : currentTheme.getContrastTextColor(accentColor);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: currentTheme.buttonBorderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: decoration,
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetAllBlockedApps() async {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final theme = currentTheme.theme;

    final dialogBgColor = isNeo 
        ? Colors.white 
        : (isSoft 
            ? const Color(0xFFD1D9E6) 
            : (isVibrant ? const Color(0xFF0F172A) : theme.cardColor));

    final dialogTextColor = isNeo 
        ? Colors.black 
        : (isSoft 
            ? const Color(0xFF2D3748) 
            : (isVibrant ? Colors.white : theme.colorScheme.onSurface));

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: currentTheme.cardBorderRadius,
          side: isNeo ? const BorderSide(color: Colors.black, width: 3.5) : currentTheme.buttonBorder,
        ),
        title: Text(
          "Odblokovať všetko?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
            color: dialogTextColor,
          ),
        ),
        content: Text(
          "Naozaj chceš odblokovať všetky zablokované aplikácie?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isNeo ? FontWeight.bold : FontWeight.normal,
            color: isNeo ? Colors.black87 : dialogTextColor.withValues(alpha: 0.8),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          _buildDialogButton(
            label: "Zrušiť",
            accentColor: currentTheme.errorColor,
            currentTheme: currentTheme,
            isSecondary: true,
            onTap: () => Navigator.pop(dialogContext, false),
          ),
          const SizedBox(width: 8),
          _buildDialogButton(
            label: "Odblokovať",
            accentColor: currentTheme.errorColor,
            currentTheme: currentTheme,
            onTap: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        blockedPackages.clear();
      });
      await _syncBlockedApps();
    }
  }

  Future<void> _toggleApp(String packageName) async {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;
    final theme = currentTheme.theme;

    final dialogBgColor = isNeo 
        ? Colors.white 
        : (isSoft 
            ? const Color(0xFFD1D9E6) 
            : (isVibrant ? const Color(0xFF0F172A) : theme.cardColor));

    final dialogTextColor = isNeo 
        ? Colors.black 
        : (isSoft 
            ? const Color(0xFF2D3748) 
            : (isVibrant ? Colors.white : theme.colorScheme.onSurface));

    setState(() {
      if (blockedPackages.contains(packageName)) {
        blockedPackages.remove(packageName);
      } else if (isPremium || blockedPackages.length < 3) { 
        blockedPackages.add(packageName);
      } else {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: dialogBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: currentTheme.cardBorderRadius,
              side: isNeo ? const BorderSide(color: Colors.black, width: 3.5) : currentTheme.buttonBorder,
            ),
            title: Column(
              children: [
                Icon(Icons.star_rounded, size: 50, color: isNeo ? Colors.black : currentTheme.warningColor),
                const SizedBox(height: 10),
                Text(
                  "Odomkni Brainlock Premium!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
                    color: dialogTextColor,
                  ),
                ),
              ],
            ),
            content: Text(
              "Dosiahol si limit 3 zablokovaných aplikácií zadarmo.\n\nPre neobmedzené blokovanie aplikácií si aktivuj Premium.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isNeo ? FontWeight.bold : FontWeight.normal,
                color: isNeo ? Colors.black87 : dialogTextColor.withValues(alpha: 0.8),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              _buildDialogButton(
                label: "Zrušiť",
                accentColor: currentTheme.errorColor,
                currentTheme: currentTheme,
                isSecondary: true,
                onTap: () => Navigator.pop(dialogContext),
              ),
              const SizedBox(width: 8),
              _buildDialogButton(
                label: "Odomknúť Premium",
                accentColor: currentTheme.warningColor,
                currentTheme: currentTheme,
                onTap: () async {
                  Navigator.pop(dialogContext);
                  final success = await RevenueCatService.presentPaywall();
                  if (success) {
                    setState(() {
                      isPremium = true;
                      blockedPackages.add(packageName);
                    });
                    _syncBlockedApps();
                  }
                },
              ),
            ],
          ),
        );
        return;
      }
    });

    await _syncBlockedApps();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final Color accentColor = currentTheme.blockedAppsColor;
    final bool isVibrant = currentTheme.id == 5;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;

    final headerDecoration = isNeo
        ? BoxDecoration(
            color: Colors.white,
            borderRadius: currentTheme.cardBorderRadius,
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
          )
        : (isVibrant
            ? BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                borderRadius: currentTheme.cardBorderRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : BoxDecoration(
                color: theme.cardColor,
                borderRadius: currentTheme.cardBorderRadius,
                border: currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                boxShadow: currentTheme.cardShadows,
                gradient: currentTheme.cardGradient,
              ));

    final searchDecoration = isNeo
        ? BoxDecoration(
            color: Colors.white,
            borderRadius: currentTheme.cardBorderRadius,
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
          )
        : (isSoft
            ? BoxDecoration(
                color: const Color(0xFFC8D3E6),
                borderRadius: currentTheme.cardBorderRadius,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF97A7C0),
                    offset: Offset(4, 4),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-4, -4),
                    blurRadius: 6,
                  ),
                ],
              )
            : (isVibrant
                ? BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                    borderRadius: currentTheme.cardBorderRadius,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  )
                : BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: currentTheme.cardBorderRadius,
                    border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.12)),
                    boxShadow: currentTheme.cardShadows,
                  )));

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Blokované aplikácie',
            style: TextStyle(
              fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
              color: isNeo ? Colors.black : theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: isNeo ? Colors.black : theme.colorScheme.onSurface,
          elevation: theme.appBarTheme.elevation ?? 0,
          actions: [
            if (blockedPackages.isNotEmpty)
              IconButton(
                icon: Icon(Icons.restart_alt_rounded, size: 26, color: isNeo ? Colors.black : null),
                tooltip: 'Odblokovať všetko',
                onPressed: _resetAllBlockedApps,
              ),
            const SizedBox(width: 8),
          ],
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
                                  fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
                                  color: isNeo ? Colors.black : (isVibrant ? Colors.white : theme.colorScheme.onSurface),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: isSoft
                                    ? BoxDecoration(
                                        color: const Color(0xFFC8D3E6),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0xFF97A7C0),
                                            offset: Offset(2, 2),
                                            blurRadius: 4,
                                          ),
                                          BoxShadow(
                                            color: Colors.white,
                                            offset: Offset(-2, -2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      )
                                    : BoxDecoration(
                                        color: isNeo ? accentColor : accentColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isNeo ? Colors.black : (isVibrant ? Colors.white : accentColor), 
                                          width: isNeo ? 2.5 : 1,
                                        ),
                                        boxShadow: isNeo ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2))] : null,
                                      ),
                                child: Text(
                                  isPremium 
                                      ? "${blockedPackages.length} / ∞" 
                                      : "${blockedPackages.length} / 3",
                                  style: TextStyle(
                                    color: isNeo ? Colors.black : (isSoft ? accentColor : (isVibrant ? Colors.white : accentColor)),
                                    fontWeight: isNeo ? FontWeight.w900 : FontWeight.bold,
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
                              fontWeight: isNeo ? FontWeight.bold : FontWeight.normal,
                              color: isNeo ? Colors.black87 : (isVibrant ? Colors.white.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
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
                        style: TextStyle(
                          fontWeight: isNeo ? FontWeight.w900 : FontWeight.normal,
                          color: isNeo ? Colors.black : (isVibrant ? Colors.white : theme.colorScheme.onSurface),
                        ),
                        decoration: InputDecoration(
                          hintText: "Hľadať aplikáciu...",
                          hintStyle: TextStyle(
                            color: isNeo ? Colors.black54 : (isVibrant ? Colors.white.withValues(alpha: 0.6) : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isNeo ? Colors.black : (isVibrant ? Colors.white.withValues(alpha: 0.6) : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
                                fontWeight: isNeo ? FontWeight.w900 : FontWeight.normal,
                                color: isNeo ? Colors.black : (isVibrant ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredApps.length,
                            itemBuilder: (context, index) {
                              final app = filteredApps[index];
                              final isBlocked = blockedPackages.contains(app.packageName);

                              final itemDecoration = isNeo
                                  ? (isBlocked
                                      ? BoxDecoration(
                                          color: accentColor,
                                          borderRadius: currentTheme.cardBorderRadius,
                                          border: Border.all(color: Colors.black, width: 3.5),
                                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                                        )
                                      : BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: currentTheme.cardBorderRadius,
                                          border: Border.all(color: Colors.black, width: 3.5),
                                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                                        ))
                                  : (isBlocked
                                      ? currentTheme.getCardDecoration(accentColor, isSelected: true)
                                      : (isVibrant
                                          ? BoxDecoration(
                                              color: const Color(0xFF0F172A).withValues(alpha: 0.70),
                                              borderRadius: currentTheme.cardBorderRadius,
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            )
                                          : BoxDecoration(
                                              color: theme.cardColor,
                                              borderRadius: currentTheme.cardBorderRadius,
                                              border: currentTheme.cardBorder ?? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                                              boxShadow: currentTheme.cardShadows,
                                              gradient: currentTheme.cardGradient,
                                            )));

                              final textColor = isNeo 
                                  ? Colors.black 
                                  : (isBlocked ? currentTheme.getContrastTextColor(accentColor) : (isVibrant ? Colors.white : theme.colorScheme.onSurface));

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
                                      fontWeight: isNeo ? FontWeight.w900 : (isBlocked ? FontWeight.bold : FontWeight.w500),
                                      fontSize: 15,
                                      color: textColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isBlocked ? "Zablokovaná" : "Povolená",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isNeo ? FontWeight.bold : (isBlocked ? FontWeight.bold : FontWeight.normal),
                                      color: isNeo 
                                          ? Colors.black87 
                                          : (isBlocked ? textColor.withValues(alpha: 0.85) : (isVibrant ? Colors.white.withValues(alpha: 0.6) : theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                    ),
                                  ),
                                  trailing: Switch(
                                    value: isBlocked,
                                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                    activeColor: isNeo ? Colors.black : (isSoft ? Colors.white : (isVibrant ? Colors.white : accentColor)),
                                    activeTrackColor: isNeo 
                                        ? Colors.white 
                                        : (isSoft ? accentColor : (isBlocked ? textColor.withValues(alpha: 0.3) : accentColor.withValues(alpha: 0.3))),
                                    inactiveThumbColor: isNeo ? Colors.black54 : (isSoft ? const Color(0xFF97A7C0) : (isVibrant ? Colors.white54 : theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                                    inactiveTrackColor: isNeo ? Colors.white54 : (isSoft ? const Color(0xFFC8D3E6) : (isVibrant ? Colors.white24 : theme.colorScheme.onSurface.withValues(alpha: 0.1))),
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