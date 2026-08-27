class CardModel {
  final int? id;
  final int deckId;
  final String prompt;
  final String correctAnswer;


  CardModel({
    this.id,
    required this.deckId,
    required this.prompt,
    required this.correctAnswer,
  });

  // Converts a Card object into a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'prompt': prompt,
      'correct_answer': correctAnswer,
    };
  }

  // Converts a SQLite Map row back into a Card object
  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      deckId: map['deck_id'],
      prompt: map['prompt'],
      correctAnswer: map['correct_answer'],

    );
  }
}