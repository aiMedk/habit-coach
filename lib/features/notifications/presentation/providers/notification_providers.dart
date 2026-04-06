import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/notifications/data/repositories/supabase_notification_repository.dart';
import 'package:habit_coach/features/notifications/data/services/fcm_notification_service.dart';
import 'package:habit_coach/features/notifications/domain/entities/notification_preferences.dart';
import 'package:habit_coach/features/notifications/domain/repositories/notification_repository.dart';

/// T125: Notification Riverpod providers.

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => SupabaseNotificationRepository(),
);

final fcmNotificationServiceProvider = Provider<FCMNotificationService>(
  (ref) => FCMNotificationService(ref.watch(notificationRepositoryProvider)),
);

/// The current user's notification preferences.
final notificationPreferencesProvider = FutureProvider<NotificationPreferences>(
  (ref) async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) return const NotificationPreferences();
    return ref.watch(notificationRepositoryProvider).getPreferences(user.id);
  },
);

/// The device FCM token (null if not granted / not yet obtained).
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final settings = await FirebaseMessaging.instance.requestPermission();
  if (settings.authorizationStatus != AuthorizationStatus.authorized &&
      settings.authorizationStatus != AuthorizationStatus.provisional) {
    return null;
  }
  return FirebaseMessaging.instance.getToken();
});

// ── Update preferences notifier ───────────────────────────────────────────────

class UpdatePreferencesNotifier
    extends StateNotifier<AsyncValue<NotificationPreferences?>> {
  UpdatePreferencesNotifier(this._repo, this._ref)
    : super(const AsyncValue.data(null));

  final NotificationRepository _repo;
  final Ref _ref;

  Future<void> update(
    String userId,
    NotificationPreferences preferences,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updatePreferences(userId, preferences);
      state = AsyncValue.data(preferences);
      _ref.invalidate(notificationPreferencesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final updatePreferencesProvider = StateNotifierProvider.autoDispose<
  UpdatePreferencesNotifier,
  AsyncValue<NotificationPreferences?>
>((ref) {
  return UpdatePreferencesNotifier(
    ref.watch(notificationRepositoryProvider),
    ref,
  );
});
