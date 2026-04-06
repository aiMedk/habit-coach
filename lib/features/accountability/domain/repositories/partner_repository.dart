import 'package:habit_coach/features/accountability/domain/entities/partnership.dart';

/// T077: PartnerRepository interface — domain layer, no Supabase imports.
abstract interface class PartnerRepository {
  /// Creates a new pending partnership and returns the invite token.
  ///
  /// Throws [ValidationFailure] if the user already has an active/pending
  /// partnership.
  Future<Partnership> invitePartner(String inviterId);

  /// Accepts an invite by token. Sets status to [PartnershipStatus.active]
  /// and links the invitee.
  ///
  /// Throws [ValidationFailure] if the token is invalid or expired (>7 days).
  Future<Partnership> acceptInvite({
    required String inviteToken,
    required String inviteeId,
  });

  /// Returns the current user's active or pending partnership, or null.
  Future<Partnership?> getPartnership(String userId);

  /// Dissolves the partnership. Both users lose accountability features.
  Future<void> dissolvePartnership(String partnershipId);

  /// Returns the partner's streak summary for the shared dashboard.
  ///
  /// Returns null if the partnership is not active or has no partner.
  Future<PartnerStreakSummary?> getPartnerStreaks(String partnershipId);
}
