import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/prefs_helper.dart';
import 'quiz_overlay_screen.dart';

class BlockChoiceScreen extends StatefulWidget {
  const BlockChoiceScreen({super.key});

  @override
  State<BlockChoiceScreen> createState() => _BlockChoiceScreenState();
}

class _BlockChoiceScreenState extends State<BlockChoiceScreen> {
  int remainingGrace = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGraceCount();
  }

  Future<void> _loadGraceCount() async {
    int count = await PrefsHelper.getRemainingGraceAttempts();
    setState(() {
      remainingGrace = count;
      isLoading = false;
    });
  }

  void _useGracePeriod() async {
    bool success = await PrefsHelper.useGraceAttempt();
    if (success) {
      const platform = MethodChannel('brainlock.channel');
      try {
        // Pošleme Kotlinu, že chceme IBA 1 MINÚTU
        await platform.invokeMethod('unlockApp', {'minutes': 1});
      } catch (e) {
        print("Chyba: $e");
      }
    }
  }

  void _startTest() {
    // Prepne nás z tejto obrazovky priamo na Kvíz
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const QuizOverlayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      "Zablokované!",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    // HLAVNÉ TLAČIDLO: TEST
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _startTest,
                      child: const Text("Spustiť TEST (5 minút)", style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 12),

                    // DRUHÉ TLAČIDLO: GRACE PERIOD (Iba ak zostávajú pokusy!)
                    if (remainingGrace > 0)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: _useGracePeriod,
                        child: Text("Odpustok na 1 min. ($remainingGrace/3 dnes)"),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          "Dnešné odpustky si už vyčerpal!",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}