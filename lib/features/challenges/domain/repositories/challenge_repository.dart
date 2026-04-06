import 'package:habit_coach/features/challenges/domain/entities/challenge.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge_participant.dart';

/// T100: ChallengeRepository interface — domain layer, no Supabase imports.
abstract interface class ChallengeRepository {
  /// Creates a new pending challenge and returns it with an invite token.
  ///
  /// Throws if the user already has 3 active challenges.
  Future<Challenge> createChallenge({
    required String creatorId,
    required String habitDescription,
    required ChallengeMode mode,
    required DateTime startDate,
    required DateTime endDate,
    int maxParticipants,
    int? collaborateTargetPct,
  });

  /// Joins a challenge via invite token. Creates a pending participant record.
  ///
  /// Throws if the challenge is full (5 participants) or user already joined.
  Future<ChallengeParticipant> joinChallenge({
    required String inviteToken,
    required String userId,
    required String displayName,
  });

  /// Leaves a challenge. Sets participant status to [ParticipantStatus.left].
  Future<void> leaveChallenge({
    required String challengeId,
    required String userId,
  });

  /// Returns a single challenge by ID.
  Future<Challenge?> getChallenge(String challengeId);

  /// Returns the sorted leaderboard for a challenge.
  ///
  /// Compete: ranked by completionCount desc, then currentStreak desc.
  /// Collaborate: ranked by completionCount desc.
  Future<List<ChallengeParticipant>> getLeaderboard(String challengeId);

  /// Returns all challenges the user is participating in (any status).
  Future<List<Challenge>> getUserActiveChallenges(String userId);
}
