import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge_participant.dart';
import 'package:habit_coach/features/challenges/presentation/widgets/leaderboard_widget.dart';

void main() {
  final now = DateTime.now();

  ChallengeParticipant _part({
    required String id,
    required String userId,
    required String name,
    int completionCount = 0,
    int currentStreak = 0,
  }) => ChallengeParticipant(
    id: id,
    challengeId: 'ch-1',
    userId: userId,
    displayName: name,
    completionCount: completionCount,
    currentStreak: currentStreak,
    status: ParticipantStatus.active,
    joinedAt: now,
  );

  Widget _wrap(List<ChallengeParticipant> participants) => MaterialApp(
    home: Scaffold(
      body: LeaderboardWidget(participants: participants, currentUserId: 'u1'),
    ),
  );

  testWidgets('shows empty state when no participants', (tester) async {
    await tester.pumpWidget(_wrap([]));
    expect(find.text('No participants yet'), findsOneWidget);
  });

  testWidgets('shows participant names', (tester) async {
    await tester.pumpWidget(
      _wrap([
        _part(id: 'p1', userId: 'u1', name: 'Alice', completionCount: 5),
        _part(id: 'p2', userId: 'u2', name: 'Bob', completionCount: 3),
      ]),
    );
    expect(find.textContaining('Alice'), findsOneWidget);
    expect(find.textContaining('Bob'), findsOneWidget);
  });

  testWidgets('shows crown icon for leader', (tester) async {
    await tester.pumpWidget(
      _wrap([_part(id: 'p1', userId: 'u2', name: 'Bob', completionCount: 5)]),
    );
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('highlights current user row', (tester) async {
    await tester.pumpWidget(
      _wrap([
        _part(id: 'p1', userId: 'u1', name: 'Alice', completionCount: 5),
        _part(id: 'p2', userId: 'u2', name: 'Bob', completionCount: 3),
      ]),
    );
    // Current user row shows "(you)" suffix
    expect(find.textContaining('you'), findsOneWidget);
  });
}
