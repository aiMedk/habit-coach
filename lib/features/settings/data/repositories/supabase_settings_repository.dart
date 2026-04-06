import 'package:supabase_flutter/supabase_flutter.dart';

/// T139: SupabaseSettingsRepository — persists user settings (timezone,
/// notification preferences, weekly review day).
class SupabaseSettingsRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Updates the user's IANA timezone identifier.
  Future<void> updateTimezone(String userId, String timezone) async {
    await _client.from('users').update({'timezone': timezone}).eq('id', userId);
  }

  /// Updates the weekly review day (0 = Sunday, 1 = Monday … 6 = Saturday).
  Future<void> updateReviewDay(String userId, int reviewDay) async {
    assert(reviewDay >= 0 && reviewDay <= 6, 'reviewDay must be 0–6 (Sun–Sat)');
    await _client
        .from('users')
        .update({'review_day': reviewDay})
        .eq('id', userId);
  }

  /// Returns the user's current settings as a map.
  Future<Map<String, dynamic>> getSettings(String userId) async {
    final row =
        await _client
            .from('users')
            .select('timezone, notification_preferences, review_day')
            .eq('id', userId)
            .single();
    return row;
  }
}
