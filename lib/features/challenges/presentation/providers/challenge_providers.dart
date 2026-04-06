import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/challenges/data/repositories/supabase_challenge_repository.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge_participant.dart';
import 'package:habit_coach/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';

/// T103: Challenge feature Riverpod providers.

final challengeRepositoryProvider = Provider<ChallengeRepository>(
  (ref) => SupabaseChallengeRepository(),
);

/// All challenges the current user is participating in.
final userChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref
      .watch(challengeRepositoryProvider)
      .getUserActiveChallenges(user.id);
});

/// Single challenge detail by ID.
final challengeDetailProvider = FutureProvider.family<Challenge?, String>((
  ref,
  challengeId,
) async {
  return ref.watch(challengeRepositoryProvider).getChallenge(challengeId);
});

/// Leaderboard for a challenge.
final leaderboardProvider =
    FutureProvider.family<List<ChallengeParticipant>, String>((
      ref,
      challengeId,
    ) async {
      return ref.watch(challengeRepositoryProvider).getLeaderboard(challengeId);
    });

// ── Create challenge notifier ─────────────────────────────────────────────────

class CreateChallengeState {
  const CreateChallengeState({
    this.isLoading = false,
    this.error,
    this.created,
  });

  final bool isLoading;
  final String? error;
  final Challenge? created;

  CreateChallengeState copyWith({
    bool? isLoading,
    String? error,
    Challenge? created,
  }) => CreateChallengeState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    created: created ?? this.created,
  );
}

class CreateChallengeNotifier extends StateNotifier<CreateChallengeState> {
  CreateChallengeNotifier(this._repo, this._ref)
    : super(const CreateChallengeState());

  final ChallengeRepository _repo;
  final Ref _ref;

  Future<void> create({
    required String creatorId,
    required String habitDescription,
    required ChallengeMode mode,
    required DateTime startDate,
    required DateTime endDate,
    int maxParticipants = 5,
    int? collaborateTargetPct,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final challenge = await _repo.createChallenge(
        creatorId: creatorId,
        habitDescription: habitDescription,
        mode: mode,
        startDate: startDate,
        endDate: endDate,
        maxParticipants: maxParticipants,
        collaborateTargetPct: collaborateTargetPct,
      );
      state = state.copyWith(isLoading: false, created: challenge);
      _ref.invalidate(userChallengesProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final createChallengeProvider = StateNotifierProvider.autoDispose<
  CreateChallengeNotifier,
  CreateChallengeState
>((ref) {
  return CreateChallengeNotifier(ref.watch(challengeRepositoryProvider), ref);
});

// ── Join challenge notifier ───────────────────────────────────────────────────

class JoinChallengeState {
  const JoinChallengeState({this.isLoading = false, this.error, this.joined});

  final bool isLoading;
  final String? error;
  final ChallengeParticipant? joined;

  JoinChallengeState copyWith({
    bool? isLoading,
    String? error,
    ChallengeParticipant? joined,
  }) => JoinChallengeState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    joined: joined ?? this.joined,
  );
}

class JoinChallengeNotifier extends StateNotifier<JoinChallengeState> {
  JoinChallengeNotifier(this._repo, this._ref)
    : super(const JoinChallengeState());

  final ChallengeRepository _repo;
  final Ref _ref;

  Future<void> join({
    required String inviteToken,
    required String userId,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final participant = await _repo.joinChallenge(
        inviteToken: inviteToken,
        userId: userId,
        displayName: displayName,
      );
      state = state.copyWith(isLoading: false, joined: participant);
      _ref.invalidate(userChallengesProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final joinChallengeProvider = StateNotifierProvider.autoDispose<
  JoinChallengeNotifier,
  JoinChallengeState
>((ref) {
  return JoinChallengeNotifier(ref.watch(challengeRepositoryProvider), ref);
});
