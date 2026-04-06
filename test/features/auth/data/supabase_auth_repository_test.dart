// T155: Auth data layer unit tests — SupabaseAuthRepository mapping.
// These tests validate the mapping logic and error translation without
// hitting a live Supabase instance.
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart';

void main() {
  // Row as returned from Supabase public.users
  final fullRow = <String, dynamic>{
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

  group('SupabaseAuthRepository.mapToAppUser', () {
    test('correctly maps a free user row', () {
      final user = SupabaseAuthRepository.mapToAppUser(fullRow);
      expect(user.id, 'user-abc');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.timezone, 'America/New_York');
      expect(user.subscriptionTier, SubscriptionTier.free);
      expect(user.notificationPreferences.reminder, isTrue);
      expect(user.notificationPreferences.streakAtRisk, isFalse);
      expect(user.deletionStatus, DeletionStatus.active);
      expect(user.deletionRequestedAt, isNull);
      expect(user.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
    });

    test('correctly maps a pro user row', () {
      final row = Map<String, dynamic>.from(fullRow)
        ..['subscription_tier'] = 'pro';
      final user = SupabaseAuthRepository.mapToAppUser(row);
      expect(user.subscriptionTier, SubscriptionTier.pro);
    });

    test('defaults timezone to UTC when null', () {
      final row = Map<String, dynamic>.from(fullRow)..['timezone'] = null;
      final user = SupabaseAuthRepository.mapToAppUser(row);
      expect(user.timezone, 'UTC');
    });

    test('maps pending_deletion status correctly', () {
      final row =
          Map<String, dynamic>.from(fullRow)
            ..['deletion_status'] = 'pending_deletion'
            ..['deletion_requested_at'] = '2026-03-01T00:00:00.000Z';
      final user = SupabaseAuthRepository.mapToAppUser(row);
      expect(user.deletionStatus, DeletionStatus.pendingDeletion);
      expect(
        user.deletionRequestedAt,
        DateTime.parse('2026-03-01T00:00:00.000Z'),
      );
    });

    test('uses NotificationPreferences.allEnabled when field is null', () {
      final row = Map<String, dynamic>.from(fullRow)
        ..['notification_preferences'] = null;
      final user = SupabaseAuthRepository.mapToAppUser(row);
      expect(user.notificationPreferences.reminder, isTrue);
      expect(user.notificationPreferences.partnerNudge, isTrue);
    });
  });

  group('NotificationPreferences.fromJson', () {
    test('handles missing pro-only keys by defaulting to true', () {
      final prefs = NotificationPreferences.fromJson({'reminder': false});
      expect(prefs.reminder, isFalse);
      expect(prefs.streakAtRisk, isTrue);
      expect(prefs.partnerNudge, isTrue);
    });

    test('round-trips through toJson', () {
      final original = const NotificationPreferences(
        reminder: false,
        streakAtRisk: true,
        milestone: false,
        partnerNudge: true,
        challengeUpdate: false,
      );
      final restored = NotificationPreferences.fromJson(original.toJson());
      expect(restored.reminder, isFalse);
      expect(restored.streakAtRisk, isTrue);
      expect(restored.milestone, isFalse);
      expect(restored.partnerNudge, isTrue);
      expect(restored.challengeUpdate, isFalse);
    });
  });
}
