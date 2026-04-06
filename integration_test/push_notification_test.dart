import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/notifications/domain/entities/notification_preferences.dart';
import 'package:habit_coach/features/notifications/domain/repositories/notification_repository.dart';
import 'package:integration_test/integration_test.dart';

/// T181: Push notification integration smoke tests.
///
/// Tests run in isolation (no Firebase / Supabase). They validate:
/// - FCM token registration/refresh via the repository contract
/// - Notification preferences persist and toggle correctly
/// - Tap routing resolves correct routes for all notification types

class _InMemoryNotificationRepository implements NotificationRepository {
  NotificationPreferences _prefs = const NotificationPreferences();
  String? _token;

  @override
  Future<NotificationPreferences> getPreferences(String userId) async => _prefs;

  @override
  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    _prefs = preferences;
  }

  @override
  Future<void> registerFCMToken(String userId, String token) async {
    _token = token;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _InMemoryNotificationRepository repo;

  setUp(() {
    repo = _InMemoryNotificationRepository();
  });

  testWidgets('US8 smoke: FCM token registration and refresh', (tester) async {
    await repo.registerFCMToken('user-1', 'initial-token');
    expect(repo._token, 'initial-token');

    await repo.registerFCMToken('user-1', 'refreshed-token');
    expect(repo._token, 'refreshed-token');
  });

  testWidgets('US8 smoke: notification preferences toggle persists', (
    tester,
  ) async {
    var prefs = await repo.getPreferences('user-1');
    expect(prefs.reminder, isTrue);

    await repo.updatePreferences(
      'user-1',
      prefs.copyWith(reminder: false, streakAtRisk: false),
    );

    prefs = await repo.getPreferences('user-1');
    expect(prefs.reminder, isFalse);
    expect(prefs.streakAtRisk, isFalse);
    expect(prefs.milestone, isTrue);
  });

  testWidgets('US8 smoke: quiet hours round-trip via preferences', (
    tester,
  ) async {
    const quietHours = QuietHours(start: 22, end: 7);
    await repo.updatePreferences(
      'user-1',
      const NotificationPreferences(quietHours: quietHours),
    );
    final prefs = await repo.getPreferences('user-1');
    expect(prefs.quietHours.start, 22);
    expect(prefs.quietHours.end, 7);
    expect(prefs.quietHours.contains(23), isTrue);
    expect(prefs.quietHours.contains(12), isFalse);
  });

  testWidgets('US8 smoke: tap routing resolves correct routes', (tester) async {
    // reminder → dashboard
    expect(
      AppRoutes.routeForNotificationPayload('reminder:'),
      AppRoutes.dashboard,
    );

    // streak_at_risk → dashboard
    expect(
      AppRoutes.routeForNotificationPayload('streak_at_risk:'),
      AppRoutes.dashboard,
    );

    // partner_nudge → partner dashboard
    expect(
      AppRoutes.routeForNotificationPayload('partner_nudge:'),
      AppRoutes.partnerDashboard,
    );

    // challenge_update with id → challenge detail
    final route = AppRoutes.routeForNotificationPayload(
      'challenge_update:chal-42',
    );
    expect(route, '/challenge/chal-42');

    // unknown type → null
    expect(AppRoutes.routeForNotificationPayload('unknown:'), isNull);

    // null payload → null
    expect(AppRoutes.routeForNotificationPayload(null), isNull);
  });
}
