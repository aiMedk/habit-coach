import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge.dart';
import 'package:habit_coach/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge_participant.dart';
import 'package:habit_coach/features/challenges/presentation/providers/challenge_providers.dart';
import 'package:habit_coach/features/challenges/presentation/screens/challenges_list_screen.dart';

class _FakeRepo implements ChallengeRepository {
  @override
  Future<Challenge> createChallenge({
    required String creatorId,
    required String habitDescription,
    required ChallengeMode mode,
    required DateTime startDate,
    required DateTime endDate,
    int maxParticipants = 5,
    int? collaborateTargetPct,
  }) => throw UnimplementedError();
  @override
  Future<ChallengeParticipant> joinChallenge({
    required String inviteToken,
    required String userId,
    required String displayName,
  }) => throw UnimplementedError();
  @override
  Future<void> leaveChallenge({
    required String challengeId,
    required String userId,
  }) async {}
  @override
  Future<Challenge?> getChallenge(String challengeId) async => null;
  @override
  Future<List<ChallengeParticipant>> getLeaderboard(String challengeId) async =>
      [];
  @override
  Future<List<Challenge>> getUserActiveChallenges(String userId) async => [];
}

void main() {
  final now = DateTime.now();

  Challenge _challenge(ChallengeStatus status) => Challenge(
    id: 'ch-${status.name}',
    creatorId: 'u1',
    habitDescription: 'Run every day',
    mode: ChallengeMode.compete,
    startDate: now.add(const Duration(days: 1)),
    endDate: now.add(const Duration(days: 31)),
    maxParticipants: 5,
    inviteToken: 'tok',
    status: status,
    participantCount: 2,
    createdAt: now,
  );

  Widget _wrap(List<Challenge> challenges) => ProviderScope(
    overrides: [
      challengeRepositoryProvider.overrideWithValue(_FakeRepo()),
      userChallengesProvider.overrideWith((_) async => challenges),
    ],
    child: const MaterialApp(home: ChallengesListScreen()),
  );

  testWidgets('shows empty state on Active tab when no active challenges', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap([]));
    await tester.pumpAndSettle();
    expect(find.text('No active challenges'), findsOneWidget);
  });

  testWidgets('active challenge appears in Active tab', (tester) async {
    await tester.pumpWidget(_wrap([_challenge(ChallengeStatus.active)]));
    await tester.pumpAndSettle();
    expect(find.text('Run every day'), findsOneWidget);
  });

  testWidgets('pending challenge appears in Pending tab', (tester) async {
    await tester.pumpWidget(_wrap([_challenge(ChallengeStatus.pending)]));
    await tester.pumpAndSettle();
    // Switch to Pending tab
    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();
    expect(find.text('Run every day'), findsOneWidget);
  });

  testWidgets('shows FAB for creating new challenge', (tester) async {
    await tester.pumpWidget(_wrap([]));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
