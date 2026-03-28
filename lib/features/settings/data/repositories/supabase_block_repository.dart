import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_coach/core/error/failures.dart';
import 'package:habit_coach/core/network/supabase_client.dart';
import 'package:habit_coach/features/settings/domain/entities/blocked_user.dart';
import 'package:habit_coach/features/settings/domain/repositories/block_repository.dart';

/// T080: SupabaseBlockRepository — implements [BlockRepository] using
/// Supabase queries. Blocking automatically dissolves any active partnership.
final class SupabaseBlockRepository implements BlockRepository {
  SupabaseBlockRepository() : _client = AppSupabaseClient.instance;

  final SupabaseClient _client;

  @override
  Future<BlockedUser> blockUser({
    required String blockerId,
    required String targetUserId,
  }) async {
    try {
      // Fetch target display name for cache
      final profileData =
          await _client
              .from('users')
              .select('display_name')
              .eq('id', targetUserId)
              .maybeSingle();

      final displayName =
          (profileData?['display_name'] as String?) ?? 'Unknown user';

      final data =
          await _client
              .from('blocked_users')
              .upsert({'blocker_id': blockerId, 'blocked_id': targetUserId})
              .select()
              .single();

      // Dissolve any active partnership between these two users
      await _client
          .from('partnerships')
          .update({'status': 'dissolved'})
          .or(
            'and(inviter_id.eq.$blockerId,invitee_id.eq.$targetUserId),'
            'and(inviter_id.eq.$targetUserId,invitee_id.eq.$blockerId)',
          )
          .inFilter('status', ['pending', 'active', 'suspended']);

      return BlockedUser(
        id: data['id'] as String,
        blockerId: blockerId,
        blockedId: targetUserId,
        blockedDisplayName: displayName,
        createdAt: DateTime.parse(data['created_at'] as String),
      );
    } catch (e) {
      throw ServerFailure('Failed to block user: $e');
    }
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      await _client
          .from('blocked_users')
          .delete()
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedUserId);
    } catch (e) {
      throw ServerFailure('Failed to unblock user: $e');
    }
  }

  @override
  Future<List<BlockedUser>> getBlockedUsers(String blockerId) async {
    try {
      final rows = await _client
          .from('blocked_users')
          .select('*, users!blocked_id(display_name)')
          .eq('blocker_id', blockerId)
          .order('created_at', ascending: false);

      return (rows as List).map((r) {
        final row = r as Map<String, dynamic>;
        final userJoin = row['users'] as Map<String, dynamic>?;
        return BlockedUser(
          id: row['id'] as String,
          blockerId: blockerId,
          blockedId: row['blocked_id'] as String,
          blockedDisplayName:
              (userJoin?['display_name'] as String?) ?? 'Unknown user',
          createdAt: DateTime.parse(row['created_at'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> isBlocked({
    required String userId1,
    required String userId2,
  }) async {
    try {
      final data =
          await _client
              .from('blocked_users')
              .select('id')
              .or(
                'and(blocker_id.eq.$userId1,blocked_id.eq.$userId2),'
                'and(blocker_id.eq.$userId2,blocked_id.eq.$userId1)',
              )
              .limit(1)
              .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }
}
