import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSelectorScreen extends StatefulWidget {
  const AppSelectorScreen({super.key});

  @override
  State<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends State<AppSelectorScreen> {
  List<AppInfo> installedApps = [];
  Set<String> blockedPackages = {};
  bool isLoading = true;
  static const platform = MethodChannel('brainlock.channel');

  @override
  void initState() {
    super.initState();
    _loadAppsAndSettings();
  }

  Future<void> _loadAppsAndSettings() async {
    // 1. Načítame zoznam blokovaných balíčkov z pamäte
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('blocked_apps') ?? ['com.android.chrome'];
    blockedPackages = savedList.toSet();

    // 2. Načítame všetky reálne aplikácie s ikonami (vylúčime systémové služby)
    List<AppInfo> apps = await InstalledApps.getInstalledApps(excludeNonLaunchableApps: true, excludeSystemApps: false, withIcon: true);
    
    apps.removeWhere((app) => app.packageName == 'com.example.brainlock');

    // Zoradíme ich podľa abecedy
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    setState(() {
      installedApps = apps;
      isLoading = false;
    });
  }

  Future<void> _toggleApp(String packageName) async {
    setState(() {
      if (blockedPackages.contains(packageName)) {
        blockedPackages.remove(packageName);
      } else {
        blockedPackages.add(packageName);
      }
    });

    // Uložíme zmenu do pamäte
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_apps', blockedPackages.toList());

    // Odošleme nový zoznam priamo Ninjovi do Kotlinu
    try {
      await platform.invokeMethod('setBlockedApps', {'apps': blockedPackages.toList()});
    } catch (e) {
      print("Chyba synchronizácie s Kotlinom: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blokované aplikácie'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 stĺpce
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: installedApps.length,
                itemBuilder: (context, index) {
                  final app = installedApps[index];
                  final isBlocked = blockedPackages.contains(app.packageName);

                  return GestureDetector(
                    onTap: () => _toggleApp(app.packageName),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isBlocked ? Colors.deepPurple.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBlocked ? Colors.deepPurple : Colors.grey.shade300,
                          width: isBlocked ? 2 : 1,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Ikona aplikácie
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              app.icon != null
                                  ? Image.memory(app.icon!, width: 48, height: 48)
                                  : const Icon(Icons.android, size: 48, color: Colors.grey),
                              if (isBlocked)
                                const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.deepPurple,
                                  child: Icon(Icons.check, size: 12, color: Colors.white),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Názov aplikácie
                          Text(
                            app.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isBlocked ? FontWeight.bold : FontWeight.normal,
                              color: isBlocked ? Colors.deepPurple : Colors.black87,
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