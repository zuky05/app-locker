import 'package:flutter/material.dart';

class AppThemeData {
  final int id;
  final String name;
  final bool isPremium;
  final bool isGlass;
  final BorderRadius cardBorderRadius;
  final BorderRadius buttonBorderRadius;
  final Border? cardBorder;
  final List<BoxShadow>? cardShadows;
  final Gradient? cardGradient;
  final ThemeData theme;

  final Color dailyGoalColor;
  final Color decksColor;
  final Color testSetupColor;
  final Color blockedAppsColor;
  final Color quickImportColor;

  AppThemeData({
    required this.id,
    required this.name,
    required this.isPremium,
    this.isGlass = false,
    required this.cardBorderRadius,
    required this.buttonBorderRadius,
    this.cardBorder,
    this.cardShadows,
    this.cardGradient,
    required this.theme,
    required this.dailyGoalColor,
    required this.decksColor,
    required this.testSetupColor,
    required this.blockedAppsColor,
    required this.quickImportColor,
  });
}

class AppThemes {
  static final List<AppThemeData> availableThemes = [
    _cyberpunkDarkTheme,
    _softNeumorphismTheme,
    _neoBrutalismTheme,
    _cleanMinimalTheme,
    _glassmorphismTheme,
    _vibrantGradientTheme,
  ];

  // 1. CYBERPUNK DARK
  static final AppThemeData _cyberpunkDarkTheme = AppThemeData(
    id: 0,
    name: 'Cyberpunk Dark',
    isPremium: true,
    cardBorderRadius: BorderRadius.circular(8),
    buttonBorderRadius: BorderRadius.circular(6),
    cardBorder: Border.all(color: const Color(0xFFBD00FF), width: 1.5),
    cardShadows: [
      BoxShadow(
        color: const Color(0xFFBD00FF).withValues(alpha: 0.35),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ],
    cardGradient: const LinearGradient(
      colors: [Color(0xFF131524), Color(0xFF0D0E17)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    dailyGoalColor: const Color(0xFFBD00FF),    // Neónová fialová
    decksColor: const Color(0xFF00E676),        // Neónová zelená
    testSetupColor: const Color(0xFF00F5FF),    // Neónová azúrová/cyan
    blockedAppsColor: const Color(0xFFFF3D00),  // Červeno-oranžová pre blokované appky
    quickImportColor: const Color(0xFFFFB800),  // Zlatá
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF08090E),
      cardColor: const Color(0xFF131524),
      primaryColor: const Color(0xFFBD00FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFBD00FF),
        onPrimary: Colors.white,
        secondary: Color(0xFF00F5FF), // Azúrová pre texty odpovedí v kvíze!
        tertiary: Color(0xFF00F5FF),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
  );

  // 2. SOFT NEUMORPHISM
  static final AppThemeData _softNeumorphismTheme = AppThemeData(
    id: 1,
    name: 'Soft Neumorphism',
    isPremium: true,
    cardBorderRadius: BorderRadius.circular(20),
    buttonBorderRadius: BorderRadius.circular(16),
    cardShadows: [
      BoxShadow(
        color: const Color(0xFFD1D9E6),
        offset: const Offset(6, 6),
        blurRadius: 12,
      ),
      const BoxShadow(
        color: Colors.white,
        offset: Offset(-6, -6),
        blurRadius: 12,
      ),
    ],
    dailyGoalColor: const Color(0xFF4A4A68),
    decksColor: const Color(0xFF4DB6AC),
    testSetupColor: const Color(0xFF7986CB),
    blockedAppsColor: const Color(0xFFE57373),
    quickImportColor: const Color(0xFF90A4AE),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0F0F3),
      cardColor: const Color(0xFFF0F0F3),
      primaryColor: const Color(0xFF4A4A68),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4A4A68),
        secondary: Color(0xFF4DB6AC),
        surface: Color(0xFFF0F0F3),
        onPrimary: Colors.white,
        onSurface: Color(0xFF2C2C3E),
        onSecondaryContainer: Color(0xFF718096),
        tertiary: Color(0xFF7986CB),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2C2C3E)),
        titleTextStyle: TextStyle(color: Color(0xFF2C2C3E), fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
  );

  // 3. NEO BRUTALISM
  static final AppThemeData _neoBrutalismTheme = AppThemeData(
    id: 2,
    name: 'Neo Brutalism',
    isPremium: true,
    cardBorderRadius: BorderRadius.circular(12),
    buttonBorderRadius: BorderRadius.circular(8),
    cardBorder: Border.all(color: Colors.black, width: 3.5),
    cardShadows: const [
      BoxShadow(
        color: Colors.black,
        offset: Offset(4, 4),
        blurRadius: 0,
      ),
    ],
    dailyGoalColor: const Color(0xFFFFDE59),
    decksColor: const Color(0xFFFF91A4),
    testSetupColor: const Color(0xFF00E5FF),
    blockedAppsColor: const Color(0xFFFF5757),
    quickImportColor: Colors.white,
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      primaryColor: Colors.black,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Color(0xFFFF91A4),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: Colors.black,
        onSecondaryContainer: Colors.black87,
        tertiary: Colors.black,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        bodyMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900),
      ),
    ),
  );

  // 4. CLEAN MINIMAL
  static final AppThemeData _cleanMinimalTheme = AppThemeData(
    id: 3,
    name: 'Clean Minimal',
    isPremium: true,
    cardBorderRadius: BorderRadius.circular(12),
    buttonBorderRadius: BorderRadius.circular(8),
    cardBorder: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
    cardShadows: [],
    dailyGoalColor: const Color(0xFF212121),
    decksColor: const Color(0xFF212121),
    testSetupColor: const Color(0xFF212121),
    blockedAppsColor: const Color(0xFF212121),
    quickImportColor: const Color(0xFF212121),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      primaryColor: const Color(0xFF212121),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF212121),
        secondary: Color(0xFF757575),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: Color(0xFF212121),
        onSecondaryContainer: Color(0xFF9E9E9E),
        tertiary: Color(0xFF212121),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF212121)),
        titleTextStyle: TextStyle(color: Color(0xFF212121), fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
  );

  // 5. STARLIGHT GLASS
  static final AppThemeData _glassmorphismTheme = AppThemeData(
    id: 4,
    name: 'Starlight Glass',
    isPremium: true,
    isGlass: true,
    cardBorderRadius: BorderRadius.circular(24),
    buttonBorderRadius: BorderRadius.circular(18),
    cardBorder: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.15),
        Colors.white.withValues(alpha: 0.05),
      ],
    ),
    cardShadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 20,
        spreadRadius: -5,
      ),
    ],
    dailyGoalColor: Colors.white,
    decksColor: Colors.white,
    testSetupColor: Colors.white,
    blockedAppsColor: Colors.white,
    quickImportColor: Colors.white,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF131B2F),
      cardColor: Colors.white.withValues(alpha: 0.1),
      primaryColor: Colors.white,
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.white70,
        surface: Colors.white.withValues(alpha: 0.1),
        onPrimary: Colors.black,
        onSurface: Colors.white,
        onSecondaryContainer: Colors.white60,
        tertiary: const Color(0xFFFFD54F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
  );

  // 6. VIBRANT GRADIENTS
  static final AppThemeData _vibrantGradientTheme = AppThemeData(
    id: 5,
    name: 'Vibrant Gradients',
    isPremium: true,
    cardBorderRadius: BorderRadius.circular(30),
    buttonBorderRadius: BorderRadius.circular(30),
    cardShadows: [
      BoxShadow(
        color: const Color(0xFFD53369).withValues(alpha: 0.25),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
    cardGradient: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFD53369),
        Color(0xFFDAAE51),
      ],
    ),
    dailyGoalColor: const Color(0xFFD53369),
    decksColor: const Color(0xFF00C9FF),
    testSetupColor: const Color(0xFF8A2BE2),
    blockedAppsColor: const Color(0xFFFF8C00),
    quickImportColor: const Color(0xFF00E676),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardColor: const Color(0xFFD53369),
      primaryColor: const Color(0xFFD53369),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFD53369),
        secondary: Color(0xFF00C9FF),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: Color(0xFF1A1A1A),
        onSecondaryContainer: Color(0xFF9E9E9E),
        tertiary: Color(0xFFFF8C00),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
        titleTextStyle: TextStyle(color: Color(0xFF1A1A1A), fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
  );
}