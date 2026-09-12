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
      // CYBERPUNK: Dynamický okraj vo farbe sekcie (ružová pre decks, zelená pre daily goal...)
      return BorderSide(color: activeAccent, width: 1.5);
    } else if (id == 4) {
      // STARLIGHT GLASS: Jemný sklenený okraj vo farbe akcentu
      return BorderSide(color: activeAccent.withValues(alpha: 0.4), width: 1.0);
    }  else if (id == 1) {
    // SOFT NEUMORPHISM: Tu nastavíš ten jednoduchý tmavý/čierny okraj pre štít a button
    return const BorderSide(color: Color(0xFF2C2C3E), width: 1.5);
    }

    // Bez okrajov pre témy bez button borderov
    return BorderSide.none;
  }

  /// Vráti univerzálnu dekoráciu pre kartu / button podľa akcentovej farby danej sekcie
  BoxDecoration getCardDecoration(Color accentColor, {bool isSelected = false}) {
    if (id == 2) {
      // NEO BRUTALISM: Plná farba akcentu, hrubý čierny border a tvrdý tieň
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
      // CYBERPUNK: Okraj AJ neónová žiara VŽDY striktne používajú accentColor konkrétnej karty
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
  // SOFT NEUMORPHISM: Pozadie dostane 8% tónovanie z akcentu danej sekcie
      return BoxDecoration(
        color: Color.alphaBlend(accentColor.withValues(alpha: 0.08), theme.cardColor),
        borderRadius: cardBorderRadius,
        border: isSelected 
            ? Border.all(color: accentColor, width: 2) 
            : Border.all(color: accentColor.withValues(alpha: 0.2), width: 2),
        boxShadow: cardShadows,
      );
      } else if (id == 5) {
      // VIBRANT GRADIENTS
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.85),
            accentColor.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: cardBorderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      );
    } else {
      // CLEAN MINIMAL & STARLIGHT GLASS
      return BoxDecoration(
        color: isGlass ? Colors.white.withValues(alpha: 0.1) : theme.cardColor,
        borderRadius: cardBorderRadius,
        border: cardBorder ?? Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
        gradient: cardGradient,
        boxShadow: cardShadows,
      );
    }
  }

  /// Zabezpečí čistú čitateľnosť textu pre všetky neónové aj tmavé tlačidlá
  Color getContrastTextColor(Color accentColor) {
    if (id == 2) {
      return Colors.black; // Neo-Brutalism má vždy čierny text
    }
    
    // Ak je farba jasne žltá (Quick Import), použijeme čierny text pre čitateľnosť
    if (accentColor.value == quickImportColor.value || accentColor.value == warningColor.value) {
      
      return Colors.black;
    }

    // Pre Cyberpunk a tmavé témy je text biely a čitateľný
    if (id == 0 || theme.brightness == Brightness.dark) {
      return Colors.white;
    }


    return theme.colorScheme.onSurface;
  }

  /// Vráti farbu ikony pre konkrétny button/element
  Color getIconColor(Color accentColor) {
    if (id == 2) {
      return Colors.black;
    }
    if (id == 0) {
      return accentColor; // V Cyberpunku ikony svietia akcentom
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
    dailyGoalColor: const Color(0xFF00E676),    // Neónová zelená pre Daily Goal
    decksColor: const Color(0xFFFF007F),        // Neónová ružová pre Decks
    testSetupColor: const Color(0xFF00F5FF),    // Neónová azúrová pre Test Setup
    blockedAppsColor: const Color(0xFFFF3D00),  // Neónová oranžová pre Blocked Apps
    quickImportColor: const Color(0xFFFFE600),  // Neónová žltá
    successColor: const Color(0xFF00E676),      // Neónová zelená
    warningColor: const Color(0xFFFFE600),      // Neónová žltá
    errorColor: const Color(0xFFFF3D00),        // Neónová červená/oranžová
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
        offset: Offset(6, 6),
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
    cardBorder: Border.all(color:  Colors.black, width: 1.0),
    cardShadows: const [],
    dailyGoalColor: const Color(0xFF212121),
    decksColor: const Color(0xFF616161),
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
    buttonBorderRadius: BorderRadius.circular(18),
    cardBorder: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
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
    dailyGoalColor: const Color(0xFF38BDF8),
    decksColor: const Color(0xFF34D399),
    testSetupColor: const Color(0xFFA78BFA),
    blockedAppsColor: const Color(0xFFFB7185),
    quickImportColor: const Color(0xFFFBBF24),
    successColor: const Color(0xFF34D399),
    warningColor: const Color(0xFFFBBF24),
    errorColor: const Color(0xFFFB7185),
    primaryButtonBg: Colors.white,
    primaryButtonFg: const Color(0xFF0F172A),
    buttonBorder: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
    circleAvatarBg: Colors.white.withValues(alpha: 0.1),
    circleAvatarBorder: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF1E293B),
      primaryColor: Colors.white,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Color(0xFF0F172A),
        secondary: Color(0xFF38BDF8),
        onSecondary: Colors.black,
        tertiary: Color(0xFFFFD54F),
        surface: Color(0xFF1E293B),
        onSurface: Colors.white,
        onSecondaryContainer: Colors.white60,
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
      color: Colors.white.withValues(alpha: 0.5),
      width: 1.5,
    ),
    cardShadows: [
      BoxShadow(
        color: const Color(0xFFD53369).withValues(alpha: 0.18),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
    cardGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFFD53369).withValues(alpha: 0.85),
        const Color(0xFFDAAE51).withValues(alpha: 0.85),
      ],
    ),
    dailyGoalColor: const Color(0xFFD53369),
    decksColor: const Color(0xFF00C9FF),
    testSetupColor: const Color(0xFF8A2BE2),
    blockedAppsColor: const Color(0xFFFF8C00),
    quickImportColor: const Color(0xFF00E676),
    successColor: const Color(0xFF00E676),
    warningColor: const Color(0xFFFF8C00),
    errorColor: const Color(0xFFFF3366),
    primaryButtonBg: const Color(0xFFD53369),
    primaryButtonFg: Colors.white,
    buttonBorder: BorderSide.none,
    circleAvatarBg: Colors.white,
    circleAvatarBorder: Border.all(color: const Color(0xFFD53369).withValues(alpha: 0.3), width: 2.0),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardColor: const Color(0xFFFFFFFF),
      primaryColor: const Color(0xFFD53369),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFD53369),
        onPrimary: Colors.white,
        secondary: Color(0xFF00C9FF),
        onSecondary: Colors.white,
        tertiary: Color(0xFFFF8C00),
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