import 'package:isar/isar.dart';
import 'package:habit_coach/core/error/failures.dart';
import 'package:habit_coach/core/utils/date_utils.dart';
import 'package:habit_coach/features/habits/data/models/isar_models.dart';
import 'package:habit_coach/features/habits/domain/entities/completion.dart';
import 'package:habit_coach/features/habits/domain/repositories/completion_repository.dart';

/// T042: IsarCompletionRepository — offline-first completion storage.
///
/// Idempotency: at most one non-undone completion per (habitId, localDate).
/// Undo window: enforced at 5 minutes from [Completion.createdAt].
final class IsarCompletionRepository implements CompletionRepository {
  IsarCompletionRepository(this._isar);

  final Isar _isar;

  @override
  Future<Completion> completeHabit({
    required String habitId,
    required String userId,
    required DateTime completedAt,
    required String localDate,
  }) async {
    // Idempotency: return existing non-undone completion for same day.
    final existing =
        await _isar.completionLocals
            .filter()
            .habitIdEqualTo(habitId)
            .localDateEqualTo(localDate)
            .isUndoneEqualTo(false)
            .findFirst();

    if (existing != null) return _toDomain(existing);

    final now = DateTime.now().toUtc();
    final local = CompletionLocal(
      id: _generateId(),
      habitId: habitId,
      userId: userId,
      completedAt: completedAt.toUtc(),
      localDate: localDate,
      isUndone: false,
      createdAt: now,
    );
    await _isar.writeTxn(() => _isar.completionLocals.put(local));
    return _toDomain(local);
  }

  @override
  Future<void> undoCompletion(String completionId) async {
    final existing = await _isar.completionLocals.getById(completionId);
    if (existing == null) {
      throw CacheFailure('Completion $completionId not found');
    }
    if (!HabitDateUtils.isWithinUndoWindow(existing.createdAt)) {
      throw const ValidationFailure(
        'Undo window has elapsed (5 minutes from completion)',
      );
    }
    final updated = CompletionLocal(
      id: existing.id,
      habitId: existing.habitId,
      userId: existing.userId,
      completedAt: existing.completedAt,
      localDate: existing.localDate,
      isUndone: true,
      createdAt: existing.createdAt,
      syncedAt: existing.syncedAt,
    );
    await _isar.writeTxn(() => _isar.completionLocals.put(updated));
  }

  @override
  Future<List<Completion>> getCompletionsForHabit(String habitId) async {
    final locals =
        await _isar.completionLocals
            .filter()
            .habitIdEqualTo(habitId)
            .isUndoneEqualTo(false)
            .sortByLocalDateDesc()
            .findAll();
    return locals.map(_toDomain).toList();
  }

  @override
  Future<List<Completion>> getCompletionsForDate(
    String userId,
    String localDate,
  ) async {
    final locals =
        await _isar.completionLocals
            .filter()
            .userIdEqualTo(userId)
            .localDateEqualTo(localDate)
            .isUndoneEqualTo(false)
            .findAll();
    return locals.map(_toDomain).toList();
  }

  @override
  Future<List<Completion>> getRecentCompletions(
    String habitId, {
    int days = 30,
  }) async {
    final cutoff = HabitDateUtils.toDateString(HabitDateUtils.daysAgo(days));
    final locals =
        await _isar.completionLocals
            .filter()
            .habitIdEqualTo(habitId)
            .isUndoneEqualTo(false)
            .localDateGreaterThan(cutoff, include: true)
            .sortByLocalDateDesc()
            .findAll();
    return locals.map(_toDomain).toList();
  }

  @override
  Future<List<Completion>> getPendingSyncCompletions(String userId) async {
    final locals =
        await _isar.completionLocals
            .filter()
            .userIdEqualTo(userId)
            .isUndoneEqualTo(false)
            .syncedAtIsNull()
            .findAll();
    return locals.map(_toDomain).toList();
  }

  // ── Mapping helpers ──────────────────────────────────────────────────────────

  static Completion _toDomain(CompletionLocal local) => Completion(
    id: local.id,
    habitId: local.habitId,
    userId: local.userId,
    completedAt: local.completedAt,
    localDate: local.localDate,
    isUndone: local.isUndone,
    createdAt: local.createdAt,
  );

  static String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(16);
}
