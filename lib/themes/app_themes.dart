import 'package:flutter/material.dart';

class AppThemes {
  static final List<AppThemeData> availableThemes = [
    _cyberpunkDarkTheme,
    _softNeumorphismTheme,
    _neoBrutalismTheme,
    _cleanMinimalTheme,
    _glassmorphismTheme,
    _vibrantGradientTheme,
  ];

  static final AppThemeData _cyberpunkDarkTheme = AppThemeData(
    id: 0,
    name: 'Cyberpunk Dark',
    isPremium: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF12141D),
      cardColor: const Color(0xFF1E2130),
      primaryColor: const Color(0xFFB388FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB388FF),
        secondary: Color(0xFF00E676),
        surface: Color(0xFF1E2130),
        onPrimary: Colors.white,
        onSurface: Colors.white,
        onSecondaryContainer: Color(0xFF9E9E9E),
        tertiary: Color(0xFFFF9100),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFFB388FF), width: 1.5),
        ),
      ),
    ),
  );

  static final AppThemeData _softNeumorphismTheme = AppThemeData(
    id: 1,
    name: 'Soft Neumorphism',
    isPremium: true,
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0EDF5),
      cardColor: const Color(0xFFF0EDF5),
      primaryColor: const Color(0xFF6B5B95),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6B5B95),
        secondary: Color(0xFF5B9AA0),
        surface: Color(0xFFF0EDF5),
        onPrimary: Colors.white,
        onSurface: Color(0xFF333333),
        onSecondaryContainer: Color(0xFF888888),
        tertiary: Color(0xFFFFB347),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF333333)),
        titleTextStyle: TextStyle(color: Color(0xFF333333), fontSize: 24, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.1), // Opravené tu
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    ),
  );

  static final AppThemeData _neoBrutalismTheme = AppThemeData(
    id: 2,
    name: 'Neo Brutalism',
    isPremium: true,
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      cardColor: const Color(0xFFFFD166),
      primaryColor: Colors.black,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Color(0xFFEF476F),
        surface: Color(0xFFFFD166),
        onPrimary: Colors.white,
        onSurface: Colors.black,
        onSecondaryContainer: Colors.black87,
        tertiary: Color(0xFFFFD166),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        bodyMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Colors.black, width: 4),
        ),
      ),
    ),
  );

  static final AppThemeData _cleanMinimalTheme = AppThemeData(
    id: 3,
    name: 'Clean Minimal',
    isPremium: true,
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      cardColor: Colors.white,
      primaryColor: Colors.black,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Colors.black54,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: Colors.black,
        onSecondaryContainer: Colors.black54,
        tertiary: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
    ),
  );

  static final AppThemeData _glassmorphismTheme = AppThemeData(
    id: 4,
    name: 'Starlight Glass',
    isPremium: true,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E2746),
      cardColor: Colors.white, // dočasne
      primaryColor: Colors.white,
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.white70,
        surface: Colors.white,
        onPrimary: Colors.black,
        onSurface: Colors.white,
        onSecondaryContainer: Colors.white60,
        tertiary: const Color(0xFFFFB300),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.15), // Opravené tu
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1), // Opravené tu
        ),
      ),
    ),
  );

  static final AppThemeData _vibrantGradientTheme = AppThemeData(
    id: 5,
    name: 'Vibrant Gradients',
    isPremium: true,
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      cardColor: const Color(0xFFF52E92),
      primaryColor: const Color(0xFF8A2BE2),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF8A2BE2),
        secondary: Color(0xFF00C6FF),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: Colors.black87,
        onSecondaryContainer: Colors.black54,
        tertiary: Color(0xFFFF8C00),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: const Color(0xFF8A2BE2).withValues(alpha: 0.4), // Opravené tu
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    ),
  );
}

class AppThemeData {
  final int id;
  final String name;
  final bool isPremium;
  final ThemeData theme;

  AppThemeData({
    required this.id,
    required this.name,
    required this.isPremium,
    required this.theme,
  });
}