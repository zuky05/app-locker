import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';


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
      isPremade: map['is_premade'] == 1 || map['is_premade'] == true,
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

  /// Vráti preložený názov pre premade deck na základe rozpoznania názvu, alebo pôvodný názov
  String getLocalizedName(BuildContext context) {
    if (!isPremade) return name;

    final t = Provider.of<LocaleProvider>(context, listen: false).t;
    final cleanName = name.trim().toLowerCase();

    if (cleanName.contains('english') || cleanName.contains('angličtin')) {
      return t.premadeDeckEnglishBasicName;
    }
    if (cleanName.contains('it') || cleanName.contains('programov') || cleanName.contains('computer')) {
      return t.premadeDeckItTermsName;
    }
    if (cleanName.contains('capital') || cleanName.contains('hlavn') || cleanName.contains('geogr')) {
      return t.premadeDeckGeographyName;
    }
    return name;
  }

  /// Vráti preloženú kategóriu pre premade deck na základe rozpoznania kategórie, alebo pôvodnú kategóriu
  String getLocalizedCategory(BuildContext context) {
    if (!isPremade) return category;

    final t = Provider.of<LocaleProvider>(context, listen: false).t;
    final cleanCat = category.trim().toLowerCase();

    if (cleanCat.contains('lang') || cleanCat.contains('jazyk')) {
      return t.premadeCategoryLanguages;
    }
    if (cleanCat.contains('it') || cleanCat.contains('computer') || cleanCat.contains('tech') || cleanCat.contains('informa')) {
      return t.premadeCategoryIt;
    }
    if (cleanCat.contains('geog') || cleanCat.contains('geof')) {
      return t.premadeCategoryGeography;
    }
    return category;
  }
}