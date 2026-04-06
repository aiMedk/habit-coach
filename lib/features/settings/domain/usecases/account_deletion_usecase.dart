import 'package:supabase_flutter/supabase_flutter.dart';

/// T138: AccountDeletionUseCase — soft-delete flow.
///
/// Steps:
///   1. Set user's deletion_status to 'pending_deletion' and record
///      deletion_requested_at = NOW().
///   2. Cancel any active subscription (RevenueCat cancellation is handled
///      out-of-band by the user via the store; we mark locally as cancelled).
///   3. Dissolve all active partnerships.
///   4. Cancel all pending/active challenges created by the user.
///   5. Sign the user out.
///
/// The actual data purge runs 30 days later via a Supabase scheduled function
/// (migration 020_purge_deleted_accounts.sql).
///
/// This use-case touches Supabase directly (service-level operations) because
/// it crosses feature boundaries. It is intentionally placed in the settings
/// domain layer.
class AccountDeletionUseCase {
  AccountDeletionUseCase(this._client);

  final SupabaseClient _client;

  Future<void> execute(String userId) async {
    // 1. Mark account as pending deletion.
    await _client
        .from('users')
        .update({
          'deletion_status': 'pending_deletion',
          'deletion_requested_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);

    // 2. Mark subscription as cancelled (store cancellation is user-side).
    await _client
        .from('subscriptions')
        .update({'status': 'cancelled'})
        .eq('user_id', userId)
        .eq('status', 'active');

    // 3. Dissolve all active/pending partnerships.
    await _client
        .from('partnerships')
        .update({'status': 'dissolved'})
        .or('inviter_id.eq.$userId,invitee_id.eq.$userId')
        .inFilter('status', ['active', 'pending', 'suspended']);

    // 4. Cancel all active/pending challenges created by this user.
    await _client
        .from('challenges')
        .update({'status': 'cancelled'})
        .eq('creator_id', userId)
        .inFilter('status', ['pending', 'active']);

    // 5. Sign out — clears local session.
    await _client.auth.signOut();
  }
}
