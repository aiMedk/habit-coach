import 'package:isar/isar.dart';
import 'package:habit_coach/core/error/failures.dart';
import 'package:habit_coach/features/habits/data/models/isar_models.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/domain/repositories/habit_repository.dart';

/// T041: IsarHabitRepository — offline-first local storage using Isar.
///
/// All reads/writes hit Isar directly for instant UI response.
/// [SupabaseSyncService] is responsible for syncing mutations to the server.
final class IsarHabitRepository implements HabitRepository {
  IsarHabitRepository(this._isar, {required this.userId});

  final Isar _isar;
  final String userId;

  @override
  Future<List<Habit>> getHabits({bool activeOnly = false}) async {
    final query = _isar.habitLocals
        .filter()
        .userIdEqualTo(userId)
        .apply((q) => activeOnly ? q.isActiveEqualTo(true) : q);
    final locals = await query.findAll();
    return locals.map(_toDomain).toList();
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    final local = await _isar.habitLocals.getById(id);
    return local != null ? _toDomain(local) : null;
  }

  @override
  Future<Habit> createHabit({
    required String name,
    String? description,
    required HabitFrequency frequency,
    List<int>? frequencyDays,
  }) async {
    if (frequency == HabitFrequency.specificDays &&
        (frequencyDays == null || frequencyDays.isEmpty)) {
      throw const ValidationFailure(
        'specific_days frequency requires at least one day',
      );
    }
    final now = DateTime.now().toUtc();
    final id = _generateId();
    final local = HabitLocal(
      id: id,
      userId: userId,
      name: name,
      description: description,
      frequency: frequency.name,
      frequencyDays: frequencyDays,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    await _isar.writeTxn(() => _isar.habitLocals.put(local));
    return _toDomain(local);
  }

  @override
  Future<Habit> updateHabit(Habit habit) async {
    final existing = await _isar.habitLocals.getById(habit.id);
    if (existing == null) throw CacheFailure('Habit ${habit.id} not found');
    final updated = HabitLocal(
      id: existing.id,
      userId: existing.userId,
      name: habit.name,
      description: habit.description,
      frequency: habit.frequency.name,
      frequencyDays: habit.frequencyDays,
      isActive: habit.isActive,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    await _isar.writeTxn(() => _isar.habitLocals.put(updated));
    return _toDomain(updated);
  }

  @override
  Future<void> deactivateHabit(String habitId) async {
    final existing = await _isar.habitLocals.getById(habitId);
    if (existing == null) return;
    final updated = HabitLocal(
      id: existing.id,
      userId: existing.userId,
      name: existing.name,
      description: existing.description,
      frequency: existing.frequency,
      frequencyDays: existing.frequencyDays,
      isActive: false,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    await _isar.writeTxn(() => _isar.habitLocals.put(updated));
  }

  @override
  Future<Habit> reactivateHabit(String habitId) async {
    final existing = await _isar.habitLocals.getById(habitId);
    if (existing == null) throw CacheFailure('Habit $habitId not found');
    final updated = HabitLocal(
      id: existing.id,
      userId: existing.userId,
      name: existing.name,
      description: existing.description,
      frequency: existing.frequency,
      frequencyDays: existing.frequencyDays,
      isActive: true,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    await _isar.writeTxn(() => _isar.habitLocals.put(updated));
    return _toDomain(updated);
  }

  // ── Mapping helpers ──────────────────────────────────────────────────────────

  static Habit _toDomain(HabitLocal local) => Habit(
    id: local.id,
    userId: local.userId,
    name: local.name,
    description: local.description,
    frequency:
        local.frequency == 'specific_days'
            ? HabitFrequency.specificDays
            : HabitFrequency.daily,
    frequencyDays: local.frequencyDays,
    isActive: local.isActive,
    createdAt: local.createdAt,
    updatedAt: local.updatedAt,
  );

  static String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(16);
}

// Isar query builder extension helper
extension on QueryBuilder<HabitLocal, HabitLocal, QAfterFilterCondition> {
  QueryBuilder<HabitLocal, HabitLocal, QAfterFilterCondition> apply(
    QueryBuilder<HabitLocal, HabitLocal, QAfterFilterCondition> Function(
      QueryBuilder<HabitLocal, HabitLocal, QAfterFilterCondition>,
    )
    fn,
  ) => fn(this);
}
