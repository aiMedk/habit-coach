import 'package:habit_coach/features/habits/domain/entities/habit.dart';

/// T038: HabitRepository interface — domain layer, no Isar/Supabase imports.
abstract interface class HabitRepository {
  /// Returns all habits for the authenticated user.
  Future<List<Habit>> getHabits({bool activeOnly = false});

  /// Returns a single habit by [id], or null if not found.
  Future<Habit?> getHabitById(String id);

  /// Creates a new habit. Throws [ValidationFailure] if free-tier limit exceeded.
  Future<Habit> createHabit({
    required String name,
    String? description,
    required HabitFrequency frequency,
    List<int>? frequencyDays,
  });

  /// Updates mutable fields of an existing habit.
  Future<Habit> updateHabit(Habit habit);

  /// Soft-deactivates a habit (sets isActive = false).
  Future<void> deactivateHabit(String habitId);

  /// Reactivates a previously deactivated habit.
  /// Throws [ValidationFailure] if free-tier limit would be exceeded.
  Future<Habit> reactivateHabit(String habitId);
}
