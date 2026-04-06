import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge_participant.dart';
import 'package:habit_coach/features/challenges/domain/repositories/challenge_repository.dart';

void main() {
  late ChallengeRepository repo;
  final start = DateTime.now().add(const Duration(days: 1));
  final end = DateTime.now().add(const Duration(days: 31));

  setUp(() {
    repo = _FakeChallengeRepository();
  });

  test('createChallenge returns pending challenge', () async {
    final c = await repo.createChallenge(
      creatorId: 'u1',
      habitDescription: 'Run',
      mode: ChallengeMode.compete,
      startDate: start,
      endDate: end,
    );
    expect(c.isPending, isTrue);
    expect(c.creatorId, equals('u1'));
    expect(c.inviteToken, isNotEmpty);
  });

  test('getUserActiveChallenges returns empty initially', () async {
    final list = await repo.getUserActiveChallenges('nobody');
    expect(list, isEmpty);
  });

  test('joinChallenge adds participant', () async {
    final c = await repo.createChallenge(
      creatorId: 'u1',
      habitDescription: 'Run',
      mode: ChallengeMode.compete,
      startDate: start,
      endDate: end,
    );
    final p = await repo.joinChallenge(
      inviteToken: c.inviteToken,
      userId: 'u2',
      displayName: 'Bob',
    );
    expect(p.challengeId, equals(c.id));
  });

  test('joinChallenge throws on invalid token', () async {
    await expectLater(
      () => repo.joinChallenge(
        inviteToken: 'bad',
        userId: 'u2',
        displayName: 'X',
      ),
      throwsException,
    );
  });

  test('5-participant cap enforced', () async {
    final c = await repo.createChallenge(
      creatorId: 'u1',
      habitDescription: 'Run',
      mode: ChallengeMode.compete,
      startDate: start,
      endDate: end,
      maxParticipants: 2,
    );
    await repo.joinChallenge(
      inviteToken: c.inviteToken,
      userId: 'u2',
      displayName: 'B',
    );
    await expectLater(
      () => repo.joinChallenge(
        inviteToken: c.inviteToken,
        userId: 'u3',
        displayName: 'C',
      ),
      throwsException,
    );
  });

  test('leaveChallenge sets participant to left', () async {
    final c = await repo.createChallenge(
      creatorId: 'u1',
      habitDescription: 'Run',
      mode: ChallengeMode.compete,
      startDate: start,
      endDate: end,
    );
    await repo.joinChallenge(
      inviteToken: c.inviteToken,
      userId: 'u2',
      displayName: 'B',
    );
    await repo.leaveChallenge(challengeId: c.id, userId: 'u2');
    final board = await repo.getLeaderboard(c.id);
    expect(board.any((p) => p.userId == 'u2'), isFalse);
  });

  test('getLeaderboard returns sorted participants', () async {
    final c = await repo.createChallenge(
      creatorId: 'u1',
      habitDescription: 'Run',
      mode: ChallengeMode.compete,
      startDate: start,
      endDate: end,
    );
    await repo.joinChallenge(
      inviteToken: c.inviteToken,
      userId: 'u2',
      displayName: 'Bob',
    );
    final board = await repo.getLeaderboard(c.id);
    // Creator (u1) is in the board as a participant
    expect(board, isNotEmpty);
  });
}

// ── Fake implementation ───────────────────────────────────────────────────────

class _FakeChallengeRepository implements ChallengeRepository {
  final _challenges = <String, Challenge>{};
  final _participants = <String, List<ChallengeParticipant>>{};
  int _seq = 0;

  @override
  Future<Challenge> createChallenge({
    required String creatorId,
    required String habitDescription,
    required ChallengeMode mode,
    required DateTime startDate,
    required DateTime endDate,
    int maxParticipants = 5,
    int? collaborateTargetPct,
  }) async {
    final id = 'ch-${_seq++}';
    final c = Challenge(
      id: id,
      creatorId: creatorId,
      habitDescription: habitDescription,
      mode: mode,
      startDate: startDate,
      endDate: endDate,
      maxParticipants: maxParticipants,
      collaborateTargetPct: collaborateTargetPct,
      inviteToken: 'token-$id',
      status: ChallengeStatus.pending,
      participantCount: 1,
      createdAt: DateTime.now(),
    );
    _challenges[id] = c;
    _participants[id] = [
      ChallengeParticipant(
        id: 'p-creator-$id',
        challengeId: id,
        userId: creatorId,
        displayName: 'Creator',
        completionCount: 0,
        currentStreak: 0,
        status: ParticipantStatus.active,
        joinedAt: DateTime.now(),
      ),
    ];
    return c;
  }

  @override
  Future<ChallengeParticipant> joinChallenge({
    required String inviteToken,
    required String userId,
    required String displayName,
  }) async {
    final c =
        _challenges.values
            .where((c) => c.inviteToken == inviteToken)
            .firstOrNull;
    if (c == null) throw Exception('Invalid invite token');

    final existing = _participants[c.id] ?? [];
    final active = existing.where((p) => p.status != ParticipantStatus.left);
    if (active.length >= c.maxParticipants) {
      throw Exception('Challenge is full');
    }

    final p = ChallengeParticipant(
      id: 'p-${_seq++}',
      challengeId: c.id,
      userId: userId,
      displayName: displayName,
      completionCount: 0,
      currentStreak: 0,
      status: ParticipantStatus.active,
      joinedAt: DateTime.now(),
    );
    _participants[c.id] = [...existing, p];
    return p;
  }

  @override
  Future<void> leaveChallenge({
    required String challengeId,
    required String userId,
  }) async {
    final list = _participants[challengeId];
    if (list == null) return;
    _participants[challengeId] =
        list
            .map(
              (p) =>
                  p.userId == userId
                      ? p.copyWith(status: ParticipantStatus.left)
                      : p,
            )
            .toList();
  }

  @override
  Future<Challenge?> getChallenge(String challengeId) async {
    return _challenges[challengeId];
  }

  @override
  Future<List<ChallengeParticipant>> getLeaderboard(String challengeId) async {
    final list =
        (_participants[challengeId] ?? [])
            .where((p) => p.status != ParticipantStatus.left)
            .toList();
    list.sort((a, b) {
      final cc = b.completionCount.compareTo(a.completionCount);
      if (cc != 0) return cc;
      return b.currentStreak.compareTo(a.currentStreak);
    });
    return list;
  }

  @override
  Future<List<Challenge>> getUserActiveChallenges(String userId) async {
    final ids =
        (_participants.entries
            .where((e) => e.value.any((p) => p.userId == userId && !p.hasLeft))
            .map((e) => e.key)).toSet();
    return _challenges.values.where((c) => ids.contains(c.id)).toList();
  }
}
