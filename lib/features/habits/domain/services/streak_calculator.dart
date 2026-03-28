import 'package:habit_coach/core/utils/date_utils.dart';
import 'package:habit_coach/features/habits/domain/entities/completion.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/domain/entities/streak.dart';

/// T040: StreakCalculator — pure domain logic, no Flutter/storage imports.
///
/// Streak calculation rules (from data-model.md):
/// - Starting from today, walk backwards through calendar days.
/// - For each day: check if a non-undone Completion exists for the habit.
/// - If frequency = specific_days, skip non-scheduled days.
/// - Current streak = count of consecutive completed days from today backwards.
/// - Longest streak = max streak found across all completion history.
final class StreakCalculator {
  const StreakCalculator();

  /// Calculates the [Streak] for [habit] from the given [completions].
  ///
  /// [completions] must be all non-undone completions for the habit,
  /// sorted descending by [Completion.localDate] (most recent first).
  /// [today] defaults to the actual today date (overridable for testing).
  Streak calculate(
    Habit habit,
    List<Completion> completions, {
    DateTime? today,
  }) {
    final referenceDate = today ?? HabitDateUtils.today();

    // Build a set of completed date strings for O(1) lookup.
    final completedDates =
        completions.where((c) => !c.isUndone).map((c) => c.localDate).toSet();

    if (completedDates.isEmpty) {
      return Streak(habitId: habit.id, currentCount: 0, longestCount: 0);
    }

    final currentCount = _countCurrentStreak(
      habit,
      completedDates,
      referenceDate,
    );
    final longestCount = _countLongestStreak(
      habit,
      completedDates,
      referenceDate,
    );
    final lastDate = completedDates.reduce(
      (a, b) => a.compareTo(b) > 0 ? a : b,
    );

    return Streak(
      habitId: habit.id,
      currentCount: currentCount,
      longestCount: longestCount,
      lastCompletionDate: lastDate,
    );
  }

  /// Walks backwards from today counting consecutive scheduled + completed days.
  int _countCurrentStreak(
    Habit habit,
    Set<String> completedDates,
    DateTime referenceDate,
  ) {
    int count = 0;
    DateTime cursor = referenceDate;

    // Walk up to 1 year back (safety limit)
    for (int i = 0; i < 366; i++) {
      final dateStr = HabitDateUtils.toDateString(cursor);

      if (!habit.isScheduledOn(cursor.weekday)) {
        // Not scheduled — skip this day without breaking the streak
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      if (completedDates.contains(dateStr)) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        // Scheduled but not completed — streak is broken
        // Exception: allow today to be incomplete (habit might not yet be done)
        if (i == 0) {
          // Today is incomplete — check yesterday before giving up
          cursor = cursor.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    return count;
  }

  /// Finds the longest streak in the full completion history.
  int _countLongestStreak(
    Habit habit,
    Set<String> completedDates,
    DateTime referenceDate,
  ) {
    if (completedDates.isEmpty) return 0;

    // Find the oldest completed date to know how far back to scan
    final oldestDate = completedDates.reduce(
      (a, b) => a.compareTo(b) < 0 ? a : b,
    );
    final oldest = DateTime.parse(oldestDate);

    int longest = 0;
    int current = 0;
    DateTime cursor = referenceDate;

    while (!cursor.isBefore(oldest)) {
      final dateStr = HabitDateUtils.toDateString(cursor);

      if (!habit.isScheduledOn(cursor.weekday)) {
        // Non-scheduled day — doesn't break streak
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      if (completedDates.contains(dateStr)) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return longest;
  }
}
