import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/stats_provider.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';
import '../themes/themed_background.dart';

class StatsDetailScreen extends StatefulWidget {
  const StatsDetailScreen({super.key});

  @override
  State<StatsDetailScreen> createState() => _StatsDetailScreenState();
}

class _StatsDetailScreenState extends State<StatsDetailScreen> {
  int _selectedFilterIndex = 0; // 0: Dnes, 1: Týždeň, 2: Všetok čas

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0 s';
    
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '$minutes min $seconds s';
    } else {
      return '$seconds s';
    }
  }

  String _getAccuracyMessage(int accuracy) {
    if (accuracy <= 20) {
      return 'Treba viac trénovať 😅';
    } else if (accuracy <= 40) {
      return 'Niekam sa už dostávame... 📈';
    } else if (accuracy <= 60) {
      return 'Dobrá práca, len tak ďalej ⚡';
    } else if (accuracy <= 80) {
      return 'Už ti to ide super! 🧠';
    } else if (accuracy < 100) {
      return 'Skvelá pamäť, ideš ako stroj! 🔥';
    } else {
      return 'Perfektný výkon! Absolútny master 👑';
    }
  }

  void _onSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    // Posun prsta doľava (velocity < 0) -> Posun na ďalší filter
    if (details.primaryVelocity! < -200) {
      setState(() {
        _selectedFilterIndex = (_selectedFilterIndex + 1) % 3;
      });
    } 
    // Posun prsta doprava (velocity > 0) -> Posun na predchádzajúci filter
    else if (details.primaryVelocity! > 200) {
      setState(() {
        _selectedFilterIndex = (_selectedFilterIndex - 1 + 3) % 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isSoft = currentTheme.id == 1;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: theme.appBarTheme.elevation ?? 0,
          title: Text(
            'Štatistiky učenia',
            style: theme.appBarTheme.titleTextStyle ?? TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        ),
        body: Consumer<StatsProvider>(
          builder: (context, statsProvider, child) {
            if (statsProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: currentTheme.decksColor),
              );
            }

            final stats = statsProvider.getStatsForPeriod(_selectedFilterIndex);
            final int cardsCount = stats['cards'] ?? 0;
            
            final int studySeconds = stats['durationSeconds'] ?? 0; 
            final int earnedSeconds = stats['earnedSeconds'] ?? 0;  
            final int accuracy = stats['accuracy'] ?? 0;
            final int streak = statsProvider.currentStreak;

            final String favoriteDeck = stats['favoriteDeck'] ?? 'Žiadny';
            final String nemesisPrompt = stats['nemesisPrompt'] ?? stats['nemesisCard'] ?? 'Žiadna';
            final String nemesisAnswer = stats['nemesisAnswer'] ?? '';

            final int savedProcrastinationSeconds = (studySeconds * 2.5).round();

            return GestureDetector(
              onHorizontalDragEnd: _onSwipe,
              behavior: HitTestBehavior.opaque,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: ListView(
                  key: ValueKey(_selectedFilterIndex),
                  padding: const EdgeInsets.all(20.0),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. PREPÍNAČ OBDOBIA (NEUMORPHIC TRACK)
                    _buildSegmentedFilter(currentTheme),
                    const SizedBox(height: 24),

                    // 2. STREAK KARTA
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: currentTheme.getCardDecoration(currentTheme.dailyGoalColor),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: isSoft
                                ? BoxDecoration(
                                    color: const Color(0xFFC8D3E6),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(color: Color(0xFF97A7C0), offset: Offset(2, 2), blurRadius: 4),
                                      BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                                    ],
                                  )
                                : null,
                            child: const Text('🔥', style: TextStyle(fontSize: 38)),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AKTÍVNY STREAK',
                                style: TextStyle(
                                  color: isVibrant 
                                      ? Colors.white.withValues(alpha: 0.8) 
                                      : (currentTheme.id == 2 ? Colors.black : currentTheme.dailyGoalColor),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$streak ${streak == 1 ? 'deň' : (streak >= 2 && streak <= 4 ? 'dni' : 'dní')}',
                                style: TextStyle(
                                  color: isVibrant ? Colors.white : (isSoft ? const Color(0xFF2D3748) : theme.colorScheme.onSurface),
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. GRID 1: ČAS UČENIA & ZAROBENÝ ČAS
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            title: 'Čas učenia',
                            value: _formatDuration(studySeconds),
                            icon: Icons.timer_rounded,
                            color: currentTheme.blockedAppsColor,
                            currentTheme: currentTheme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatTile(
                            title: 'Zarobený čas',
                            value: _formatDuration(earnedSeconds),
                            icon: Icons.lock_open_rounded,
                            color: Colors.amber.shade700,
                            currentTheme: currentTheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. GRID 2: PREBRATÉ KARTIČKY & UŠETRENÝ ČAS
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            title: 'Prebratých kartičiek',
                            value: '$cardsCount',
                            icon: Icons.style_rounded,
                            color: currentTheme.testSetupColor,
                            currentTheme: currentTheme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatTile(
                            title: 'Ušetrený čas',
                            value: _formatDuration(savedProcrastinationSeconds),
                            icon: Icons.hourglass_top_rounded,
                            color: Colors.teal,
                            currentTheme: currentTheme,
                            customGradient: isVibrant ? const LinearGradient(
                              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ) : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 5. PRIEMERNÁ ÚSPEŠNOSŤ
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: currentTheme.getCardDecoration(currentTheme.decksColor),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: isSoft ? const EdgeInsets.all(10) : EdgeInsets.zero,
                                decoration: isSoft
                                    ? BoxDecoration(
                                        color: const Color(0xFFC8D3E6),
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(color: Color(0xFF97A7C0), offset: Offset(2, 2), blurRadius: 4),
                                          BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                                        ],
                                      )
                                    : null,
                                child: Icon(
                                  Icons.insights_rounded, 
                                  color: isVibrant ? Colors.white : currentTheme.getIconColor(currentTheme.decksColor), 
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Priemerná úspešnosť',
                                    style: TextStyle(
                                      color: isVibrant ? Colors.white : (isSoft ? const Color(0xFF2D3748) : theme.colorScheme.onSurface),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getAccuracyMessage(accuracy),
                                    style: TextStyle(
                                      color: isVibrant 
                                          ? Colors.white.withValues(alpha: 0.75) 
                                          : (isSoft ? const Color(0xFF718096) : theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '$accuracy %',
                            style: TextStyle(
                              color: isVibrant ? Colors.white : (isSoft ? currentTheme.decksColor : theme.colorScheme.onSurface),
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. NAJOBĽÚBENEJŠÍ BALÍČEK
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: isVibrant
                          ? BoxDecoration(
                              borderRadius: currentTheme.cardBorderRadius,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            )
                          : currentTheme.getCardDecoration(Colors.indigo),
                      child: Row(
                        children: [
                          Container(
                            padding: isSoft ? const EdgeInsets.all(10) : EdgeInsets.zero,
                            decoration: isSoft
                                ? BoxDecoration(
                                    color: const Color(0xFFC8D3E6),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(color: Color(0xFF97A7C0), offset: Offset(2, 2), blurRadius: 4),
                                      BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                                    ],
                                  )
                                : null,
                            child: Icon(
                              Icons.star_rounded, 
                              color: isVibrant ? Colors.white : currentTheme.getIconColor(Colors.indigo), 
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Najobľúbenejší balíček',
                                  style: TextStyle(
                                    color: isVibrant 
                                        ? Colors.white.withValues(alpha: 0.8) 
                                        : (isSoft ? const Color(0xFF718096) : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  favoriteDeck,
                                  style: TextStyle(
                                    color: isVibrant ? Colors.white : (isSoft ? const Color(0xFF2D3748) : theme.colorScheme.onSurface),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (favoriteDeck != 'Žiadny')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: isSoft
                                  ? BoxDecoration(
                                      color: const Color(0xFFC8D3E6),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0xFF97A7C0), offset: Offset(2, 2), blurRadius: 4),
                                        BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                                      ],
                                    )
                                  : BoxDecoration(
                                      color: (isVibrant || currentTheme.id == 4)
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: (isVibrant || currentTheme.id == 4)
                                            ? Colors.white.withValues(alpha: 0.25)
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                                      ),
                                    ),
                              child: Text(
                                '$cardsCount kartičiek',
                                style: TextStyle(
                                  color: isVibrant || currentTheme.id == 4 
                                      ? Colors.white 
                                      : (isSoft ? const Color(0xFF2D3748) : theme.colorScheme.onSurface),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 7. NEMESIS KARTA (INTERAKTÍVNA FLASHCARD)
                    _NemesisInteractiveCard(
                      prompt: nemesisPrompt,
                      correctAnswer: nemesisAnswer,
                      currentTheme: currentTheme,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required AppThemeData currentTheme,
    Gradient? customGradient,
  }) {
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isSoft = currentTheme.id == 1;
    final bool useWhiteText = isVibrant || customGradient != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: customGradient != null 
          ? BoxDecoration(
              borderRadius: currentTheme.cardBorderRadius,
              gradient: customGradient,
            )
          : currentTheme.getCardDecoration(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: isSoft ? const EdgeInsets.all(8) : EdgeInsets.zero,
            decoration: isSoft
                ? BoxDecoration(
                    color: const Color(0xFFC8D3E6),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF97A7C0), offset: Offset(2, 2), blurRadius: 4),
                      BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                    ],
                  )
                : null,
            child: Icon(
              icon, 
              color: useWhiteText ? Colors.white : currentTheme.getIconColor(color), 
              size: isSoft ? 24 : 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: useWhiteText 
                  ? Colors.white.withValues(alpha: 0.8) 
                  : (isSoft ? const Color(0xFF718096) : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: useWhiteText 
                    ? Colors.white 
                    : (isSoft ? const Color(0xFF2D3748) : theme.colorScheme.onSurface),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedFilter(AppThemeData currentTheme) {
    final theme = currentTheme.theme;
    final bool isVibrant = currentTheme.id == 5;
    final bool isGlass = currentTheme.id == 4;
    final bool isNeo = currentTheme.id == 2;
    final bool isSoft = currentTheme.id == 1;

    BoxDecoration outerDecoration;
    if (isSoft) {
      // 🟢 SOFT NEUMORPHISM: Zapustená drážka (Inset concave track)
      outerDecoration = BoxDecoration(
        color: const Color(0xFFC8D3E6),
        borderRadius: currentTheme.buttonBorderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF97A7C0),
            offset: Offset(3, 3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-3, -3),
            blurRadius: 6,
          ),
        ],
      );
    } else if (isNeo) {
      outerDecoration = BoxDecoration(
        color: Colors.white,
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
      );
    } else if (isGlass) {
      outerDecoration = BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.45),
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (isVibrant) {
      outerDecoration = BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.70),
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      );
    } else {
      outerDecoration = BoxDecoration(
        color: theme.cardColor,
        borderRadius: currentTheme.buttonBorderRadius,
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.15), width: 1.2),
        boxShadow: currentTheme.cardShadows,
      );
    }

    final filters = ['Dnes', 'Týždeň', 'Všetko'];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: outerDecoration,
      child: Row(
        children: List.generate(filters.length, (index) {
          final bool isSelected = _selectedFilterIndex == index;
          final Color accentColor = currentTheme.quickImportColor;

          BoxDecoration? selectedDeco;
          if (isSelected) {
            if (isSoft) {
              // 🟢 SOFT NEUMORPHISM: Vystúpený samostatný gombík (Raised soft Convex)
              selectedDeco = BoxDecoration(
                color: const Color(0xFFD1D9E6),
                borderRadius: BorderRadius.circular(
                  (currentTheme.buttonBorderRadius.topLeft.x - 2).clamp(4.0, 20.0),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF97A7C0),
                    offset: Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
              );
            } else if (isNeo) {
              selectedDeco = BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(
                  (currentTheme.buttonBorderRadius.topLeft.x - 2).clamp(4.0, 20.0),
                ),
                border: Border.all(color: Colors.black, width: 2.5),
              );
            } else if (isGlass) {
              selectedDeco = BoxDecoration(
                color: Color.alphaBlend(
                  accentColor.withValues(alpha: 0.25),
                  const Color(0xFF0F172A).withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(
                  (currentTheme.buttonBorderRadius.topLeft.x - 2).clamp(4.0, 20.0),
                ),
                border: Border.all(
                  color: Color.alphaBlend(accentColor.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.4)),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              );
            } else if (isVibrant) {
              selectedDeco = BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                  (currentTheme.buttonBorderRadius.topLeft.x - 2).clamp(4.0, 20.0),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.2),
              );
            } else {
              selectedDeco = currentTheme.getCardDecoration(accentColor, isSelected: true);
            }
          }

          final Color textColor = isSelected
              ? (isSoft 
                  ? currentTheme.decksColor 
                  : (isNeo 
                      ? Colors.black 
                      : (isVibrant || isGlass ? Colors.white : currentTheme.getContrastTextColor(accentColor))))
              : (isSoft 
                  ? const Color(0xFF718096) 
                  : (isVibrant || isGlass ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.65)));

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: selectedDeco ?? const BoxDecoration(color: Colors.transparent),
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// --- PRIVÁTNY INTERAKTÍVNY WIDGET PRE NEMESIS KARTU ---
class _NemesisInteractiveCard extends StatefulWidget {
  final String prompt;
  final String correctAnswer;
  final AppThemeData currentTheme;

  const _NemesisInteractiveCard({
    required this.prompt,
    required this.correctAnswer,
    required this.currentTheme,
  });

  @override
  State<_NemesisInteractiveCard> createState() => _NemesisInteractiveCardState();
}

class _NemesisInteractiveCardState extends State<_NemesisInteractiveCard> {
  bool _isFlipped = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.currentTheme.theme;
    final bool hasNemesis = widget.prompt != 'Žiadna' && widget.prompt.isNotEmpty;
    final bool isVibrant = widget.currentTheme.id == 5;
    final bool isSoft = widget.currentTheme.id == 1;

    if (!hasNemesis) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: isVibrant
            ? BoxDecoration(
                borderRadius: widget.currentTheme.cardBorderRadius,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E0E00), Color(0xFF1F1C18)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : widget.currentTheme.getCardDecoration(Colors.deepOrange),
        child: Row(
          children: [
            Container(
              padding: isSoft ? const EdgeInsets.all(8) : EdgeInsets.zero,
              decoration: isSoft
                  ? BoxDecoration(
                      color: const Color(0xFFC8D3E6),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF97A7C0), offset: Offset(2, 2), blurRadius: 4),
                        BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                      ],
                    )
                  : null,
              child: Icon(
                Icons.sentiment_satisfied_alt_rounded, 
                color: isVibrant ? Colors.white : widget.currentTheme.getIconColor(Colors.deepOrange), 
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nemesis karta',
                    style: TextStyle(
                      color: isVibrant 
                          ? Colors.white.withValues(alpha: 0.8) 
                          : (isSoft ? const Color(0xFF718096) : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Zatiaľ nemáš žiadnu úhlavnú nepriateľskú kartu 🎉',
                    style: TextStyle(
                      color: isVibrant ? Colors.white : (isSoft ? const Color(0xFF2D3748) : theme.colorScheme.onSurface),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final String textToDisplay = _isFlipped 
        ? (widget.correctAnswer.trim().isNotEmpty ? widget.correctAnswer : widget.prompt)
        : widget.prompt;

    final bool isSvg = textToDisplay.trim().toLowerCase().endsWith('.svg');

    Color textColor;
    if (_isFlipped) {
      textColor = widget.currentTheme.id == 2 ? Colors.green.shade800 : (isVibrant ? Colors.lightGreenAccent : Colors.green.shade600);
    } else {
      textColor = isVibrant ? Colors.white : (isSoft ? const Color(0xFF2D3748) : theme.colorScheme.onSurface);
    }

    return GestureDetector(
      onTap: () => setState(() => _isFlipped = !_isFlipped),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Container(
          key: ValueKey(_isFlipped),
          padding: const EdgeInsets.all(18),
          decoration: isVibrant
              ? BoxDecoration(
                  borderRadius: widget.currentTheme.cardBorderRadius,
                  gradient: LinearGradient(
                    colors: _isFlipped 
                        ? [const Color(0xFF07241A), const Color(0xFF0F4734)]
                        : [const Color(0xFF8E0E00), const Color(0xFF1F1C18)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                )
              : widget.currentTheme.getCardDecoration(
                  _isFlipped ? Colors.green.shade700 : Colors.deepOrange,
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: isSoft ? const EdgeInsets.all(6) : EdgeInsets.zero,
                        decoration: isSoft
                            ? BoxDecoration(
                                color: const Color(0xFFC8D3E6),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(color: Color(0xFF97A7C0), offset: Offset(2, 2), blurRadius: 4),
                                  BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                                ],
                              )
                            : null,
                        child: Icon(
                          _isFlipped ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, 
                          color: isVibrant 
                              ? Colors.white 
                              : widget.currentTheme.getIconColor(
                                  _isFlipped ? Colors.green.shade700 : Colors.deepOrange,
                                ), 
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isFlipped ? 'ODPOVEĎ' : 'NEMESIS KARTA (NAJVIAC CHÝB)',
                        style: TextStyle(
                          color: isVibrant 
                              ? Colors.white.withValues(alpha: 0.9) 
                              : (isSoft ? const Color(0xFF718096) : theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.flip_rounded,
                    size: 18,
                    color: isVibrant ? Colors.white.withValues(alpha: 0.7) : (isSoft ? const Color(0xFF718096) : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isSvg)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SvgPicture.asset(
                        textToDisplay.trim(),
                        height: 85,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Text(
                    textToDisplay,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _isFlipped ? 'Ťukni pre návrat na otázku' : 'Ťukni pre otočenie a zobrazenie odpovede',
                  style: TextStyle(
                    color: isVibrant ? Colors.white.withValues(alpha: 0.7) : (isSoft ? const Color(0xFF718096) : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}