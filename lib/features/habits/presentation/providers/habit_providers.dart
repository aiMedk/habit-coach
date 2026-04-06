import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_coach/core/network/connectivity_checker.dart';
import 'package:habit_coach/core/network/isar_provider.dart';
import 'package:habit_coach/core/utils/date_utils.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/habits/data/repositories/isar_completion_repository.dart';
import 'package:habit_coach/features/habits/data/repositories/isar_habit_repository.dart';
import 'package:habit_coach/features/habits/data/services/offline_completion_queue.dart';
import 'package:habit_coach/features/habits/data/services/supabase_sync_service.dart';
import 'package:habit_coach/features/habits/domain/entities/completion.dart';
import 'package:habit_coach/features/habits/domain/entities/daily_stats.dart';
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

/// T005: Aggregated dashboard stats derived from habit list, completions,
/// streaks, and a week-range completion query.
final dailyStatsProvider = FutureProvider<DailyStats>((ref) async {
  final habits = await ref.watch(habitListProvider.future);
  final todayCompletions = await ref.watch(todayCompletionsProvider.future);
  final streaks = await Future.wait(
    habits.map((h) => ref.watch(streakProvider(h.id).future)),
  );
  final completionRepo = await ref.watch(completionRepositoryProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return DailyStats.empty;

  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final weekStart = HabitDateUtils.toDateString(
    DateTime(monday.year, monday.month, monday.day),
  );
  final todayStr = HabitDateUtils.toDateString(now);
  final weekCompletions = await completionRepo.getCompletionsForDateRange(
    user.id,
    weekStart,
    todayStr,
  );

  return DailyStats(
    completedCount: todayCompletions.length,
    totalCount: habits.length,
    bestStreak: streaks.map((s) => s.currentCount).fold(0, max),
    weekCompletedCount: weekCompletions.map((c) => c.habitId).toSet().length,
    weekTotalCount: habits.length,
  );
});

/// T020/T021: Provides the [ConnectivityChecker] singleton.
final connectivityProvider = Provider<ConnectivityChecker>((ref) {
  return ConnectivityPlusChecker(Connectivity());
});

/// T020/T021: Provides the [SupabaseSyncService] for syncing completions.
final syncServiceProvider = FutureProvider<SupabaseSyncService>((ref) async {
  final completionRepo = await ref.watch(completionRepositoryProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    throw StateError('syncServiceProvider: no authenticated user');
  }
  return SupabaseSyncService(
    supabase: Supabase.instance.client,
    completionRepository: completionRepo,
    userId: user.id,
  );
});

/// T020/T021: Provides the [OfflineCompletionQueue] and starts it.
/// Lazily initializes on first access and automatically starts listening
/// for connectivity changes to sync pending completions.
final offlineQueueProvider = FutureProvider<OfflineCompletionQueue>((
  ref,
) async {
  final isar = await ref.watch(isarProvider.future);
  final syncService = await ref.watch(syncServiceProvider.future);
  final connectivity = ref.watch(connectivityProvider);

  final queue = OfflineCompletionQueue(
    isar: isar,
    syncService: syncService,
    connectivity: connectivity,
  );

  await queue.start();

  // Clean up on disposal
  ref.onDispose(() {
    queue.dispose();
  });

  return queue;
});

/// T021: Provides the sync-failure notification stream.
/// Emits `true` when a sync attempt fails; the UI watches this to show a banner.
final syncFailureProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final queue = await ref.watch(offlineQueueProvider.future);
  yield* queue.syncFailures;
});
