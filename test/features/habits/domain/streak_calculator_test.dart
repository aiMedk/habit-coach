import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/habits/domain/entities/completion.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/domain/services/streak_calculator.dart';

/// T158: StreakCalculator domain unit tests.
void main() {
  const calculator = StreakCalculator();

  // Reference date: Wednesday 2026-03-25 (weekday = 3)
  final today = DateTime(2026, 3, 25);

  Habit _dailyHabit() => Habit(
    id: 'h1',
    userId: 'u1',
    name: 'Test',
    frequency: HabitFrequency.daily,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  // Mon=0, Tue=1, Wed=2, Thu=3, Fri=4
  Habit _weekdayHabit() => Habit(
    id: 'h2',
    userId: 'u1',
    name: 'Weekdays',
    frequency: HabitFrequency.specificDays,
    frequencyDays: [0, 1, 2, 3, 4],
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Completion _completion(String dateStr) => Completion(
    id: dateStr,
    habitId: 'h1',
    userId: 'u1',
    completedAt: DateTime.parse(dateStr),
    localDate: dateStr,
    isUndone: false,
    createdAt: DateTime.parse(dateStr),
  );

  group('StreakCalculator — daily habit', () {
    test('returns zero streak when no completions', () {
      final result = calculator.calculate(_dailyHabit(), [], today: today);
      expect(result.currentCount, 0);
      expect(result.longestCount, 0);
    });

    test('counts 3-day current streak including today', () {
      final completions = [
        _completion('2026-03-25'),
        _completion('2026-03-24'),
        _completion('2026-03-23'),
      ];
      final result = calculator.calculate(
        _dailyHabit(),
        completions,
        today: today,
      );
      expect(result.currentCount, 3);
      expect(result.longestCount, 3);
    });

    test(
      'streak is not broken if today is incomplete — counts yesterday back',
      () {
        // Today (25th) not completed; yesterday (24th) and day before (23rd) are.
        final completions = [
          _completion('2026-03-24'),
          _completion('2026-03-23'),
        ];
        final result = calculator.calculate(
          _dailyHabit(),
          completions,
          today: today,
        );
        expect(result.currentCount, 2);
      },
    );

    test('streak breaks when a day in the past is missed', () {
      // Gap on the 23rd
      final completions = [
        _completion('2026-03-25'),
        _completion('2026-03-24'),
        // missing 2026-03-23
        _completion('2026-03-22'),
      ];
      final result = calculator.calculate(
        _dailyHabit(),
        completions,
        today: today,
      );
      expect(result.currentCount, 2);
      expect(result.longestCount, 2);
    });

    test('longest streak spans non-adjacent window', () {
      // One 5-day streak in January; one 2-day streak recently
      final completions = [
        _completion('2026-03-25'),
        _completion('2026-03-24'),
        _completion('2026-01-05'),
        _completion('2026-01-04'),
        _completion('2026-01-03'),
        _completion('2026-01-02'),
        _completion('2026-01-01'),
      ];
      final result = calculator.calculate(
        _dailyHabit(),
        completions,
        today: today,
      );
      expect(result.longestCount, 5);
      expect(result.currentCount, 2);
    });

    test('undone completions are excluded', () {
      final completions = [
        Completion(
          id: 'c1',
          habitId: 'h1',
          userId: 'u1',
          completedAt: today,
          localDate: '2026-03-25',
          isUndone: true,
          createdAt: today,
        ),
      ];
      final result = calculator.calculate(
        _dailyHabit(),
        completions,
        today: today,
      );
      expect(result.currentCount, 0);
    });

    test('lastCompletionDate reflects most recent date', () {
      final completions = [
        _completion('2026-03-25'),
        _completion('2026-03-24'),
      ];
      final result = calculator.calculate(
        _dailyHabit(),
        completions,
        today: today,
      );
      expect(result.lastCompletionDate, '2026-03-25');
    });
  });

  group('StreakCalculator — specific-days habit (Mon–Fri)', () {
    test('skips weekend days without breaking streak', () {
      // 2026-03-25 is Wed; streak Mon 23 → Tue 24 → Wed 25
      final completions = [
        _completion('2026-03-25'),
        _completion('2026-03-24'),
        _completion('2026-03-23'),
        // Weekend (21=Sat, 22=Sun) skipped
        _completion('2026-03-20'),
      ];
      final result = calculator.calculate(
        _weekdayHabit(),
        completions,
        today: today,
      );
      expect(result.currentCount, 4);
    });

    test('streak breaks if a scheduled weekday is missed', () {
      // Missing Monday 23rd
      final completions = [
        _completion('2026-03-25'),
        _completion('2026-03-24'),
        // missing 2026-03-23 (Monday)
        _completion('2026-03-20'),
      ];
      final result = calculator.calculate(
        _weekdayHabit(),
        completions,
        today: today,
      );
      expect(result.currentCount, 2);
    });
  });

  group('StreakCalculator — Streak entity', () {
    test('isMilestone true at 7', () {
      final completions = List.generate(
        7,
        (i) => _completion('2026-03-${19 + i}'),
      );
      final result = calculator.calculate(
        _dailyHabit(),
        completions,
        today: today,
      );
      expect(result.isMilestone, true);
    });

    test('nextMilestone is 7 when current is 3', () {
      final completions = [
        _completion('2026-03-25'),
        _completion('2026-03-24'),
        _completion('2026-03-23'),
      ];
      final result = calculator.calculate(
        _dailyHabit(),
        completions,
        today: today,
      );
      expect(result.nextMilestone, 7);
    });
  });
}
