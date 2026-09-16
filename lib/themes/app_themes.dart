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

  BorderSide getButtonBorderSide([Color? accentColor]) {
    final Color activeAccent = accentColor ?? primaryButtonBg;

    if (id == 2) {
      return const BorderSide(color: Colors.black, width: 3.5);
    } else if (id == 0) {
      return BorderSide(color: activeAccent, width: 1.5);
    } else if (id == 4) {
      return BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.2);
    } else if (id == 1) {
      return BorderSide.none;
    } else if (id == 5) {
      return BorderSide(color: Colors.white.withValues(alpha: 0.75), width: 1.5);
    }

    return BorderSide.none;
  }

  BoxDecoration getCardDecoration(Color accentColor, {bool isSelected = false}) {
    if (id == 2) {
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
      // 🟢 SOFT NEUMORPHISM (Vyvážený 3D kontrast)
      if (isSelected) {
        // Zapustený / stlačený stav (Inset Concave)
        return BoxDecoration(
          color: const Color(0xFFC8D3E6),
          borderRadius: cardBorderRadius,
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF97A7C0),
              offset: Offset(4, 4),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 6,
            ),
          ],
        );
      }

      // Vystúpený 3D stav (Raised Convex UI)
      return BoxDecoration(
        color: theme.cardColor,
        borderRadius: cardBorderRadius,
        boxShadow: const [
          // Sýty spodný pravý tieň
          BoxShadow(
            color: Color(0xFF97A7C0),
            offset: Offset(7, 7),
            blurRadius: 14,
            spreadRadius: 1,
          ),
          // Čistý horný ľavý biely odlesk
          BoxShadow(
            color: Colors.white,
            offset: Offset(-7, -7),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      );
    } else if (id == 4) {
      return BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.45),
        borderRadius: cardBorderRadius,
        border: Border.all(
          color: isSelected 
              ? accentColor.withValues(alpha: 0.90) 
              : Color.alphaBlend(accentColor.withValues(alpha: 0.50), Colors.white.withValues(alpha: 0.25)),
          width: isSelected ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      );
    } else if (id == 5) {
      List<Color> gradientColors;

      if (accentColor.toARGB32() == dailyGoalColor.toARGB32()) {
        gradientColors = [const Color(0xFF00FF87), const Color(0xFF004D25)];
      } else if (accentColor.toARGB32() == decksColor.toARGB32()) {
        gradientColors = [const Color(0xFF00F2FE), const Color(0xFF003BB3), const Color(0xFF010038)];
      } else if (accentColor.toARGB32() == testSetupColor.toARGB32()) {
        gradientColors = [const Color(0xFFFF2A85), const Color(0xFF8B008B), const Color(0xFF330047)];
      } else if (accentColor.toARGB32() == blockedAppsColor.toARGB32()) {
        gradientColors = [const Color(0xFFFF3344), const Color(0xFF88000E), const Color(0xFF330005)];
      } else {
        gradientColors = [const Color(0xFFFFB700), const Color(0xFFD84315), const Color(0xFF4E1500)];
      }

      return BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: cardBorderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
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
      return BoxDecoration(
        color: theme.cardColor,
        borderRadius: cardBorderRadius,
        border: cardBorder ?? Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
        gradient: cardGradient,
        boxShadow: cardShadows,
      );
    }
  }

  Color getContrastTextColor(Color accentColor) {
    if (id == 2) {
      return Colors.black;
    }

    if (id == 1) {
      return const Color(0xFF2D3748);
    }

    if (id == 5) {
      return Colors.white;
    }

    if (accentColor.toARGB32() == quickImportColor.toARGB32() || accentColor.toARGB32() == warningColor.toARGB32()) {
      return Colors.black;
    }

    if (id == 0 || id == 4 || theme.brightness == Brightness.dark) {
      return Colors.white;
    }

    return theme.colorScheme.onSurface;
  }

  Color getIconColor(Color accentColor) {
    if (id == 2) {
      return Colors.black;
    }
    if (id == 1) {
      return accentColor;
    }
    if (id == 5) {
      return Colors.white;
    }
    if (id == 0 || id == 4) {
      return accentColor; 
    }
    return getContrastTextColor(accentColor);
  }

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

  BorderSide getQuizButtonBorder({required bool isChecked, Color? customColor}) {
    if (id == 2) {
      return const BorderSide(color: Colors.black, width: 3.5);
    }
    if (id == 1) {
      return BorderSide.none;
    }
    return BorderSide(
      color: customColor ?? testSetupColor.withValues(alpha: isChecked ? 1.0 : 0.6),
      width: isChecked ? 2.0 : 1.5,
    );
  }

  PreferredSizeWidget getAppBarDivider() {
    if (id == 2) {
      return const PreferredSize(
        preferredSize: Size.fromHeight(3.5),
        child: Divider(height: 3.5, thickness: 3.5, color: Colors.black),
      );
    } else if (id == 1) {
      return const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      );
    } else if (id == 0) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(
          height: 1.5,
          color: testSetupColor.withValues(alpha: 0.6),
        ),
      );
    } else if (id == 4) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(
          height: 1.5,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      );
    } else if (id == 5) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(
          height: 1.5,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      );
    }

    return PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Divider(height: 1.0, thickness: 1.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
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

  // 🟢 SOFT NEUMORPHISM (Perfektný odtieň `#D1D9E6`)
  static final AppThemeData _softNeumorphismTheme = AppThemeData(
    id: 1,
    name: 'Soft Neumorphism',
    isPremium: true,
    cardBorderRadius: BorderRadius.circular(22),
    buttonBorderRadius: BorderRadius.circular(18),
    cardShadows: const [
      BoxShadow(
        color: Color(0xFF97A7C0),
        offset: Offset(7, 7),
        blurRadius: 14,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: Colors.white,
        offset: Offset(-7, -7),
        blurRadius: 14,
        spreadRadius: 1,
      ),
    ],
    dailyGoalColor: const Color(0xFF6C5CE7),
    decksColor: const Color(0xFF00CEC9),
    testSetupColor: const Color(0xFF0984E3),
    blockedAppsColor: const Color(0xFFFF7675),
    quickImportColor: const Color(0xFFA29BFE),
    successColor: const Color(0xFF00B894),
    warningColor: const Color(0xFFFDCB6E),
    errorColor: const Color(0xFFFF7675),
    primaryButtonBg: const Color(0xFF6C5CE7),
    primaryButtonFg: Colors.white,
    buttonBorder: BorderSide.none,
    circleAvatarBg: const Color(0xFFD1D9E6),
    circleAvatarBorder: Border.all(color: Colors.white, width: 2.0),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFD1D9E6), // 🟢 Klasický sýty Neumorphism podklad
      cardColor: const Color(0xFFD1D9E6),               // 🟢 Identická farba karty
      primaryColor: const Color(0xFF6C5CE7),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6C5CE7),
        onPrimary: Colors.white,
        secondary: Color(0xFF00CEC9),
        onSecondary: Colors.white,
        tertiary: Color(0xFF0984E3),
        surface: Color(0xFFD1D9E6),
        onSurface: Color(0xFF2D3748),
        onSecondaryContainer: Color(0xFF718096),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2D3748)),
        titleTextStyle: TextStyle(color: Color(0xFF2D3748), fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
  );

  static final AppThemeData _neoBrutalismTheme = AppThemeData(
    id: 2,
    name: 'Neo Brutalism',
    isPremium: true,
    cardBorderRadius: BorderRadius.circular(16),
    buttonBorderRadius: BorderRadius.circular(12),
    cardBorder: Border.all(color: Colors.black, width: 3.5),
    cardShadows: const [
      BoxShadow(
        color: Colors.black,
        offset: Offset(4, 4),
        blurRadius: 0,
      ),
    ],
    dailyGoalColor: const Color(0xFFC084FC),
    decksColor: const Color(0xFFFF70A6),
    testSetupColor: const Color(0xFF00E5FF),
    blockedAppsColor: const Color(0xFFFF4757),
    quickImportColor: const Color(0xFFFFD166),
    successColor: const Color(0xFF06D6A0),
    warningColor: const Color(0xFFFFD166),
    errorColor: const Color(0xFFFF4757),
    primaryButtonBg: const Color(0xFF06D6A0),
    primaryButtonFg: Colors.black,
    buttonBorder: const BorderSide(color: Colors.black, width: 3.5),
    circleAvatarBg: Colors.white,
    circleAvatarBorder: Border.all(color: Colors.black, width: 3.5),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F5EE),
      cardColor: Colors.white,
      primaryColor: Colors.black,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Color(0xFFFF70A6),
        onSecondary: Colors.black,
        tertiary: Color(0xFFFFD166),
        surface: Colors.white,
        onSurface: Colors.black,
        onSecondaryContainer: Colors.black,
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

  static final AppThemeData _glassmorphismTheme = AppThemeData(
    id: 4,
    name: 'Starlight Glass',
    isPremium: true,
    isGlass: true,
    cardBorderRadius: BorderRadius.circular(24),
    buttonBorderRadius: BorderRadius.circular(16),
    dailyGoalColor: const Color(0xFF38BDF8),
    decksColor: const Color(0xFF34D399),
    testSetupColor: const Color(0xFFC084FC),
    blockedAppsColor: const Color(0xFFF43F5E),
    quickImportColor: const Color(0xFFFBBF24),
    successColor: const Color(0xFF34D399),
    warningColor: const Color(0xFFFBBF24),
    errorColor: const Color(0xFFF43F5E),
    primaryButtonBg: const Color(0xFF38BDF8),
    primaryButtonFg: Colors.white,
    buttonBorder: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
    circleAvatarBg: Colors.white.withValues(alpha: 0.12),
    circleAvatarBorder: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF050714),
      cardColor: const Color(0xFF0F172A),
      primaryColor: const Color(0xFF38BDF8),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF38BDF8),
        onPrimary: Colors.white,
        secondary: Color(0xFF34D399),
        onSecondary: Colors.black,
        tertiary: Color(0xFFC084FC),
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

  static final AppThemeData _vibrantGradientTheme = AppThemeData(
    id: 5,
    name: 'Vibrant Gradients',
    isPremium: true,
    cardBorderRadius: BorderRadius.circular(24),
    buttonBorderRadius: BorderRadius.circular(20),
    cardBorder: Border.all(
      color: Colors.white.withValues(alpha: 0.4),
      width: 1.5,
    ),
    cardShadows: [
      BoxShadow(
        color: const Color(0xFFFF9800).withValues(alpha: 0.35),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
    dailyGoalColor: const Color(0xFF00FF87),
    decksColor: const Color(0xFF00F2FE),
    testSetupColor: const Color(0xFFFF2A85),
    blockedAppsColor: const Color(0xFFFF3344),
    quickImportColor: const Color(0xFFFFB700),
    successColor: const Color(0xFF00FF87),
    warningColor: const Color(0xFFFFB700),
    errorColor: const Color(0xFFFF3344),
    primaryButtonBg: const Color(0xFFFF9800),
    primaryButtonFg: Colors.white,
    buttonBorder: BorderSide.none,
    circleAvatarBg: Colors.white,
    circleAvatarBorder: Border.all(color: Colors.white, width: 2.0),
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F5F9),
      cardColor: const Color(0xFFFFFFFF),
      primaryColor: const Color(0xFFFF9800),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF9800),
        onPrimary: Colors.white,
        secondary: Color(0xFF00F2FE),
        onSecondary: Colors.white,
        tertiary: Color(0xFFFF3344),
        surface: Color(0xFF0F172A),
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