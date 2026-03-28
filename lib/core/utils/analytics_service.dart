import 'package:supabase_flutter/supabase_flutter.dart';

/// T188: Analytics event tracking — logs key user actions to a lightweight
/// Supabase `analytics_events` table for success-criteria measurement.
///
/// Events tracked:
///   habit_completed, streak_milestone, ai_checkin_started,
///   ai_checkin_completed, partner_invited, partner_accepted,
///   challenge_joined, subscription_purchased, subscription_cancelled.
///
/// The service is intentionally fire-and-forget (errors are swallowed) so
/// analytics failures never block user-facing flows.
class AnalyticsService {
  AnalyticsService(this._client);

  final SupabaseClient _client;

  // ── Event name constants ─────────────────────────────────────────────────
  static const habitCompleted = 'habit_completed';
  static const streakMilestone = 'streak_milestone';
  static const aiCheckinStarted = 'ai_checkin_started';
  static const aiCheckinCompleted = 'ai_checkin_completed';
  static const partnerInvited = 'partner_invited';
  static const partnerAccepted = 'partner_accepted';
  static const challengeJoined = 'challenge_joined';
  static const subscriptionPurchased = 'subscription_purchased';
  static const subscriptionCancelled = 'subscription_cancelled';

  /// Logs an analytics event with optional [properties].
  ///
  /// Silently swallows errors — analytics must never interrupt UX.
  Future<void> track(
    String event, {
    Map<String, dynamic> properties = const {},
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      await _client.from('analytics_events').insert({
        'user_id': userId,
        'event': event,
        'properties': properties,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Intentionally ignored — analytics failures are non-fatal.
    }
  }
}
