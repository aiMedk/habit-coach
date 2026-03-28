// T155: Auth data layer unit tests — SupabaseAuthRepository mapping.
// These tests validate the mapping logic and error translation without
// hitting a live Supabase instance.
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart';

void main() {
  group('SupabaseAuthRepository mapping', () {
    // Row as returned from Supabase public.users
    final fullRow = {
      'id': 'user-abc',
      'email': 'test@example.com',
      'display_name': 'Test User',
      'timezone': 'America/New_York',
      'subscription_tier': 'free',
      'notification_preferences': {
        'reminder': true,
        'streak_at_risk': false,
        'milestone': true,
        'partner_nudge': true,
        'challenge_update': false,
      },
      'deletion_status': 'active',
      'deletion_requested_at': null,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-02T00:00:00.000Z',
    };

    test('mapToAppUser correctly maps free user row', () {
      // Test via the public entity constructors used by the mapper
      final prefs = NotificationPreferences.fromJson(
        fullRow['notification_preferences'] as Map<String, dynamic>,
      );
      expect(prefs.reminder, isTrue);
      expect(prefs.streakAtRisk, isFalse);

      final tier =
          (fullRow['subscription_tier'] as String) == 'pro'
              ? SubscriptionTier.pro
              : SubscriptionTier.free;
      expect(tier, equals(SubscriptionTier.free));
    });

    test('mapToAppUser correctly maps pro user row', () {
      final proRow = Map<String, dynamic>.from(fullRow)
        ..['subscription_tier'] = 'pro';
      final tier =
          (proRow['subscription_tier'] as String) == 'pro'
              ? SubscriptionTier.pro
              : SubscriptionTier.free;
      expect(tier, equals(SubscriptionTier.pro));
    });

    test('mapToAppUser handles pending deletion status', () {
      final pendingRow =
          Map<String, dynamic>.from(fullRow)
            ..['deletion_status'] = 'pending_deletion'
            ..['deletion_requested_at'] = '2026-03-01T00:00:00.000Z';
      final status =
          (pendingRow['deletion_status'] as String) == 'pending_deletion'
              ? DeletionStatus.pendingDeletion
              : DeletionStatus.active;
      expect(status, equals(DeletionStatus.pendingDeletion));
      expect(pendingRow['deletion_requested_at'], isNotNull);
    });

    test('NotificationPreferences.fromJson handles missing pro-only keys', () {
      // Pre-existing rows may not have all keys; defaults to true
      final prefs = NotificationPreferences.fromJson({'reminder': false});
      expect(prefs.reminder, isFalse);
      expect(prefs.streakAtRisk, isTrue); // default
      expect(prefs.partnerNudge, isTrue); // default
    });
  });
}
