import 'package:habit_coach/features/settings/domain/entities/blocked_user.dart';

/// T078: BlockRepository interface — domain layer, no Supabase imports.
abstract interface class BlockRepository {
  /// Blocks [targetUserId] on behalf of [blockerId].
  ///
  /// Also dissolves any active partnership between the two users.
  Future<BlockedUser> blockUser({
    required String blockerId,
    required String targetUserId,
  });

  /// Removes the block between [blockerId] and [blockedUserId].
  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  });

  /// Returns all users blocked by [blockerId].
  Future<List<BlockedUser>> getBlockedUsers(String blockerId);

  /// Returns true if [blockerId] has blocked [targetUserId] (or vice versa).
  Future<bool> isBlocked({required String userId1, required String userId2});
}
