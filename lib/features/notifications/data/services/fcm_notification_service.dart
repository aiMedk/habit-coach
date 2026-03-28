import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:habit_coach/features/notifications/domain/repositories/notification_repository.dart';

/// T123: FCMNotificationService — wraps FirebaseMessaging.
///
/// Responsibilities:
/// - Request notification permissions on first launch
/// - Obtain and register FCM token with Supabase
/// - Listen for token refreshes and re-register
/// - Expose the initial message for tap-to-navigate on cold start
/// - Expose onMessageOpenedApp for background tap-to-navigate
///
/// Foreground notification display is handled natively on iOS (via APNS) and
/// by Firebase's default notification channel on Android (configured in
/// AndroidManifest.xml). No extra package required.
class FCMNotificationService {
  FCMNotificationService(this._repo);

  final NotificationRepository _repo;

  /// Initialise FCM, request permissions, register the token, and set up
  /// listeners. Call once after the user authenticates.
  Future<void> init(String userId) async {
    // Request permissions (iOS / macOS).
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Show foreground notifications on iOS.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Register current token.
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _repo.registerFCMToken(userId, token);
    }

    // Listen for token refreshes.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _repo.registerFCMToken(userId, newToken);
    });
  }

  /// Returns the notification payload that launched the app (cold start).
  /// The caller should navigate based on [AppRoutes.routeForNotificationPayload].
  Future<String?> getInitialPayload() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return _payloadFromMessage(message);
  }

  /// Stream of notification payloads when tapped while app is in background.
  Stream<String?> get onMessageOpenedAppPayload =>
      FirebaseMessaging.onMessageOpenedApp.map(_payloadFromMessage);

  String? _payloadFromMessage(RemoteMessage? message) {
    if (message == null) return null;
    final type = message.data['type'] as String?;
    final id = message.data['notification_id'] as String? ?? '';
    if (type == null) return null;
    return '$type:$id';
  }
}
