/// T002: DailyStats — immutable value object for dashboard aggregates.
/// Pure Dart, no Flutter or Supabase imports (Constitution I).
final class DailyStats {
  const DailyStats({
    required this.completedCount,
    required this.totalCount,
    required this.bestStreak,
    required this.weekCompletedCount,
    required this.weekTotalCount,
  });

  /// Non-undone completions logged today.
  final int completedCount;

  /// Active habits scheduled for today.
  final int totalCount;

  /// Highest [Streak.currentCount] across all active habits.
  final int bestStreak;

  /// Unique habits with at least one completion this calendar week (Mon–today).
  final int weekCompletedCount;

  /// Total active habits (denominator for "This week: X/Y").
  final int weekTotalCount;

  /// Zero-value sentinel for loading / empty states.
  static const empty = DailyStats(
    completedCount: 0,
    totalCount: 0,
    bestStreak: 0,
    weekCompletedCount: 0,
    weekTotalCount: 0,
  );
}
