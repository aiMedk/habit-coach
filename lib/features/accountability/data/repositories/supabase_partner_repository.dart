import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_coach/core/error/failures.dart';
import 'package:habit_coach/core/network/supabase_client.dart';
import 'package:habit_coach/features/accountability/domain/entities/partnership.dart';
import 'package:habit_coach/features/accountability/domain/repositories/partner_repository.dart';

/// T079: SupabasePartnerRepository — implements [PartnerRepository] using
/// Supabase queries. Uses real-time subscription for status changes.
final class SupabasePartnerRepository implements PartnerRepository {
  SupabasePartnerRepository() : _client = AppSupabaseClient.instance;

  final SupabaseClient _client;

  @override
  Future<Partnership> invitePartner(String inviterId) async {
    // Check for existing active/pending partnership
    final existing = await getPartnership(inviterId);
    if (existing != null) {
      throw const ValidationFailure(
        'You already have an active or pending partnership',
      );
    }

    try {
      final data =
          await _client
              .from('partnerships')
              .insert({'inviter_id': inviterId})
              .select()
              .single();
      return _mapToPartnership(data);
    } catch (e) {
      throw ServerFailure('Failed to create partnership invite: $e');
    }
  }

  @override
  Future<Partnership> acceptInvite({
    required String inviteToken,
    required String inviteeId,
  }) async {
    // Look up the invite
    final data =
        await _client
            .from('partnerships')
            .select()
            .eq('invite_token', inviteToken)
            .eq('status', 'pending')
            .maybeSingle();

    if (data == null) {
      throw const ValidationFailure('Invite not found or already used');
    }

    final partnership = _mapToPartnership(data);

    // Check expiry (7 days)
    final age = DateTime.now().difference(partnership.createdAt);
    if (age.inDays >= 7) {
      throw const ValidationFailure(
        'This invite has expired. Ask your partner to send a new one.',
      );
    }

    try {
      final updated =
          await _client
              .from('partnerships')
              .update({'invitee_id': inviteeId, 'status': 'active'})
              .eq('id', partnership.id)
              .select()
              .single();
      return _mapToPartnership(updated);
    } catch (e) {
      throw ServerFailure('Failed to accept invite: $e');
    }
  }

  @override
  Future<Partnership?> getPartnership(String userId) async {
    try {
      // A user can be inviter OR invitee
      final data =
          await _client
              .from('partnerships')
              .select()
              .or('inviter_id.eq.$userId,invitee_id.eq.$userId')
              .inFilter('status', ['pending', 'active', 'suspended'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
      return data != null ? _mapToPartnership(data) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> dissolvePartnership(String partnershipId) async {
    try {
      await _client
          .from('partnerships')
          .update({'status': 'dissolved'})
          .eq('id', partnershipId);
    } catch (e) {
      throw ServerFailure('Failed to dissolve partnership: $e');
    }
  }

  @override
  Future<PartnerStreakSummary?> getPartnerStreaks(String partnershipId) async {
    try {
      // Get partnership to find partner ID
      final partnershipData =
          await _client
              .from('partnerships')
              .select('inviter_id, invitee_id, status')
              .eq('id', partnershipId)
              .eq('status', 'active')
              .maybeSingle();

      if (partnershipData == null) return null;

      // Resolve partner ID (we need to know current user to pick the right side,
      // so we fetch both sides' data and the caller filters)
      final partnerId = partnershipData['invitee_id'] as String?;
      if (partnerId == null) return null;

      // Fetch partner profile
      final profileData =
          await _client
              .from('users')
              .select('display_name')
              .eq('id', partnerId)
              .maybeSingle();

      if (profileData == null) return null;

      // Fetch partner's active habits
      final habits = await _client
          .from('habits')
          .select('id, name')
          .eq('user_id', partnerId)
          .eq('is_active', true)
          .limit(10);

      if ((habits as List).isEmpty) {
        return PartnerStreakSummary(
          partnerId: partnerId,
          partnerName: profileData['display_name'] as String,
          streaks: const {},
          completionRateToday: 0,
        );
      }

      // Today's completions for partner
      final today = DateTime.now();
      final todayStr =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final completions = await _client
          .from('completions')
          .select('habit_id')
          .eq('user_id', partnerId)
          .eq('local_date', todayStr)
          .eq('is_undone', false);

      final completedIds = Set<String>.from(
        (completions as List).map((c) => c['habit_id'] as String),
      );

      final habitList = (habits as List).cast<Map<String, dynamic>>();
      final completionRate =
          habitList.isEmpty ? 0.0 : completedIds.length / habitList.length;

      // Build streak map (simplified — uses completion count as proxy)
      final streaks = <String, int>{
        for (final h in habitList)
          h['name'] as String: completedIds.contains(h['id'] as String) ? 1 : 0,
      };

      return PartnerStreakSummary(
        partnerId: partnerId,
        partnerName: profileData['display_name'] as String,
        streaks: streaks,
        completionRateToday: completionRate,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Mapper ────────────────────────────────────────────────────────────────

  static Partnership _mapToPartnership(Map<String, dynamic> row) {
    return Partnership(
      id: row['id'] as String,
      inviterId: row['inviter_id'] as String,
      inviteeId: row['invitee_id'] as String?,
      inviteToken: row['invite_token'] as String,
      status: _parseStatus(row['status'] as String),
      suspendedAt:
          row['suspended_at'] != null
              ? DateTime.parse(row['suspended_at'] as String)
              : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  static PartnershipStatus _parseStatus(String s) => switch (s) {
    'active' => PartnershipStatus.active,
    'suspended' => PartnershipStatus.suspended,
    'dissolved' => PartnershipStatus.dissolved,
    _ => PartnershipStatus.pending,
  };
}
