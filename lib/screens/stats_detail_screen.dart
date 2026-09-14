import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stats_provider.dart';
import '../themes/theme_provider.dart';
import '../themes/app_themes.dart';

class StatsDetailScreen extends StatefulWidget {
  const StatsDetailScreen({super.key});

  @override
  State<StatsDetailScreen> createState() => _StatsDetailScreenState();
}

class _StatsDetailScreenState extends State<StatsDetailScreen> {
  int _selectedFilterIndex = 0; // 0: Dnes, 1: Týždeň, 2: Všetok čas

  // Pomocná funkcia pre prehľadný formát času
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final theme = currentTheme.theme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
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
          
          // Čas v sekundách načítaný z DB
          final int studySeconds = stats['durationSeconds'] ?? 0; // 👈 Reálny čas učenia
          final int earnedSeconds = stats['earnedSeconds'] ?? 0;  // 👈 Zarobený čas
          final int accuracy = stats['accuracy'] ?? 0;
          final int streak = statsProvider.currentStreak;

          final String favoriteDeck = stats['favoriteDeck'] ?? 'Žiadny';
          final String nemesisPrompt = stats['nemesisPrompt'] ?? stats['nemesisCard'] ?? 'Žiadna';
          final String nemesisAnswer = stats['nemesisAnswer'] ?? '';

          // Odhad ušetreného času na sociálnych sieťach / prokrastinácii
          final int savedProcrastinationSeconds = (studySeconds * 2.5).round();

          return ListView(
            padding: const EdgeInsets.all(20.0),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. PREPÍNAČ OBDOBIA
              Row(
                children: [
                  Expanded(child: _buildFilterButton('Dnes', 0, currentTheme)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterButton('Týždeň', 1, currentTheme)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterButton('Všetko', 2, currentTheme)),
                ],
              ),
              const SizedBox(height: 24),

              // 2. STREAK KARTA (HLAVNÝ BANNER)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: currentTheme.getCardDecoration(currentTheme.dailyGoalColor),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 48)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AKTÍVNY STREAK',
                          style: TextStyle(
                            color: currentTheme.id == 2 || currentTheme.id == 5 
                                ? Colors.black 
                                : currentTheme.dailyGoalColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$streak ${streak == 1 ? 'deň' : (streak >= 2 && streak <= 4 ? 'dni' : 'dní')}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
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
                      value:  _formatDuration(studySeconds),
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
                        Icon(
                          Icons.insights_rounded, 
                          color: currentTheme.getIconColor(currentTheme.decksColor), 
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priemerná úspešnosť',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              accuracy >= 80 ? 'Skvelá pamäť!' : 'Pokračuj v tréningu',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '$accuracy %',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
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
                decoration: currentTheme.getCardDecoration(Colors.indigo),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded, 
                      color: currentTheme.getIconColor(Colors.indigo), 
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Najobľúbenejší balíček',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            favoriteDeck,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
          );
        },
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required AppThemeData currentTheme,
  }) {
    final theme = currentTheme.theme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: currentTheme.getCardDecoration(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            color: currentTheme.getIconColor(color), 
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                color: theme.colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title, int index, AppThemeData currentTheme) {
    final bool isSelected = _selectedFilterIndex == index;
    final theme = currentTheme.theme;

    Color bgColor;
    Color fgColor;

    if (isSelected) {
      bgColor = currentTheme.id == 2 || currentTheme.id == 5 
          ? Colors.white 
          : theme.colorScheme.onSurface;
      fgColor = currentTheme.id == 2 || currentTheme.id == 5 
          ? Colors.black 
          : theme.scaffoldBackgroundColor;
    } else {
      bgColor = theme.cardColor;
      fgColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      borderRadius: currentTheme.buttonBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: currentTheme.buttonBorderRadius,
          border: Border.all(
            color: currentTheme.id == 2 ? Colors.black : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: currentTheme.id == 2 ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: fgColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
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

    if (!hasNemesis) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: widget.currentTheme.getCardDecoration(Colors.deepOrange),
        child: Row(
          children: [
            Icon(
              Icons.sentiment_satisfied_alt_rounded, 
              color: widget.currentTheme.getIconColor(Colors.deepOrange), 
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nemesis karta',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Zatiaľ nemáš žiadnu úhlavnú nepriateĽskú kartu 🎉',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
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

    // Určenie textu, ktorý sa má zobraziť (ak chýba odpoveď, zobrazí prompt)
    final String textToDisplay = _isFlipped 
        ? (widget.correctAnswer.trim().isNotEmpty ? widget.correctAnswer : widget.prompt)
        : widget.prompt;

    // Bezpečná farba textu s vysokým kontrastom
    Color textColor;
    if (_isFlipped) {
      textColor = widget.currentTheme.id == 2 ? Colors.green.shade800 : Colors.green.shade600;
    } else {
      textColor = theme.colorScheme.onSurface;
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
          decoration: widget.currentTheme.getCardDecoration(
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
                      Icon(
                        _isFlipped ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, 
                        color: widget.currentTheme.getIconColor(
                          _isFlipped ? Colors.green.shade700 : Colors.deepOrange,
                        ), 
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isFlipped ? 'ODPOVEĎ' : 'NEMESIS KARTA (NAJVIAC CHÝB)',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                textToDisplay,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                _isFlipped ? 'Ťukni pre návrat na otázku' : 'Ťukni pre otočenie a zobrazenie odpovede',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}