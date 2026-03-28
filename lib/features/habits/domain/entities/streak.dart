/// T037: Streak value object — pure Dart, derived (not stored).
/// Immutable snapshot computed by [StreakCalculator] from Completion records.
final class Streak {
  const Streak({
    required this.habitId,
    required this.currentCount,
    required this.longestCount,
    this.lastCompletionDate,
  });

  final String habitId;

  /// Consecutive completed days ending today (or yesterday, if today not yet due).
  final int currentCount;

  /// Maximum streak ever recorded across all completion history.
  final int longestCount;

  /// The most recent [localDate] string of a non-undone completion.
  final String? lastCompletionDate;

  bool get hasActiveStreak => currentCount > 0;

  /// Returns true if the streak has hit a milestone worthy of celebration.
  bool get isMilestone =>
      currentCount == 7 || currentCount == 30 || currentCount == 100;

  /// Returns the next milestone target, or null if above the highest tracked.
  int? get nextMilestone {
    for (final m in [7, 30, 100]) {
      if (currentCount < m) return m;
    }
    return null;
  }

  static const Streak empty = Streak(
    habitId: '',
    currentCount: 0,
    longestCount: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Streak &&
          other.habitId == habitId &&
          other.currentCount == currentCount &&
          other.longestCount == longestCount);

  @override
  int get hashCode => Object.hash(habitId, currentCount, longestCount);
}
