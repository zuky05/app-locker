import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenuecat_service.dart';

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

    // Počúvame, či sa stav predplatného náhodou nezmenil na pozadí
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
    final success = await RevenueCatService.presentPaywall();
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vitaj v Premium klube! 🎉"), backgroundColor: Colors.green),
        );
      }
      _checkPremiumStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Brainlock Premium"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                color: _isPremium ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                _isPremium ? "Máš aktívne Premium! 👑" : "Používaš Free verziu",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _isPremium 
                    ? "Užívaj si neobmedzené balíčky, importy z Quizletu a všetky funkcie naplno." 
                    : "Odomkni si neobmedzené vlastné balíčky, hromadný import a pokročilé funkcie testovania.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              
              if (!_isPremium) ...[
                // Tlačidlo na kúpu
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _openPaywall,
                  child: const Text("Odomknúť Premium", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                // Povinné tlačidlo pre Apple na obnovenie nákupov
                TextButton(
                  onPressed: () async {
                    final success = await RevenueCatService.restorePurchases();
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text("Nákupy boli úspešne obnovené!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)
                      );
                      _checkPremiumStatus();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text("Nenašlo sa žiadne predchádzajúce predplatné."), backgroundColor: Colors.red)
                      );
                    }
                  },
                  child: const Text("Obnoviť nákupy (Restore Purchases)", style: TextStyle(color: Colors.deepPurple, decoration: TextDecoration.underline)),
                ),
              ] else ...[
                // Ak je Premium, môže si spravovať predplatné
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.deepPurple.shade50,
                    foregroundColor: Colors.deepPurple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.manage_accounts),
                  label: const Text("Spravovať predplatné", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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