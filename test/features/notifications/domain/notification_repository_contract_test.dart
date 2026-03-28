import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/notifications/domain/entities/notification_preferences.dart';
import 'package:habit_coach/features/notifications/domain/repositories/notification_repository.dart';

/// T180: NotificationRepository contract tests using a fake implementation.

class _FakeNotificationRepository implements NotificationRepository {
  final Map<String, NotificationPreferences> _prefs = {};
  final Map<String, String> _tokens = {};

  @override
  Future<NotificationPreferences> getPreferences(String userId) async =>
      _prefs[userId] ?? const NotificationPreferences();

  @override
  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    _prefs[userId] = preferences;
  }

  @override
  Future<void> registerFCMToken(String userId, String token) async {
    _tokens[userId] = token;
  }
}

void main() {
  late _FakeNotificationRepository repo;

  setUp(() {
    repo = _FakeNotificationRepository();
  });

  group('getPreferences', () {
    test('returns default preferences for new user', () async {
      final p = await repo.getPreferences('user-1');
      expect(p.reminder, isTrue);
      expect(p.streakAtRisk, isTrue);
    });

    test('returns updated preferences after updatePreferences', () async {
      const updated = NotificationPreferences(reminder: false);
      await repo.updatePreferences('user-1', updated);
      final p = await repo.getPreferences('user-1');
      expect(p.reminder, isFalse);
    });
  });

  group('updatePreferences', () {
    test('persists all fields', () async {
      const prefs = NotificationPreferences(
        reminder: false,
        streakAtRisk: false,
        milestone: true,
        partnerNudge: false,
        challengeUpdate: true,
        quietHours: QuietHours(start: 22, end: 7),
      );
      await repo.updatePreferences('user-1', prefs);
      final fetched = await repo.getPreferences('user-1');
      expect(fetched, equals(prefs));
    });

    test('does not affect other users', () async {
      await repo.updatePreferences(
        'user-1',
        const NotificationPreferences(reminder: false),
      );
      final p2 = await repo.getPreferences('user-2');
      expect(p2.reminder, isTrue); // default for user-2
    });
  });

  group('registerFCMToken', () {
    test('stores the token for the user', () async {
      await repo.registerFCMToken('user-1', 'token-abc');
      expect(repo._tokens['user-1'], 'token-abc');
    });

    test('overwrites stale token on refresh', () async {
      await repo.registerFCMToken('user-1', 'token-old');
      await repo.registerFCMToken('user-1', 'token-new');
      expect(repo._tokens['user-1'], 'token-new');
    });
  });
}
