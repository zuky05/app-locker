class Deck {
  final int? id;
  final String name;
  final String category;
  final bool isPremade;

  Deck({
    this.id,
    required this.name,
    required this.category,
    required this.isPremade,
  });

  // Converts a Deck object into a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'is_premade': isPremade ? 1 : 0,
    };
  }

  // Converts a SQLite Map row back into a Deck object
  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      isPremade: map['is_premade'] == 1,
    );
  }
}