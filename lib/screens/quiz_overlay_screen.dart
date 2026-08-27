import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/database_helper.dart';
import 'package:flutter/services.dart'; // Aby sme mohli použiť MethodChannel

class QuizOverlayScreen extends StatefulWidget {
  const QuizOverlayScreen({super.key});

  @override
  State<QuizOverlayScreen> createState() => _QuizOverlayScreenState();
}

class _QuizOverlayScreenState extends State<QuizOverlayScreen> {
  Map<String, dynamic>? currentQuestion;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRandomQuestion();
  }

  // Funkcia, ktorá zavolá našu novú databázovú mágiu
  Future<void> _loadRandomQuestion() async {
    setState(() => isLoading = true);
    final questionData = await DatabaseHelper.instance.getRandomQuizQuestion();
    setState(() {
      currentQuestion = questionData;
      isLoading = false;
    });
  }

  void checkAnswer(String selectedOption) async {
    if (selectedOption == currentQuestion?['correct_answer']) {
      print("SPRÁVNE! Neskôr tu odomkneme appku.");
      const platform = MethodChannel('brainlock.channel');
      try {
        await platform.invokeMethod('unlockApp', {'minutes': 5});
      } catch (e) {
        print("Chyba pri odomykaní: $e");
      }
    } else {
      print("ZLE! Skús znova.");
      // Ak odpovie zle, môžeme mu napríklad načítať novú otázku
      _loadRandomQuestion();
    }
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
            ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(), // Načítavacie koliesko
              )
            : currentQuestion == null 
              ? const Text("Žiadne kartičky v databáze!")
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_clock, size: 40, color: Colors.deepPurple),
                    const SizedBox(height: 16),
                    const Text(
                      "Čas na odomknutie!",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    
                    // Skutočná otázka z databázy!
                  if (currentQuestion!['prompt'].toString().endsWith('.svg')) ...[
                                      const Text(
                                        "Ktorému štátu patrí táto vlajka?",
                                        style: TextStyle(fontSize: 18, color: Colors.black87),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SvgPicture.asset(
                                          currentQuestion!['prompt'],
                                          height: 110,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        currentQuestion!['prompt'],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                    const SizedBox(height: 24),
                    
                    // Skutočné namixované odpovede!
                    ...(currentQuestion!['options'] as List<String>).map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          backgroundColor: Colors.deepPurple.shade50,
                          foregroundColor: Colors.deepPurple,
                          elevation: 0,
                        ),
                        onPressed: () => checkAnswer(option),
                        child: Text(option),
                      ),
                    )),
                  ],
                ),
        ),
      ),
    );
  }
}