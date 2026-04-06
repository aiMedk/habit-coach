import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/accountability/domain/entities/commitment.dart';
import 'package:habit_coach/features/accountability/domain/repositories/commitment_repository.dart';

void main() {
  late CommitmentRepository repo;
  final deadline = DateTime.now().add(const Duration(days: 14));

  setUp(() {
    repo = _FakeCommitmentRepository();
  });

  test('createCommitment returns active commitment', () async {
    final c = await repo.createCommitment(
      userId: 'u1',
      partnerId: 'u2',
      habitId: 'h1',
      habitName: 'Meditate',
      targetStreak: 7,
      deadline: deadline,
    );
    expect(c.isActive, isTrue);
    expect(c.habitName, equals('Meditate'));
  });

  test('getActiveCommitments returns empty initially', () async {
    final list = await repo.getActiveCommitments('nobody');
    expect(list, isEmpty);
  });

  test('getActiveCommitments returns created commitments', () async {
    await repo.createCommitment(
      userId: 'u1',
      partnerId: 'u2',
      habitId: 'h1',
      habitName: 'Run',
      targetStreak: 30,
      deadline: deadline,
    );
    final list = await repo.getActiveCommitments('u1');
    expect(list.length, equals(1));
  });

  test('3-active limit throws on 4th commitment', () async {
    for (var i = 0; i < 3; i++) {
      await repo.createCommitment(
        userId: 'u1',
        partnerId: 'u2',
        habitId: 'h$i',
        habitName: 'Habit $i',
        targetStreak: 7,
        deadline: deadline,
      );
    }
    await expectLater(
      () => repo.createCommitment(
        userId: 'u1',
        partnerId: 'u2',
        habitId: 'h99',
        habitName: 'Extra',
        targetStreak: 7,
        deadline: deadline,
      ),
      throwsException,
    );
  });

  test(
    'getCommitmentsForPartner returns commitments targeting that partner',
    () async {
      await repo.createCommitment(
        userId: 'u1',
        partnerId: 'u2',
        habitId: 'h1',
        habitName: 'Meditate',
        targetStreak: 7,
        deadline: deadline,
      );
      final list = await repo.getCommitmentsForPartner('u2');
      expect(list.length, equals(1));
      expect(list.first.partnerId, equals('u2'));
    },
  );

  test('updateCommitmentStatus changes status', () async {
    final c = await repo.createCommitment(
      userId: 'u1',
      partnerId: 'u2',
      habitId: 'h1',
      habitName: 'Meditate',
      targetStreak: 7,
      deadline: deadline,
    );
    await repo.updateCommitmentStatus(
      commitmentId: c.id,
      status: CommitmentStatus.fulfilled,
    );
    final list = await repo.getActiveCommitments('u1');
    // After fulfilling, it no longer appears in active list
    expect(list, isEmpty);
  });
}

// ── Fake implementation ───────────────────────────────────────────────────────

class _FakeCommitmentRepository implements CommitmentRepository {
  final _store = <String, Commitment>{};
  int _seq = 0;

  @override
  Future<Commitment> createCommitment({
    required String userId,
    required String partnerId,
    required String habitId,
    required String habitName,
    required int targetStreak,
    required DateTime deadline,
  }) async {
    final active =
        _store.values.where((c) => c.userId == userId && c.isActive).length;
    if (active >= 3) throw Exception('Maximum 3 active commitments per user');

    final c = Commitment(
      id: 'c-${_seq++}',
      userId: userId,
      partnerId: partnerId,
      habitId: habitId,
      habitName: habitName,
      targetStreak: targetStreak,
      deadline: deadline,
      status: CommitmentStatus.active,
      currentStreak: 0,
      createdAt: DateTime.now(),
    );
    _store[c.id] = c;
    return c;
  }

  @override
  Future<List<Commitment>> getActiveCommitments(String userId) async {
    return _store.values
        .where((c) => c.userId == userId && c.isActive)
        .toList();
  }

  @override
  Future<List<Commitment>> getCommitmentsForPartner(String partnerId) async {
    return _store.values
        .where((c) => c.partnerId == partnerId && c.isActive)
        .toList();
  }

  @override
  Future<void> updateCommitmentStatus({
    required String commitmentId,
    required CommitmentStatus status,
  }) async {
    final c = _store[commitmentId];
    if (c == null) return;
    _store[commitmentId] = c.copyWith(status: status);
  }
}
