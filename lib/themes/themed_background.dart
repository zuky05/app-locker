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
        if (themeId == 5) ...[
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
          // CYBERPUNK: Hlboký synthwave gradient pozadia
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF05050A), // Hore temná čierna
                    Color(0xFF09140B), // Stred jemne tónovaný do tmavej zelenej
                    Color(0xFF0B1F12), // Dole hlboký cyberpunkový nádych
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
        ] else if (themeId == 0) ...[
          // 🟢 CYBERPUNK: Perspektívna 3D mriežka v žiarivej neónovo zelenej farbe
          Positioned.fill(
            child: CustomPaint(
              painter: CyberpunkPerspectiveGridPainter(
                gridColor: const Color(0xFF00FF66), // Neónovo zelená
              ),
            ),
          ),
        ] else if (themeId == 4) ...[
          // 🟢 STARLIGHT GLASS: Jemná neónovo cyan mriežka (oddelená od neumorfizmu, žiadna žltá farba)
          Positioned.fill(
            child: CustomPaint(
              painter: CyberGridPainter(
                gridColor: const Color(0xFF00E5FF).withValues(alpha: 0.18),
              ),
            ),
          ),
        ] else if (themeId == 1) ...[
          Positioned.fill(
            child: CustomPaint(
              painter: CyberGridPainter(
                gridColor: currentTheme.quickImportColor.withValues(alpha: 0.22),
              ),
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

// 🟢 CYBERPUNK PERSPECTIVE GRID PAINTER (Neónovo zelená 3D mriežka)
class CyberpunkPerspectiveGridPainter extends CustomPainter {
  final Color gridColor;

  CyberpunkPerspectiveGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.25)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final double horizonY = size.height * 0.55; 
    final double bottomWidth = size.width * 2.2;
    final double startX = size.width / 2;

    // 1. Zvislé čiary sbiehajúce sa do stredu (perspektíva)
    const int verticalLines = 14;
    for (int i = -verticalLines; i <= verticalLines; i++) {
      double bottomX = startX + (i * (bottomWidth / verticalLines));
      
      // Svietivý glow podklad
      canvas.drawLine(
        Offset(startX, horizonY),
        Offset(bottomX, size.height + 50),
        glowPaint,
      );
      // Ostrá neónová čiara
      canvas.drawLine(
        Offset(startX, horizonY),
        Offset(bottomX, size.height + 50),
        paint,
      );
    }

    // 2. Horizontálne čiary s exponenciálnym rozostupom
    const int horizontalLines = 12;
    for (int i = 0; i < horizontalLines; i++) {
      double progress = i / horizontalLines;
      double y = horizonY + (size.height - horizonY) * (progress * progress);

      final linePaint = Paint()
        ..color = gridColor.withValues(alpha: 0.15 + (progress * 0.65))
        ..strokeWidth = 1.2 + (progress * 0.9)
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

class NeobrutalismGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    const double step = 20.0;
    const double radius = 2.4;

    for (double x = 10; x < size.width; x += step) {
      for (double y = 10; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CyberGridPainter extends CustomPainter {
  final Color gridColor;

  CyberGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.4;

    const double step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
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