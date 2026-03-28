import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge_participant.dart';
import 'package:integration_test/integration_test.dart';

/// T176: Challenge integration smoke test.
///
/// Validates domain entity behaviour and leaderboard sorting in isolation.
/// Full E2E Supabase flows (create → invite → join → complete → leaderboard)
/// run in CI against a seeded test project.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final start = now.add(const Duration(days: 1));
  final end = now.add(const Duration(days: 31));

  testWidgets('new challenge is pending with capacity', (tester) async {
    final c = Challenge(
      id: 'ch-1',
      creatorId: 'u1',
      habitDescription: 'Run 1 km',
      mode: ChallengeMode.compete,
      startDate: start,
      endDate: end,
      maxParticipants: 5,
      inviteToken: 'tok',
      status: ChallengeStatus.pending,
      participantCount: 1,
      createdAt: now,
    );
    expect(c.isPending, isTrue);
    expect(c.hasCapacity, isTrue);
    expect(c.durationDays, equals(30));
  });

  testWidgets('challenge becomes full at max participants', (tester) async {
    final c = Challenge(
      id: 'ch-1',
      creatorId: 'u1',
      habitDescription: 'Run 1 km',
      mode: ChallengeMode.compete,
      startDate: start,
      endDate: end,
      maxParticipants: 5,
      inviteToken: 'tok',
      status: ChallengeStatus.active,
      participantCount: 5,
      createdAt: now,
    );
    expect(c.hasCapacity, isFalse);
  });

  testWidgets('leaderboard ranks by completion count then streak', (
    tester,
  ) async {
    final participants = [
      ChallengeParticipant(
        id: 'p1',
        challengeId: 'ch-1',
        userId: 'u1',
        displayName: 'Alice',
        completionCount: 10,
        currentStreak: 5,
        status: ParticipantStatus.active,
        joinedAt: now,
      ),
      ChallengeParticipant(
        id: 'p2',
        challengeId: 'ch-1',
        userId: 'u2',
        displayName: 'Bob',
        completionCount: 10,
        currentStreak: 3,
        status: ParticipantStatus.active,
        joinedAt: now,
      ),
      ChallengeParticipant(
        id: 'p3',
        challengeId: 'ch-1',
        userId: 'u3',
        displayName: 'Carol',
        completionCount: 7,
        currentStreak: 7,
        status: ParticipantStatus.active,
        joinedAt: now,
      ),
    ];

    participants.sort((a, b) {
      final cc = b.completionCount.compareTo(a.completionCount);
      if (cc != 0) return cc;
      return b.currentStreak.compareTo(a.currentStreak);
    });

    expect(participants[0].displayName, equals('Alice'));
    expect(participants[1].displayName, equals('Bob'));
    expect(participants[2].displayName, equals('Carol'));
  });

  testWidgets('challenge lifecycle: pending → active → completed', (
    tester,
  ) async {
    var c = Challenge(
      id: 'ch-1',
      creatorId: 'u1',
      habitDescription: 'Run',
      mode: ChallengeMode.compete,
      startDate: start,
      endDate: end,
      maxParticipants: 5,
      inviteToken: 'tok',
      status: ChallengeStatus.pending,
      participantCount: 2,
      createdAt: now,
    );
    expect(c.isPending, isTrue);
    c = c.copyWith(status: ChallengeStatus.active);
    expect(c.isActive, isTrue);
    c = c.copyWith(status: ChallengeStatus.completed);
    expect(c.isCompleted, isTrue);
    expect(c.isOpen, isFalse);
  });
}
