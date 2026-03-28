import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/notifications/domain/entities/notification_preferences.dart';

void main() {
  group('QuietHours', () {
    test('disabled() has isEnabled = false', () {
      const q = QuietHours.disabled();
      expect(q.isEnabled, isFalse);
    });

    test('contains() always returns false when disabled', () {
      const q = QuietHours.disabled();
      for (var h = 0; h < 24; h++) {
        expect(q.contains(h), isFalse);
      }
    });

    test('contains() with simple range (22→7) wraps midnight', () {
      const q = QuietHours(start: 22, end: 7);
      expect(q.contains(22), isTrue);
      expect(q.contains(0), isTrue);
      expect(q.contains(6), isTrue);
      expect(q.contains(7), isFalse);
      expect(q.contains(12), isFalse);
    });

    test('contains() with non-wrapping range (8→20)', () {
      const q = QuietHours(start: 8, end: 20);
      expect(q.contains(8), isTrue);
      expect(q.contains(15), isTrue);
      expect(q.contains(20), isFalse);
      expect(q.contains(7), isFalse);
    });

    test('toJson / fromJson round-trip', () {
      const q = QuietHours(start: 22, end: 7);
      final q2 = QuietHours.fromJson(q.toJson());
      expect(q2, equals(q));
    });

    test('equality', () {
      expect(
        const QuietHours(start: 22, end: 7),
        equals(const QuietHours(start: 22, end: 7)),
      );
      expect(
        const QuietHours(start: 22, end: 7),
        isNot(equals(const QuietHours(start: 23, end: 7))),
      );
    });
  });

  group('NotificationPreferences', () {
    test('default constructor enables all types', () {
      const p = NotificationPreferences();
      expect(p.reminder, isTrue);
      expect(p.streakAtRisk, isTrue);
      expect(p.milestone, isTrue);
      expect(p.partnerNudge, isTrue);
      expect(p.challengeUpdate, isTrue);
      expect(p.quietHours.isEnabled, isFalse);
    });

    test('isEnabled returns correct value per type', () {
      const p = NotificationPreferences(reminder: false, milestone: false);
      expect(p.isEnabled(NotificationType.reminder), isFalse);
      expect(p.isEnabled(NotificationType.milestone), isFalse);
      expect(p.isEnabled(NotificationType.streakAtRisk), isTrue);
    });

    test('copyWith overrides individual fields', () {
      const p = NotificationPreferences();
      final p2 = p.copyWith(reminder: false);
      expect(p2.reminder, isFalse);
      expect(p2.streakAtRisk, isTrue); // unchanged
    });

    test('toJson / fromJson round-trip', () {
      const p = NotificationPreferences(
        reminder: false,
        streakAtRisk: true,
        milestone: false,
        partnerNudge: true,
        challengeUpdate: false,
        quietHours: QuietHours(start: 22, end: 7),
      );
      final p2 = NotificationPreferences.fromJson(p.toJson());
      expect(p2, equals(p));
    });

    test('fromJson defaults all to true when keys absent', () {
      final p = NotificationPreferences.fromJson({});
      expect(p.reminder, isTrue);
      expect(p.streakAtRisk, isTrue);
      expect(p.milestone, isTrue);
      expect(p.partnerNudge, isTrue);
      expect(p.challengeUpdate, isTrue);
    });

    test('equality is field-based', () {
      const p1 = NotificationPreferences();
      const p2 = NotificationPreferences();
      expect(p1, equals(p2));

      final p3 = p1.copyWith(reminder: false);
      expect(p1, isNot(equals(p3)));
    });
  });
}
