import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/core/constants/app_constants.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart'
    show AppUser, DeletionStatus, NotificationPreferences, SubscriptionTier;
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

void main() {
  AppUser makeUser(SubscriptionTier tier) => AppUser(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'Test User',
    timezone: 'UTC',
    subscriptionTier: tier,
    notificationPreferences: const NotificationPreferences(),
    deletionStatus: DeletionStatus.active,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );

  group('UserEntitlementService — free tier', () {
    late EntitlementService svc;

    setUp(() {
      svc = UserEntitlementService(makeUser(SubscriptionTier.free));
    });

    test('isPro returns false', () => expect(svc.isPro, isFalse));
    test('canAccessAI returns false', () => expect(svc.canAccessAI, isFalse));
    test(
      'canAccessPartner returns false',
      () => expect(svc.canAccessPartner, isFalse),
    );
    test(
      'canAccessChallenge returns false',
      () => expect(svc.canAccessChallenge, isFalse),
    );

    test('canAddHabit allows up to free tier limit', () {
      for (var i = 0; i < AppConstants.freeTierHabitLimit; i++) {
        expect(
          svc.canAddHabit(i),
          isTrue,
          reason: 'should allow $i habits on free tier',
        );
      }
    });

    test('canAddHabit blocks at free tier limit', () {
      expect(svc.canAddHabit(AppConstants.freeTierHabitLimit), isFalse);
    });
  });

  group('UserEntitlementService — pro tier', () {
    late EntitlementService svc;

    setUp(() {
      svc = UserEntitlementService(makeUser(SubscriptionTier.pro));
    });

    test('isPro returns true', () => expect(svc.isPro, isTrue));
    test('canAccessAI returns true', () => expect(svc.canAccessAI, isTrue));
    test(
      'canAccessPartner returns true',
      () => expect(svc.canAccessPartner, isTrue),
    );
    test(
      'canAccessChallenge returns true',
      () => expect(svc.canAccessChallenge, isTrue),
    );

    test('canAddHabit allows unlimited habits', () {
      expect(svc.canAddHabit(100), isTrue);
    });
  });

  group('UserEntitlementService — null user (logged out)', () {
    late EntitlementService svc;

    setUp(() {
      svc = UserEntitlementService(null);
    });

    test('isPro returns false', () => expect(svc.isPro, isFalse));
    test(
      'canAddHabit(0) returns true',
      () => expect(svc.canAddHabit(0), isTrue),
    );
    test(
      'canAddHabit(free limit) returns false',
      () => expect(svc.canAddHabit(AppConstants.freeTierHabitLimit), isFalse),
    );
  });
}
