import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/theme_provider.dart';

class ThemedBackground extends StatelessWidget {
  final Widget child;

  const ThemedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final int themeId = currentTheme.id;

    return Stack(
      children: [
        // 1. ZÁKLADNÁ FARBA ALEBO GRADIENT POZADIA
        if (themeId == 2) ...[
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF7EED2),
            ),
          ),
        ] else if (themeId == 1) ...[
          Positioned.fill(
            child: Container(
              color: const Color(0xFFD1D9E6),
            ),
          ),
        ] else if (themeId == 3) ...[
          // 🟢 CLEAN MINIMAL: Prémiový jemný prechod (Soft Linen / Slate Gray)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF8FAFC),
                    Color(0xFFEEF2F6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ] else if (themeId == 5) ...[
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFEBF0),
                    Color(0xFFFFF2E6),
                    Color(0xFFEBF3FF),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ] else if (themeId == 0) ...[
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF020305),
                    Color(0xFF050810),
                    Color(0xFF080D1A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ] else if (themeId == 4) ...[
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF050714),
                    Color(0xFF0C1024),
                    Color(0xFF140D28),
                    Color(0xFF070918),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ] else ...[
          Positioned.fill(
            child: Container(
              color: currentTheme.theme.scaffoldBackgroundColor,
            ),
          ),
        ],

        // 2. PAINTERE
        if (themeId == 2) ...[
          Positioned.fill(
            child: CustomPaint(
              painter: NeobrutalismGridPainter(),
            ),
          ),
        ] else if (themeId == 1) ...[
          Positioned.fill(
            child: CustomPaint(
              painter: SoftNeumorphismAmbientPainter(),
            ),
          ),
        ] else if (themeId == 3) ...[
          // 🟢 Ambientné svetlo v pozadí pre Clean Minimal (dodáva hĺbku a high-end look)
          Positioned.fill(
            child: CustomPaint(
              painter: CleanMinimalGlowPainter(),
            ),
          ),
        ] else if (themeId == 0) ...[
          Positioned.fill(
            child: CustomPaint(
              painter: CyberpunkPerspectiveGridPainter(
                gridColor: const Color(0xFF00FF66),
              ),
            ),
          ),
        ] else if (themeId == 4) ...[
          Positioned.fill(
            child: CustomPaint(
              painter: StarlightCosmicPainter(),
            ),
          ),
        ] else if (themeId == 5) ...[
          Positioned.fill(
            child: CustomPaint(
              painter: VibrantFluidWavesPainter(),
            ),
          ),
        ] else ...[
          Positioned.fill(
            child: CustomPaint(
              painter: SoftNotebookGridPainter(
                lineColor: Colors.black.withValues(alpha: 0.28),
              ),
            ),
          ),
        ],

        // 3. OBSAH OBRAZOVKY
        Positioned.fill(child: child),
      ],
    );
  }
}

class CleanMinimalGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow1 = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    final glow2 = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 130);

    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 180, glow1);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 220, glow2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SoftNeumorphismAmbientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.15), 140, glowPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.75), 180, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NeobrutalismGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    const double step = 20.0;
    const double radius = 2.2;

    for (double x = 10; x < size.width; x += step) {
      for (double y = 10; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarlightCosmicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()..style = PaintingStyle.fill;

    final random = Random(1337);

    for (int i = 0; i < 65; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = 0.8 + random.nextDouble() * 1.6;
      double opacity = 0.25 + random.nextDouble() * 0.65;

      glowPaint.color = (i % 4 == 0 
          ? const Color(0xFF38BDF8) 
          : (i % 6 == 0 ? const Color(0xFFC084FC) : Colors.white)).withValues(alpha: opacity * 0.35);
      canvas.drawCircle(Offset(x, y), radius * 2.5, glowPaint);

      starPaint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, starPaint);

      if (radius > 1.9) {
        final flarePaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.6)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

        canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), flarePaint);
        canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), flarePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CyberpunkPerspectiveGridPainter extends CustomPainter {
  final Color gridColor;

  CyberpunkPerspectiveGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double horizonY = size.height * 0.52;

    // 1. CRT SCANLINES
    final Paint scanlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 4.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    // 2. HORIZONTÁLNA NEÓNOVÁ ŽIARA
    final Rect horizonRect = Rect.fromLTRB(0, horizonY - 80, size.width, horizonY + 50);
    final Paint horizonGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF0055).withValues(alpha: 0.0),
          const Color(0xFFFF0055).withValues(alpha: 0.30),
          const Color(0xFF00F5FF).withValues(alpha: 0.40),
          const Color(0xFF00F5FF).withValues(alpha: 0.0),
        ],
      ).createShader(horizonRect);

    canvas.drawRect(horizonRect, horizonGlow);

    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.30)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;

    final double bottomWidth = size.width * 2.4;
    final double startX = size.width / 2;

    // 3. PERSPEKTÍVNE ČIARY
    const int verticalLines = 16;
    for (int i = -verticalLines; i <= verticalLines; i++) {
      double bottomX = startX + (i * (bottomWidth / verticalLines));

      canvas.drawLine(
        Offset(startX, horizonY),
        Offset(bottomX, size.height + 50),
        glowPaint,
      );
      canvas.drawLine(
        Offset(startX, horizonY),
        Offset(bottomX, size.height + 50),
        paint,
      );
    }

    // 4. VODOROVNÉ ČIARY
    const int horizontalLines = 14;
    for (int i = 0; i < horizontalLines; i++) {
      double progress = i / horizontalLines;
      double y = horizonY + (size.height - horizonY) * (progress * progress);

      final linePaint = Paint()
        ..color = gridColor.withValues(alpha: 0.15 + (progress * 0.70))
        ..strokeWidth = 1.2 + (progress * 1.2)
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SoftNotebookGridPainter extends CustomPainter {
  final Color lineColor;

  SoftNotebookGridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.4;

    const double step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VibrantFluidWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final path1 = Path()
      ..moveTo(0, size.height * 0.50)
      ..cubicTo(
        size.width * 0.35, size.height * 0.35, 
        size.width * 0.65, size.height * 0.65, 
        size.width, size.height * 0.45
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          const Color(0xFF00C6FF).withValues(alpha: 0.55),
          const Color(0xFF0072FF).withValues(alpha: 0.48),
          const Color(0xFF9D4EDD).withValues(alpha: 0.42),
        ],
      ).createShader(rect);

    canvas.drawPath(path1, paint1);

    final path2 = Path()
      ..moveTo(0, size.height * 0.10)
      ..cubicTo(
        size.width * 0.38, size.height * 0.32, 
        size.width * 0.72, size.height * 0.08, 
        size.width, size.height * 0.22
      )
      ..lineTo(size.width, size.height * 0.85)
      ..cubicTo(
        size.width * 0.60, size.height * 0.65, 
        size.width * 0.28, size.height * 0.88, 
        0, size.height * 0.70
      )
      ..close();

    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFF007F).withValues(alpha: 0.45),
          const Color(0xFFFF1744).withValues(alpha: 0.45),
          const Color(0xFFFF9100).withValues(alpha: 0.40),
        ],
      ).createShader(rect);

    canvas.drawPath(path2, paint2);

    final path3 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.30)
      ..cubicTo(
        size.width * 0.55, size.height * 0.40, 
        size.width * 0.18, size.height * 0.02, 
        0, size.height * 0.20
      )
      ..close();

    final paint3 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.55),
          const Color(0xFFFF6D00).withValues(alpha: 0.45),
          const Color(0xFFFF2A70).withValues(alpha: 0.35),
        ],
      ).createShader(rect);

    canvas.drawPath(path3, paint3);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.75),
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.65),
        ],
      ).createShader(rect);

    final strokePath1 = Path()
      ..moveTo(0, size.height * 0.28)
      ..cubicTo(
        size.width * 0.35, size.height * 0.16, 
        size.width * 0.65, size.height * 0.42, 
        size.width, size.height * 0.26
      );

    final strokePath2 = Path()
      ..moveTo(0, size.height * 0.70)
      ..cubicTo(
        size.width * 0.40, size.height * 0.88, 
        size.width * 0.70, size.height * 0.60, 
        size.width, size.height * 0.82
      );

    canvas.drawPath(strokePath1, strokePaint);
    canvas.drawPath(strokePath2, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}