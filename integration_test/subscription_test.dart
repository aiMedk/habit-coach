import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/core/constants/app_constants.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart'
    show AppUser, DeletionStatus, NotificationPreferences, SubscriptionTier;
import 'package:habit_coach/features/subscription/domain/entities/subscription.dart';
import 'package:habit_coach/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';
import 'package:integration_test/integration_test.dart';

/// T184: Subscription integration smoke tests.
///
/// Tests run in isolation (no RevenueCat / Supabase).
/// Validates the end-to-end subscription lifecycle using in-memory fakes.

class _InMemorySubscriptionRepository implements SubscriptionRepository {
  SubscriptionTier _tier = SubscriptionTier.free;
  SubscriptionStatus _status = SubscriptionStatus.active;

  @override
  Future<Subscription> getSubscription() async => Subscription(
    id: 'sub-1',
    userId: 'user-1',
    tier: _tier,
    status: _status,
    platform: Platform.ios,
    createdAt: DateTime(2025),
    updatedAt: DateTime.now(),
  );

  @override
  Future<Subscription> purchasePro() async {
    _tier = SubscriptionTier.pro;
    _status = SubscriptionStatus.active;
    return getSubscription();
  }

  @override
  Future<Subscription> restorePurchases() async => purchasePro();

  @override
  Future<void> manageSubscription() async {}

  void simulateExpiry() {
    _tier = SubscriptionTier.free;
    _status = SubscriptionStatus.expired;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _InMemorySubscriptionRepository repo;

  setUp(() {
    repo = _InMemorySubscriptionRepository();
  });

  testWidgets('US9 smoke: free user starts without Pro', (tester) async {
    final sub = await repo.getSubscription();
    expect(sub.isPro, isFalse);
    expect(sub.tier, SubscriptionTier.free);

    final svc = UserEntitlementService(
      AppUser(
        id: 'user-1',
        email: 'test@example.com',
        displayName: 'Test',
        timezone: 'UTC',
        subscriptionTier: SubscriptionTier.free,
        notificationPreferences: const NotificationPreferences(),
        deletionStatus: DeletionStatus.active,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      ),
    );
    expect(svc.canAccessAI, isFalse);
    expect(svc.canAccessPartner, isFalse);
    expect(svc.canAddHabit(AppConstants.freeTierHabitLimit), isFalse);
  });

  testWidgets('US9 smoke: purchase unlocks Pro features', (tester) async {
    final sub = await repo.purchasePro();
    expect(sub.isPro, isTrue);

    final svc = UserEntitlementService(
      AppUser(
        id: 'user-1',
        email: 'test@example.com',
        displayName: 'Test',
        timezone: 'UTC',
        subscriptionTier: SubscriptionTier.pro,
        notificationPreferences: const NotificationPreferences(),
        deletionStatus: DeletionStatus.active,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      ),
    );
    expect(svc.isPro, isTrue);
    expect(svc.canAccessAI, isTrue);
    expect(svc.canAccessPartner, isTrue);
    expect(svc.canAccessChallenge, isTrue);
    expect(svc.canAddHabit(100), isTrue);
  });

  testWidgets('US9 smoke: restore purchases re-activates Pro', (tester) async {
    final sub = await repo.restorePurchases();
    expect(sub.isPro, isTrue);
  });

  testWidgets('US9 smoke: downgrade reverts features', (tester) async {
    await repo.purchasePro();
    repo.simulateExpiry();

    final sub = await repo.getSubscription();
    expect(sub.isPro, isFalse);
    expect(sub.tier, SubscriptionTier.free);
    expect(sub.status, SubscriptionStatus.expired);

    final svc = UserEntitlementService(
      AppUser(
        id: 'user-1',
        email: 'test@example.com',
        displayName: 'Test',
        timezone: 'UTC',
        subscriptionTier: SubscriptionTier.free,
        notificationPreferences: const NotificationPreferences(),
        deletionStatus: DeletionStatus.active,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      ),
    );
    expect(svc.canAccessAI, isFalse);
    expect(svc.canAddHabit(AppConstants.freeTierHabitLimit), isFalse);
  });
}
