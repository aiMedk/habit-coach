import 'package:habit_coach/features/accountability/domain/entities/commitment.dart';

/// T091: CommitmentRepository interface — domain layer, no Supabase imports.
abstract interface class CommitmentRepository {
  /// Creates a new commitment for [userId] with [partnerId] as witness.
  ///
  /// Throws [ValidationFailure] if the user already has 3 active commitments
  /// or there is no active partnership between user and partner.
  Future<Commitment> createCommitment({
    required String userId,
    required String partnerId,
    required String habitId,
    required String habitName,
    required int targetStreak,
    required DateTime deadline,
  });

  /// Returns all active commitments for [userId] (own commitments only).
  Future<List<Commitment>> getActiveCommitments(String userId);

  /// Returns active commitments made to [partnerId] — what the partner sees.
  Future<List<Commitment>> getCommitmentsForPartner(String partnerId);

  /// Updates the status of a commitment (fulfilled or failed).
  Future<void> updateCommitmentStatus({
    required String commitmentId,
    required CommitmentStatus status,
  });
}
