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

  // Akcentové farby jednotlivých sekcií
  final Color dailyGoalColor;
  final Color decksColor;
  final Color testSetupColor;
  final Color blockedAppsColor;
  final Color quickImportColor;

  // Systémové a stavové farby
  final Color successColor;
  final Color warningColor;
  final Color errorColor;

  // Základné prvky tlačidiel a avatarov
  final Color primaryButtonBg;
  final Color primaryButtonFg;
  final BorderSide buttonBorder;
  final Color circleAvatarBg;
  final Border circleAvatarBorder;

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
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.primaryButtonBg,
    required this.primaryButtonFg,
    required this.buttonBorder,
    required this.circleAvatarBg,
    required this.circleAvatarBorder,
  });

  // --- UNIVERSAL UI HELPER METHODS ---

  /// Vráti dynamický BorderSide pre button/element podľa akcentu sekcie, kde sa nachádza
  BorderSide getButtonBorderSide([Color? accentColor]) {
    final Color activeAccent = accentColor ?? primaryButtonBg;

    if (id == 2) {
      // NEO BRUTALISM: Vždy hrubý čierny okraj
      return const BorderSide(color: Colors.black, width: 3.5);
    } else if (id == 0) {
      // CYBERPUNK: Dynamický okraj vo farbe sekcie
      return BorderSide(color: activeAccent, width: 1.5);
    } else if (id == 4) {
      // STARLIGHT GLASS: Výrazný neónový okraj tlačidiel
      return BorderSide(color: activeAccent, width: 2.0);
    } else if (id == 1) {
      // SOFT NEUMORPHISM
      return const BorderSide(color: Color(0xFF2C2C3E), width: 1.5);
    } else if (id == 5) {
      // VIBRANT GRADIENTS
      return BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5);
    }

    return BorderSide.none;
  }

  /// Vráti univerzálnu dekoráciu pre kartu / button podľa akcentovej farby danej sekcie
  BoxDecoration getCardDecoration(Color accentColor, {bool isSelected = false}) {
    if (id == 2) {
      // NEO BRUTALISM
      return BoxDecoration(
        color: accentColor,
        borderRadius: cardBorderRadius,
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      );
    } else if (id == 0) {
      // CYBERPUNK
      return BoxDecoration(
        color: theme.cardColor,
        borderRadius: cardBorderRadius,
        border: Border.all(color: accentColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      );
    } else if (id == 1) {
      // SOFT NEUMORPHISM
      return BoxDecoration(
        color: Color.alphaBlend(accentColor.withValues(alpha: 0.08), theme.cardColor),
        borderRadius: cardBorderRadius,
        border: isSelected 
            ? Border.all(color: accentColor, width: 2) 
            : Border.all(color: accentColor.withValues(alpha: 0.2), width: 2),
        boxShadow: cardShadows,
      );
    } else if (id == 4) {
      // STARLIGHT GLASS
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.38),
            accentColor.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.08),
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
        borderRadius: cardBorderRadius,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.8),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      );
    } else if (id == 5) {
      // VIBRANT GRADIENTS
      List<Color> gradientColors;

      if (accentColor.value == dailyGoalColor.value) {
        // Výrazný široký mätovo-smaragdový prechod (od svetlej mäty po tmavší smaragd)
        gradientColors = [const Color(0xFF00FF9D), const Color(0xFF047857)];
      } else if (accentColor.value == decksColor.value) {
        // Jasný azúrovo-modrý gradient
        gradientColors = [const Color(0xFF00C6FF), const Color(0xFF0072FF)];
      } else if (accentColor.value == testSetupColor.value) {
        // Sýta fialovo-neónová
        gradientColors = [const Color(0xFFA855F7), const Color(0xFFD946EF)];
      } else if (accentColor.value == blockedAppsColor.value) {
        // Výrazný krvavo-červený gradient
        gradientColors = [const Color(0xFFFF1744), const Color(0xFFB71C1C)];
      } else {
        // Zlatisto-žltý prechod pre Premium Access a Quick Import
        gradientColors = [const Color(0xFFFFD700), const Color(0xFFFF9800)];
      }

      return BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: cardBorderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      );
    } else {
      // CLEAN MINIMAL
      return BoxDecoration(
        color: theme.cardColor,
        borderRadius: cardBorderRadius,
        border: cardBorder ?? Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
        gradient: cardGradient,
        boxShadow: cardShadows,
      );
    }
  }

  /// Zabezpečí čistú čitateľnosť textu
  Color getContrastTextColor(Color accentColor) {
    if (id == 2) {
      return Colors.black;
    }

    if (id == 5) {
      // Čierny text pre žltý Premium Access, Quick Import aj svetlejší Daily Goal
      if (accentColor.value == quickImportColor.value || 
          accentColor.value == warningColor.value || 
          accentColor.value == dailyGoalColor.value) {
        return Colors.black;
      }
      return Colors.white; // Na ostatných sýtych gradientoch (červená, modrá, fialová)
    }

    if (accentColor.value == quickImportColor.value || accentColor.value == warningColor.value) {
      return Colors.black;
    }

    if (id == 0 || id == 4 || theme.brightness == Brightness.dark) {
      return Colors.white;
    }

    return theme.colorScheme.onSurface;
  }

  /// Vráti farbu ikony pre konkrétny button/element
  Color getIconColor(Color accentColor) {
    if (id == 2) {
      return Colors.black;
    }
    if (id == 5) {
      return getContrastTextColor(accentColor);
    }
    if (id == 0 || id == 4) {
      return accentColor; 
    }
    return getContrastTextColor(accentColor);
  }

  /// Pomocník pre stavové dlaždice (PermissionScreen / App Tiles)
  Color getTileBg({required bool isGranted, required Color accentColor}) {
    if (isGranted) {
      return id == 2 ? successColor : successColor.withValues(alpha: 0.15);
    }
    return id == 2 ? accentColor : theme.cardColor;
  }

  Color getTileBorderColor({required bool isGranted, required Color accentColor}) {
    if (id == 2) {
      return Colors.black;
    }
    if (isGranted) {
      return successColor;
    }
    return accentColor;
  }

  /// Okraje tlačidiel pre kvíz/test
  BorderSide getQuizButtonBorder({required bool isChecked, Color? customColor}) {
    if (id == 2) {
      return const BorderSide(color: Colors.black, width: 3.5);
    }
    return BorderSide(
      color: customColor ?? testSetupColor.withValues(alpha: isChecked ? 1.0 : 0.6),
      width: isChecked ? 2.0 : 1.5,
    );
  }
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
    cardBorderRadius: BorderRadius.circular(12),
    buttonBorderRadius: BorderRadius.circular(10),
    cardBorder: Border.all(color: const Color(0xFF00F5FF), width: 1.5),
    cardShadows: [
      BoxShadow(
        color: const Color(0xFF00F5FF).withValues(alpha: 0.25),
        blurRadius: 12,
        spreadRadius: 1,
      ),
    ],
    cardGradient: const LinearGradient(
      colors: [Color(0xFF101625), Color(0xFF0A0D16)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    dailyGoalColor: const Color(0xFF00E676),
    decksColor: const Color(0xFFFF007F),
    testSetupColor: const Color(0xFF00F5FF),
    blockedAppsColor: const Color(0xFFFF3D00),
    quickImportColor: const Color(0xFFFFE600),
    successColor: const Color(0xFF00E676),
    warningColor: const Color(0xFFFFE600),
    errorColor: const Color(0xFFFF3D00),
    primaryButtonBg: const Color(0xFF00F5FF),
    primaryButtonFg: Colors.black,
    buttonBorder: const BorderSide(color: Color(0xFF00F5FF), width: 1.5),
    circleAvatarBg: const Color(0xFF101625),
    circleAvatarBorder: Border.all(color: const Color(0xFF00F5FF), width: 2.0),
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF06080C),
      cardColor: const Color(0xFF101625),
      primaryColor: const Color(0xFF00F5FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00F5FF),
        onPrimary: Colors.black,
        secondary: Color(0xFFFFE600),
        onSecondary: Colors.black,
        tertiary: Color(0xFFFF007F),
        surface: Color(0xFF101625),
        onSurface: Colors.white,
        error: Color(0xFFFF3D00),
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
        color: Colors.black.withValues(alpha: 0.15),
        offset: const Offset(6, 6),
        blurRadius: 12,
      ),
      const BoxShadow(
        color: Colors.white,
        offset: Offset(-6, -6),
        blurRadius: 12,
      ),
    ],
    dailyGoalColor: const Color(0xFF5C6BC0),
    decksColor: const Color(0xFF26A69A),
    testSetupColor: const Color(0xFF7986CB),
    blockedAppsColor: const Color(0xFFEC407A),
    quickImportColor: const Color(0xFF78909C),
    successColor: const Color(0xFF26A69A),
    warningColor: const Color(0xFFFFA726),
    errorColor: const Color(0xFFEF5350),
    primaryButtonBg: const Color(0xFF4A4A68),
    primaryButtonFg: Colors.white,
    buttonBorder: BorderSide.none,
    circleAvatarBg: const Color(0xFFF0F0F3),
    circleAvatarBorder: Border.all(color: const Color(0xFFD1D9E6), width: 1.5),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0F0F3),
      cardColor: const Color(0xFFF0F0F3),
      primaryColor: const Color(0xFF4A4A68),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4A4A68),
        onPrimary: Colors.white,
        secondary: Color(0xFF26A69A),
        onSecondary: Colors.white,
        tertiary: Color(0xFF7986CB),
        surface: Color(0xFFF0F0F3),
        onSurface: Color(0xFF2C2C3E),
        onSecondaryContainer: Color(0xFF718096),
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
    dailyGoalColor: const Color(0xFFB57EDC),
    decksColor: const Color(0xFFFF91A4),
    testSetupColor: const Color(0xFF00E5FF),
    blockedAppsColor: const Color(0xFFFF5757),
    quickImportColor: const Color(0xFFFFDE59),
    successColor: const Color(0xFF00E676),
    warningColor: const Color(0xFFFFDE59),
    errorColor: const Color(0xFFFF5757),
    primaryButtonBg: const Color(0xFF00E676),
    primaryButtonFg: Colors.black,
    buttonBorder: const BorderSide(color: Colors.black, width: 3.5),
    circleAvatarBg: Colors.white,
    circleAvatarBorder: Border.all(color: Colors.black, width: 3.5),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      primaryColor: Colors.black,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Color(0xFFFF91A4),
        onSecondary: Colors.black,
        tertiary: Color(0xFFFFDE59),
        surface: Colors.white,
        onSurface: Colors.black,
        onSecondaryContainer: Colors.black87,
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
    isPremium: false,
    cardBorderRadius: BorderRadius.circular(12),
    buttonBorderRadius: BorderRadius.circular(8),
    cardBorder: Border.all(color: Colors.black, width: 1.0),
    cardShadows: const [],
    dailyGoalColor: const Color(0xFF212121),
    decksColor: const Color(0xFF9E9E9E),
    testSetupColor: const Color(0xFF616161),
    blockedAppsColor: const Color(0xFF757575),
    quickImportColor: const Color(0xFF9E9E9E),
    successColor: const Color(0xFF2E7D32),
    warningColor: const Color(0xFFED6C02),
    errorColor: const Color(0xFFD32F2F),
    primaryButtonBg: const Color(0xFF212121),
    primaryButtonFg: Colors.white,
    buttonBorder: BorderSide.none,
    circleAvatarBg: const Color(0xFFF5F5F5),
    circleAvatarBorder: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      primaryColor: const Color(0xFF212121),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF212121),
        onPrimary: Colors.white,
        secondary: Color(0xFF757575),
        onSecondary: Colors.white,
        tertiary: Color(0xFF212121),
        surface: Colors.white,
        onSurface: Color(0xFF212121),
        onSecondaryContainer: Color(0xFF9E9E9E),
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
    buttonBorderRadius: BorderRadius.circular(16),
    dailyGoalColor: const Color(0xFF00E5FF),    // Ultra Neon Cyan
    decksColor: const Color(0xFF00FF9D),        // Vivid Mint Green
    testSetupColor: const Color(0xFFC040FF),    // Electric Purple
    blockedAppsColor: const Color(0xFFFF2A70),  // Vivid Coral Pink
    quickImportColor: const Color(0xFFFFC700),  // Electric Gold
    successColor: const Color(0xFF00FF9D),
    warningColor: const Color(0xFFFFC700),
    errorColor: const Color(0xFFFF2A70),
    primaryButtonBg: const Color(0xFF00E5FF),
    primaryButtonFg: const Color(0xFF030712),
    buttonBorder: const BorderSide(color: Color(0xFF00E5FF), width: 2.0),
    circleAvatarBg: Colors.white.withValues(alpha: 0.15),
    circleAvatarBorder: Border.all(color: const Color(0xFF00E5FF), width: 2.0),
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF030712),
      cardColor: const Color(0xFF0F172A),
      primaryColor: const Color(0xFF00E5FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00E5FF),
        onPrimary: Color(0xFF030712),
        secondary: Color(0xFF00FF9D),
        onSecondary: Colors.black,
        tertiary: Color(0xFFC040FF),
        surface: Color(0xFF0F172A),
        onSurface: Colors.white,
        onSecondaryContainer: Colors.white70,
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
    cardBorderRadius: BorderRadius.circular(24),
    buttonBorderRadius: BorderRadius.circular(20),
    cardBorder: Border.all(
      color: Colors.white.withValues(alpha: 0.6),
      width: 1.5,
    ),
    cardShadows: [
      BoxShadow(
        color: const Color(0xFF00FF9D).withValues(alpha: 0.25),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
    dailyGoalColor: const Color(0xFF00FF9D),    // Svieža neónovo-mätová zelená
    decksColor: const Color(0xFF00C6FF),        // Azúrová modrá
    testSetupColor: const Color(0xFFA855F7),    // Fialová
    blockedAppsColor: const Color(0xFFFF1744),  // Výrazná červená
    quickImportColor: const Color(0xFFFFD700),  // Žiarivá zlatá
    successColor: const Color(0xFF00FF9D),
    warningColor: const Color(0xFFFFD700),
    errorColor: const Color(0xFFFF1744),
    primaryButtonBg: const Color(0xFFFFD700),
    primaryButtonFg: Colors.black,
    buttonBorder: BorderSide.none,
    circleAvatarBg: Colors.white,
    circleAvatarBorder: Border.all(color: Colors.white, width: 2.0),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F5F9),
      cardColor: const Color(0xFFFFFFFF),
      primaryColor: const Color(0xFFFFD700),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFFD700),
        onPrimary: Colors.black,
        secondary: Color(0xFF00C6FF),
        onSecondary: Colors.white,
        tertiary: Color(0xFFFF1744),
        surface: Colors.white,
        onSurface: Color(0xFF111111),
        onSecondaryContainer: Color(0xFF666666),
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