// T154: Auth domain unit tests — User entity and AuthRepository contract.
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart';

void main() {
  group('AppUser', () {
    late AppUser user;

    setUp(() {
      user = AppUser(
        id: 'user-1',
        email: 'test@example.com',
        displayName: 'Test User',
        timezone: 'UTC',
        subscriptionTier: SubscriptionTier.free,
        notificationPreferences: NotificationPreferences.allEnabled,
        deletionStatus: DeletionStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    });

    test('isPro returns false for free tier', () {
      expect(user.isPro, isFalse);
    });

    test('isPro returns true for pro tier', () {
      final proUser = user.copyWith(subscriptionTier: SubscriptionTier.pro);
      expect(proUser.isPro, isTrue);
    });

    test('isPendingDeletion reflects deletion status', () {
      expect(user.isPendingDeletion, isFalse);
      final pendingUser = user.copyWith(
        deletionStatus: DeletionStatus.pendingDeletion,
      );
      expect(pendingUser.isPendingDeletion, isTrue);
    });

    test('copyWith preserves immutable id and email', () {
      final updated = user.copyWith(displayName: 'New Name');
      expect(updated.id, equals(user.id));
      expect(updated.email, equals(user.email));
      expect(updated.displayName, equals('New Name'));
    });

    test('equality is based on id', () {
      final sameId = AppUser(
        id: 'user-1',
        email: 'other@example.com',
        displayName: 'Other',
        timezone: 'UTC',
        subscriptionTier: SubscriptionTier.pro,
        notificationPreferences: NotificationPreferences.allEnabled,
        deletionStatus: DeletionStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(user, equals(sameId));
      expect(user.hashCode, equals(sameId.hashCode));
    });
  });

  group('NotificationPreferences', () {
    test('allEnabled has all preferences true', () {
      const prefs = NotificationPreferences.allEnabled;
      expect(prefs.reminder, isTrue);
      expect(prefs.streakAtRisk, isTrue);
      expect(prefs.milestone, isTrue);
      expect(prefs.partnerNudge, isTrue);
      expect(prefs.challengeUpdate, isTrue);
    });

    test('fromJson/toJson round-trip', () {
      const prefs = NotificationPreferences(
        reminder: true,
        streakAtRisk: false,
        milestone: true,
        partnerNudge: false,
        challengeUpdate: true,
      );
      final json = prefs.toJson();
      final restored = NotificationPreferences.fromJson(json);
      expect(restored.reminder, equals(prefs.reminder));
      expect(restored.streakAtRisk, equals(prefs.streakAtRisk));
      expect(restored.milestone, equals(prefs.milestone));
      expect(restored.partnerNudge, equals(prefs.partnerNudge));
      expect(restored.challengeUpdate, equals(prefs.challengeUpdate));
    });

    test('fromJson defaults to true for missing keys', () {
      final restored = NotificationPreferences.fromJson({});
      expect(restored.reminder, isTrue);
      expect(restored.streakAtRisk, isTrue);
    });

    test('copyWith changes only specified fields', () {
      const original = NotificationPreferences.allEnabled;
      final updated = original.copyWith(streakAtRisk: false);
      expect(updated.streakAtRisk, isFalse);
      expect(updated.reminder, isTrue);
    });
  });
}
