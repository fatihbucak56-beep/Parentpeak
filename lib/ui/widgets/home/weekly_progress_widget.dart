import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wochenfortschritt — Mini-Dashboard mit Aktivitäts-Übersicht.
///
/// Zeigt: Tage aktiv diese Woche, Impulse gelesen, Stimmungs-Streak.
/// Kompakt, motivierend, keine Überforderung.
class WeeklyProgressWidget extends StatefulWidget {
  const WeeklyProgressWidget({super.key});

  @override
  State<WeeklyProgressWidget> createState() => _WeeklyProgressWidgetState();
}

class _WeeklyProgressWidgetState extends State<WeeklyProgressWidget> {
  int _activeDays = 0;
  int _moodStreak = 0;
  final int _totalDaysThisWeek = 7;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Zähle Tage mit Mood-Check diese Woche
    int activeDays = 0;
    int streak = 0;
    bool streakBroken = false;

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key =
          'mood.daily.${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
      final mood = prefs.getString(key);
      if (mood != null) {
        activeDays++;
        if (!streakBroken) streak++;
      } else {
        if (i > 0) streakBroken = true;
      }
    }

    if (mounted) {
      setState(() {
        _activeDays = activeDays;
        _moodStreak = streak;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _activeDays / _totalDaysThisWeek;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                ),
                Text(
                  '$_activeDays',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_activeDays von 7 Tagen aktiv',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _moodStreak > 1
                      ? '$_moodStreak Tage Streak \u{1F525}'
                      : 'Bleib dran — jeder Tag zählt',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Motivations-Icon
          if (_activeDays >= 5)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  size: 18, color: Color(0xFF16A34A)),
            ),
        ],
      ),
    );
  }
}
