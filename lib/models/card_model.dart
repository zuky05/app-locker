import 'dart:convert';

class CardModel {
  final int? id;
  final int deckId;
  final String prompt;
  final String correctAnswer;
  final List<String> distractors;
  final int difficulty;

  CardModel({
    this.id,
    required this.deckId,
    required this.prompt,
    required this.correctAnswer,
    required this.distractors,
    this.difficulty = 1,
  });

  // Converts a Card object into a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'prompt': prompt,
      'correct_answer': correctAnswer,
      'distractors_json': jsonEncode(distractors),
      'difficulty': difficulty,
    };
  }

  // Converts a SQLite Map row back into a Card object
  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      deckId: map['deck_id'],
      prompt: map['prompt'],
      correctAnswer: map['correct_answer'],
      distractors: List<String>.from(jsonDecode(map['distractors_json'])),
      difficulty: map['difficulty'] ?? 1,
    );
  }
}