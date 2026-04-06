import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge_participant.dart';

void main() {
  final now = DateTime.now();
  final start = now.add(const Duration(days: 1));
  final end = now.add(const Duration(days: 31));

  Challenge _challenge({
    ChallengeStatus status = ChallengeStatus.pending,
    int participantCount = 1,
    ChallengeMode mode = ChallengeMode.compete,
    int? collaborateTargetPct,
  }) => Challenge(
    id: 'ch-1',
    creatorId: 'u1',
    habitDescription: 'Run every day',
    mode: mode,
    startDate: start,
    endDate: end,
    maxParticipants: 5,
    collaborateTargetPct: collaborateTargetPct,
    inviteToken: 'tok-abc',
    status: status,
    participantCount: participantCount,
    createdAt: now,
  );

  group('status helpers', () {
    test('isPending', () => expect(_challenge().isPending, isTrue));
    test('isActive', () {
      expect(_challenge(status: ChallengeStatus.active).isActive, isTrue);
    });
    test('isCompleted', () {
      expect(_challenge(status: ChallengeStatus.completed).isCompleted, isTrue);
    });
    test('isCancelled', () {
      expect(_challenge(status: ChallengeStatus.cancelled).isCancelled, isTrue);
    });
    test('isOpen includes pending and active', () {
      expect(_challenge(status: ChallengeStatus.pending).isOpen, isTrue);
      expect(_challenge(status: ChallengeStatus.active).isOpen, isTrue);
      expect(_challenge(status: ChallengeStatus.completed).isOpen, isFalse);
    });
  });

  group('hasCapacity', () {
    test('true when under max', () {
      expect(_challenge(participantCount: 4).hasCapacity, isTrue);
    });
    test('false when at max', () {
      expect(_challenge(participantCount: 5).hasCapacity, isFalse);
    });
  });

  group('durationDays', () {
    test('equals end - start in days', () {
      expect(_challenge().durationDays, equals(30));
    });
  });

  group('copyWith', () {
    test('updates status', () {
      final c = _challenge().copyWith(status: ChallengeStatus.active);
      expect(c.isActive, isTrue);
      expect(c.habitDescription, equals('Run every day'));
    });
    test('updates participantCount', () {
      expect(
        _challenge().copyWith(participantCount: 3).participantCount,
        equals(3),
      );
    });
  });

  group('equality', () {
    test('same id → equal', () {
      expect(_challenge(), equals(_challenge(status: ChallengeStatus.active)));
    });
    test('different id → not equal', () {
      final other = Challenge(
        id: 'ch-2',
        creatorId: 'u1',
        habitDescription: 'Run',
        mode: ChallengeMode.compete,
        startDate: start,
        endDate: end,
        maxParticipants: 5,
        inviteToken: 'tok-xyz',
        status: ChallengeStatus.pending,
        participantCount: 1,
        createdAt: now,
      );
      expect(_challenge(), isNot(equals(other)));
    });
  });

  group('ChallengeParticipant', () {
    ChallengeParticipant _part({
      ParticipantStatus status = ParticipantStatus.active,
    }) => ChallengeParticipant(
      id: 'p-1',
      challengeId: 'ch-1',
      userId: 'u1',
      displayName: 'Alice',
      completionCount: 5,
      currentStreak: 3,
      status: status,
      joinedAt: now,
    );

    test('isActive', () => expect(_part().isActive, isTrue));
    test('hasLeft', () {
      expect(_part(status: ParticipantStatus.left).hasLeft, isTrue);
    });

    test('copyWith updates completionCount', () {
      expect(_part().copyWith(completionCount: 10).completionCount, 10);
    });
  });

  group('leaderboard sorting', () {
    test('sorted by completionCount descending then streak', () {
      final participants = [
        ChallengeParticipant(
          id: 'p1',
          challengeId: 'ch-1',
          userId: 'u1',
          displayName: 'Alice',
          completionCount: 3,
          currentStreak: 3,
          status: ParticipantStatus.active,
          joinedAt: now,
        ),
        ChallengeParticipant(
          id: 'p2',
          challengeId: 'ch-1',
          userId: 'u2',
          displayName: 'Bob',
          completionCount: 5,
          currentStreak: 2,
          status: ParticipantStatus.active,
          joinedAt: now,
        ),
        ChallengeParticipant(
          id: 'p3',
          challengeId: 'ch-1',
          userId: 'u3',
          displayName: 'Carol',
          completionCount: 5,
          currentStreak: 4,
          status: ParticipantStatus.active,
          joinedAt: now,
        ),
      ];

      participants.sort((a, b) {
        final cc = b.completionCount.compareTo(a.completionCount);
        if (cc != 0) return cc;
        return b.currentStreak.compareTo(a.currentStreak);
      });

      expect(participants[0].displayName, equals('Carol')); // 5 comp, 4 streak
      expect(participants[1].displayName, equals('Bob')); // 5 comp, 2 streak
      expect(participants[2].displayName, equals('Alice')); // 3 comp
    });
  });
}
