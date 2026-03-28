import 'package:habit_coach/features/notifications/domain/entities/notification_preferences.dart';
import 'package:habit_coach/features/notifications/domain/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// T124: Supabase implementation of NotificationRepository.
class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<NotificationPreferences> getPreferences(String userId) async {
    final row =
        await _client
            .from('users')
            .select('notification_preferences')
            .eq('id', userId)
            .single();

    final prefs = row['notification_preferences'];
    if (prefs == null) return const NotificationPreferences();
    return NotificationPreferences.fromJson(prefs as Map<String, dynamic>);
  }

  @override
  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    await _client
        .from('users')
        .update({'notification_preferences': preferences.toJson()})
        .eq('id', userId);
  }

  @override
  Future<void> registerFCMToken(String userId, String token) async {
    await _client.from('users').update({'fcm_token': token}).eq('id', userId);
  }
}
