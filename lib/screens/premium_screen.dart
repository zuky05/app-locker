import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:provider/provider.dart';
import '../services/revenuecat_service.dart';
import '../themes/theme_provider.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();

    RevenueCatService.addCustomerInfoListener((CustomerInfo info) {
      final isPro = info.entitlements.all[RevenueCatService.entitlementId]?.isActive == true;
      if (mounted) {
        setState(() => _isPremium = isPro);
      }
    });
  }

  Future<void> _checkPremiumStatus() async {
    final isPro = await RevenueCatService.isPremium();
    if (mounted) {
      setState(() {
        _isPremium = isPro;
        _isLoading = false;
      });
    }
  }

  void _openPaywall() async {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentThemeData;
    final success = await RevenueCatService.presentPaywall();
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Vitaj v Premium klube! 🎉",
              style: TextStyle(color: currentTheme.getContrastTextColor(currentTheme.successColor)),
            ), 
            backgroundColor: currentTheme.successColor,
          ),
        );
      }
      _checkPremiumStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: currentTheme.decksColor)),
      );
    }

    final Color unlockBg = currentTheme.warningColor;
    final Color unlockFg = currentTheme.getContrastTextColor(unlockBg);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Brainlock Premium"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPremium ? Icons.workspace_premium : Icons.lock_outline,
                size: 100,
                color: _isPremium 
                    ? currentTheme.warningColor 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 24),
              Text(
                _isPremium ? "Máš aktívne Premium! 👑" : "Používaš Free verziu",
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isPremium 
                    ? "Užívaj si neobmedzené balíčky, importy z Quizletu a všetky funkcie naplno." 
                    : "Odomkni si neobmedzené vlastné balíčky, hromadný import a pokročilé funkcie.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, 
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 40),
              
              if (!_isPremium) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: unlockBg,
                    foregroundColor: unlockFg,
                    shape: RoundedRectangleBorder(
                      borderRadius: currentTheme.buttonBorderRadius,
                      side: currentTheme.buttonBorder,
                    ),
                  ),
                  onPressed: _openPaywall,
                  child: const Text(
                    "Odomknúť Premium", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final success = await RevenueCatService.restorePurchases();
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Nákupy boli úspešne obnovené!", 
                            style: TextStyle(color: currentTheme.getContrastTextColor(currentTheme.successColor)),
                          ), 
                          backgroundColor: currentTheme.successColor,
                        ),
                      );
                      _checkPremiumStatus();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Nenašlo sa žiadne predchádzajúce predplatné.", 
                            style: TextStyle(color: currentTheme.getContrastTextColor(currentTheme.errorColor)),
                          ), 
                          backgroundColor: currentTheme.errorColor,
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Obnoviť nákupy (Restore Purchases)", 
                    style: TextStyle(
                      color: currentTheme.decksColor, 
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: currentTheme.getTileBg(isGranted: false, accentColor: currentTheme.decksColor),
                    foregroundColor: currentTheme.getIconColor(currentTheme.decksColor),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: currentTheme.buttonBorderRadius,
                      side: currentTheme.buttonBorder,
                    ),
                  ),
                  icon: const Icon(Icons.manage_accounts),
                  label: const Text(
                    "Spravovať predplatné", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => RevenueCatService.showCustomerCenter(),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}