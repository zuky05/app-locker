class Deck {
  final int id;
  final String name;
  final String category;
  final bool isPremade;
  final String frontLang;
  final String backLang;

  Deck({
    required this.id,
    required this.name,
    required this.category,
    required this.isPremade,
    this.frontLang = 'en-US',
    this.backLang = 'en-US',
  });

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      isPremade: map['is_premade'] == 1,
      frontLang: map['front_lang'] ?? 'en-US',
      backLang: map['back_lang'] ?? 'en-US',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'is_premade': isPremade ? 1 : 0,
      'front_lang': frontLang,
      'back_lang': backLang,
    };
  }
}