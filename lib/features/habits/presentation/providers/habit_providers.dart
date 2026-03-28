import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/core/network/isar_provider.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/habits/data/repositories/isar_completion_repository.dart';
import 'package:habit_coach/features/habits/data/repositories/isar_habit_repository.dart';
import 'package:habit_coach/features/habits/domain/entities/completion.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/domain/entities/streak.dart';
import 'package:habit_coach/features/habits/domain/repositories/completion_repository.dart';
import 'package:habit_coach/features/habits/domain/repositories/habit_repository.dart';
import 'package:habit_coach/features/habits/domain/services/streak_calculator.dart';

/// T048: Habit feature Riverpod providers.

/// Provides the [HabitRepository] backed by Isar for the current user.
/// Resolves async Isar + current user before constructing the repo.
final habitRepositoryProvider = FutureProvider<HabitRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    throw StateError('habitRepositoryProvider: no authenticated user');
  }
  return IsarHabitRepository(isar, userId: user.id);
});

/// Provides the [CompletionRepository] backed by Isar.
final completionRepositoryProvider = FutureProvider<CompletionRepository>((
  ref,
) async {
  final isar = await ref.watch(isarProvider.future);
  return IsarCompletionRepository(isar);
});

/// Returns the list of active habits for the current user.
/// Refreshed whenever the underlying repository changes.
final habitListProvider = FutureProvider<List<Habit>>((ref) async {
  final repo = await ref.watch(habitRepositoryProvider.future);
  return repo.getHabits(activeOnly: true);
});

/// Returns all completions (non-undone) for the given habit, sorted descending.
final habitCompletionsProvider =
    FutureProvider.family<List<Completion>, String>((ref, habitId) async {
      final repo = await ref.watch(completionRepositoryProvider.future);
      return repo.getCompletionsForHabit(habitId);
    });

/// Returns completions logged for today across all habits for the current user.
final todayCompletionsProvider = FutureProvider<List<Completion>>((ref) async {
  final repo = await ref.watch(completionRepositoryProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  final today = DateTime.now();
  final dateStr =
      '${today.year.toString().padLeft(4, '0')}'
      '-${today.month.toString().padLeft(2, '0')}'
      '-${today.day.toString().padLeft(2, '0')}';
  return repo.getCompletionsForDate(user.id, dateStr);
});

/// Returns a single habit by id, or null if not found.
final habitByIdProvider = FutureProvider.family<Habit?, String>((
  ref,
  habitId,
) async {
  final repo = await ref.watch(habitRepositoryProvider.future);
  return repo.getHabitById(habitId);
});

/// Returns the [Streak] for a given habit.
final streakProvider = FutureProvider.family<Streak, String>((
  ref,
  habitId,
) async {
  final habitRepo = await ref.watch(habitRepositoryProvider.future);
  final completionRepo = await ref.watch(completionRepositoryProvider.future);
  final habit = await habitRepo.getHabitById(habitId);
  if (habit == null) return Streak.empty;
  final completions = await completionRepo.getCompletionsForHabit(habitId);
  return const StreakCalculator().calculate(habit, completions);
});
