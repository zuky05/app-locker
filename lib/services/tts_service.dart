import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _isInitialized = true;
  }

  /// Odstráni emoji znaky, symboly a Unicode vlajky z textu
  static String removeEmojis(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E6}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{200D}\u{FE0F}]',
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Automatická detekcia jazyka (Fallback pre prípad, že balíček nemá zadaný jazyk)
  static String detectLanguage(String text) {
    final cleanText = text.trim();
    final lower = cleanText.toLowerCase();

    // 1. Nemčina
    if (RegExp(r'[ß]').hasMatch(lower) ||
        RegExp(r'\b(der|die|das|und|ist|nicht|ein|eine|mit|für|auf|zu|im|dem|den|wie|auch)\b').hasMatch(lower)) {
      return 'de-DE';
    }

    // 2. Fínština
    if (RegExp(r'[äö]').hasMatch(lower) ||
        RegExp(r'\b(ja|on|ei|se|hän|ovat|kuin|tai|myös|mukaan|jotka|olla|hinnat|mutta|kiitos|hei|päivää)\b').hasMatch(lower) ||
        RegExp(r'(ssa|ssä|sta|stä|lla|llä|lta|ltä|ksi|tta|ttä)$').hasMatch(lower)) {
      return 'fi-FI';
    }

    // 3. Francúzština
    if (RegExp(r'[œæç]').hasMatch(lower) ||
        RegExp(r'\b(le|la|les|un|une|est|pas|pour|sur|avec|dans|du|des|que)\b').hasMatch(lower)) {
      return 'fr-FR';
    }

    // 4. Španielčina
    if (RegExp(r'[ñ¿¡]').hasMatch(lower) ||
        RegExp(r'\b(el|la|los|las|un|una|por|para|como|pero|mas|con|por|que)\b').hasMatch(lower)) {
      return 'es-ES';
    }

    // 5. Slovenčina
    if (RegExp(r'[ôĺŕľ]').hasMatch(lower) ||
        RegExp(r'\b(je|sú|nie|ako|ale|pre|na|zo|pri|však|bol|bola|kde|keď|alebo)\b').hasMatch(lower) ||
        RegExp(r'[ščťžýáíéúň]').hasMatch(lower)) {
      return 'sk-SK';
    }

    // Default: Angličtina
    return 'en-US';
  }

  /// Prehrá čistý text bez emoji. Ak odovzdáš targetLanguage, použi ten.
  static Future<void> speak(String text, {String? targetLanguage}) async {
    final cleanedText = removeEmojis(text);
    if (cleanedText.isEmpty || cleanedText.toLowerCase().endsWith('.svg')) return;

    await init();
    final langCode = (targetLanguage != null && targetLanguage.isNotEmpty)
        ? targetLanguage
        : detectLanguage(cleanedText);

    await _flutterTts.stop();
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.speak(cleanedText);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
  }
}