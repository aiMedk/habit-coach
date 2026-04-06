import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/accountability/domain/entities/commitment.dart';

void main() {
  final deadline = DateTime.now().add(const Duration(days: 14));
  final createdAt = DateTime.now();

  Commitment _make({
    CommitmentStatus status = CommitmentStatus.active,
    int targetStreak = 7,
    int currentStreak = 0,
    DateTime? dl,
  }) => Commitment(
    id: 'c-1',
    userId: 'u1',
    partnerId: 'u2',
    habitId: 'h1',
    habitName: 'Meditate',
    targetStreak: targetStreak,
    deadline: dl ?? deadline,
    status: status,
    currentStreak: currentStreak,
    createdAt: createdAt,
  );

  group('status helpers', () {
    test('isActive', () => expect(_make().isActive, isTrue));
    test('isFulfilled', () {
      expect(_make(status: CommitmentStatus.fulfilled).isFulfilled, isTrue);
    });
    test('isFailed', () {
      expect(_make(status: CommitmentStatus.failed).isFailed, isTrue);
    });
  });

  group('progress', () {
    test('0.0 when no streak', () {
      expect(_make(targetStreak: 7, currentStreak: 0).progress, equals(0.0));
    });

    test('0.5 at half streak', () {
      expect(
        _make(targetStreak: 7, currentStreak: 3).progress,
        closeTo(3 / 7, 0.001),
      );
    });

    test('capped at 1.0 if overshoot', () {
      expect(_make(targetStreak: 7, currentStreak: 10).progress, equals(1.0));
    });
  });

  group('daysRemaining', () {
    test('positive for future deadline', () {
      final c = _make(dl: DateTime.now().add(const Duration(days: 5)));
      expect(c.daysRemaining, greaterThanOrEqualTo(4));
    });

    test('negative for past deadline', () {
      final c = _make(dl: DateTime.now().subtract(const Duration(days: 1)));
      expect(c.daysRemaining, lessThan(0));
    });
  });

  group('copyWith', () {
    test('updates status', () {
      final c = _make().copyWith(status: CommitmentStatus.fulfilled);
      expect(c.isFulfilled, isTrue);
      expect(c.habitName, equals('Meditate'));
    });

    test('updates currentStreak', () {
      final c = _make().copyWith(currentStreak: 5);
      expect(c.currentStreak, equals(5));
    });
  });

  group('equality', () {
    test('same id → equal', () {
      expect(_make(), equals(_make(status: CommitmentStatus.failed)));
    });

    test('different id → not equal', () {
      final other = Commitment(
        id: 'c-2',
        userId: 'u1',
        partnerId: 'u2',
        habitId: 'h1',
        habitName: 'Meditate',
        targetStreak: 7,
        deadline: deadline,
        status: CommitmentStatus.active,
        currentStreak: 0,
        createdAt: createdAt,
      );
      expect(_make(), isNot(equals(other)));
    });
  });
}
