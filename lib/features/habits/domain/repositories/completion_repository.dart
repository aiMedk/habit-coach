import 'package:habit_coach/features/habits/domain/entities/completion.dart';

/// T039: CompletionRepository interface — domain layer, no Isar/Supabase imports.
abstract interface class CompletionRepository {
  /// Records a habit completion for today. Idempotent — returns existing
  /// completion if already completed today.
  /// Throws [ValidationFailure] if the habit is not active.
  Future<Completion> completeHabit({
    required String habitId,
    required String userId,
    required DateTime completedAt,
    required String localDate,
  });

  /// Undoes a completion. Only valid within 5 minutes of [Completion.createdAt].
  /// Throws [ValidationFailure] if the undo window has elapsed.
  Future<void> undoCompletion(String completionId);

  /// Returns all non-undone completions for [habitId], sorted by date descending.
  Future<List<Completion>> getCompletionsForHabit(String habitId);

  /// Returns all non-undone completions for [userId] on [localDate] (yyyy-MM-dd).
  Future<List<Completion>> getCompletionsForDate(
    String userId,
    String localDate,
  );

  /// Returns completions for [habitId] within the last [days] calendar days.
  Future<List<Completion>> getRecentCompletions(
    String habitId, {
    int days = 30,
  });

  /// Returns all non-undone completions for [userId] within the inclusive date
  /// range [startDate]–[endDate] (YYYY-MM-DD strings).
  Future<List<Completion>> getCompletionsForDateRange(
    String userId,
    String startDate,
    String endDate,
  );

  /// Returns all completions not yet synced to Supabase.
  Future<List<Completion>> getPendingSyncCompletions(String userId);
}
