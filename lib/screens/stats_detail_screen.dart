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
          final int timeMinutes = stats['timeMinutes'] ?? 0;
          final int accuracy = stats['accuracy'] ?? 0;
          final int streak = statsProvider.currentStreak;

          return ListView(
            padding: const EdgeInsets.all(20.0),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. PREPÍNAČ OBDOBIA (Segmented Filter)
              Row(
                children: [
                  Expanded(
                    child: _buildFilterButton('Dnes', 0, currentTheme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterButton('Týždeň', 1, currentTheme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterButton('Všetko', 2, currentTheme),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. STREAK KARTA
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

              // 3. ŠTATISTICKÉ KARTY (GRID)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: currentTheme.getCardDecoration(currentTheme.testSetupColor),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.style_rounded, 
                            color: currentTheme.getIconColor(currentTheme.testSetupColor), 
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Kartičky',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$cardsCount',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: currentTheme.getCardDecoration(currentTheme.blockedAppsColor),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.timer_rounded, 
                            color: currentTheme.getIconColor(currentTheme.blockedAppsColor), 
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Čas učenia',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$timeMinutes min',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. ÚSPEŠNOSŤ (ACCURACY)
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
                        Text(
                          'Priemerná úspešnosť',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$accuracy %',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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