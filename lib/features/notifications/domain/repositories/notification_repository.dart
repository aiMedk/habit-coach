import 'package:habit_coach/features/notifications/domain/entities/notification_preferences.dart';

/// T120: NotificationRepository interface — domain layer.
abstract interface class NotificationRepository {
  /// Returns the current notification preferences for [userId].
  Future<NotificationPreferences> getPreferences(String userId);

  /// Persists updated [preferences] for [userId].
  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  );

  /// Registers or refreshes the FCM [token] for [userId].
  /// Called after FCM token is obtained/refreshed on the device.
  Future<void> registerFCMToken(String userId, String token);
}
