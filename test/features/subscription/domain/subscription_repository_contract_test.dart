import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart';
import 'package:habit_coach/features/subscription/domain/entities/subscription.dart';
import 'package:habit_coach/features/subscription/domain/repositories/subscription_repository.dart';

/// T183: SubscriptionRepository contract tests using a fake implementation.
/// Validates purchase, restore, and subscription state transitions.

class _FakeSubscriptionRepository implements SubscriptionRepository {
  Subscription _current = Subscription(
    id: 'sub-1',
    userId: 'user-1',
    tier: SubscriptionTier.free,
    status: SubscriptionStatus.active,
    platform: Platform.ios,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );

  bool throwOnPurchase = false;

  @override
  Future<Subscription> getSubscription() async => _current;

  @override
  Future<Subscription> purchasePro() async {
    if (throwOnPurchase) throw Exception('Purchase failed');
    _current = Subscription(
      id: _current.id,
      userId: _current.userId,
      tier: SubscriptionTier.pro,
      status: SubscriptionStatus.active,
      platform: _current.platform,
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      createdAt: _current.createdAt,
      updatedAt: DateTime.now(),
    );
    return _current;
  }

  @override
  Future<Subscription> restorePurchases() async {
    // Same as purchase in this fake
    return purchasePro();
  }

  @override
  Future<void> manageSubscription() async {}
}

void main() {
  late _FakeSubscriptionRepository repo;

  setUp(() {
    repo = _FakeSubscriptionRepository();
  });

  group('getSubscription', () {
    test('returns current subscription', () async {
      final sub = await repo.getSubscription();
      expect(sub.tier, SubscriptionTier.free);
      expect(sub.isPro, isFalse);
    });
  });

  group('purchasePro', () {
    test('upgrades subscription to Pro', () async {
      final sub = await repo.purchasePro();
      expect(sub.tier, SubscriptionTier.pro);
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.isPro, isTrue);
    });

    test('throws on purchase failure', () async {
      repo.throwOnPurchase = true;
      await expectLater(repo.purchasePro, throwsA(isA<Exception>()));
    });

    test('getSubscription reflects purchase after purchasePro', () async {
      await repo.purchasePro();
      final sub = await repo.getSubscription();
      expect(sub.isPro, isTrue);
    });
  });

  group('restorePurchases', () {
    test('restores Pro entitlement', () async {
      final sub = await repo.restorePurchases();
      expect(sub.isPro, isTrue);
    });
  });

  group('Subscription entity', () {
    test('isPro is true when tier=pro and status=active', () {
      final sub = Subscription(
        id: 'x',
        userId: 'u',
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.active,
        platform: Platform.ios,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      expect(sub.isPro, isTrue);
    });

    test('isPro is false when status=cancelled', () {
      final sub = Subscription(
        id: 'x',
        userId: 'u',
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.cancelled,
        platform: Platform.ios,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      expect(sub.isPro, isFalse);
    });

    test('isExpired returns true for past expiresAt', () {
      final sub = Subscription(
        id: 'x',
        userId: 'u',
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.expired,
        platform: Platform.ios,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      expect(sub.isExpired, isTrue);
    });
  });
}
