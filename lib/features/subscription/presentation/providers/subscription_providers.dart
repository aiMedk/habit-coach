import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/subscription/data/repositories/revenuecat_subscription_repository.dart';
import 'package:habit_coach/features/subscription/domain/entities/subscription.dart';
import 'package:habit_coach/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

/// T131 / T132: Subscription Riverpod providers.

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (_) => RevenueCatSubscriptionRepository(),
);

/// The current subscription record.
final subscriptionStateProvider = FutureProvider<Subscription>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return Subscription(
      id: '',
      userId: '',
      tier: SubscriptionTier.free,
      status: SubscriptionStatus.active,
      platform: Platform.ios,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  return ref.watch(subscriptionRepositoryProvider).getSubscription();
});

/// T131: Reactive entitlement provider backed by RevenueCat CustomerInfo.
///
/// Uses addCustomerInfoUpdateListener so entitlement state updates
/// immediately on purchase/restore without polling Supabase.
final revenueCatEntitlementProvider = StreamProvider<bool>((ref) async* {
  // Yield the initial value.
  try {
    final info = await rc.Purchases.getCustomerInfo();
    yield info.entitlements.active.containsKey('pro');
  } catch (_) {
    yield false;
  }

  // Then react to listener callbacks.
  final controller = StreamController<bool>.broadcast();
  rc.Purchases.addCustomerInfoUpdateListener((info) {
    if (!controller.isClosed) {
      controller.add(info.entitlements.active.containsKey('pro'));
    }
  });
  ref.onDispose(controller.close);
  yield* controller.stream;
});

/// Available paywall packages from RevenueCat.
final paywallProductsProvider = FutureProvider<List<rc.Package>>((ref) async {
  final offerings = await rc.Purchases.getOfferings();
  return offerings.current?.availablePackages ?? [];
});

// ── Purchase notifier ─────────────────────────────────────────────────────────

class PurchaseNotifier extends StateNotifier<AsyncValue<Subscription?>> {
  PurchaseNotifier(this._repo) : super(const AsyncValue.data(null));

  final SubscriptionRepository _repo;

  Future<void> purchasePro() async {
    state = const AsyncValue.loading();
    try {
      final sub = await _repo.purchasePro();
      state = AsyncValue.data(sub);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      final sub = await _repo.restorePurchases();
      state = AsyncValue.data(sub);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final purchaseProvider = StateNotifierProvider.autoDispose<
  PurchaseNotifier,
  AsyncValue<Subscription?>
>((ref) {
  return PurchaseNotifier(ref.watch(subscriptionRepositoryProvider));
});

/// Re-export entitlement service using the reactive RevenueCat stream as the
/// Pro check source, falling back to the Supabase-backed user record.
final reactiveEntitlementProvider = Provider<EntitlementService>((ref) {
  // Prefer the RevenueCat stream value; fall back to user's stored tier.
  final rcPro = ref.watch(revenueCatEntitlementProvider).valueOrNull;
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;

  // If RevenueCat stream has a value, use it; otherwise fall back to stored tier.
  final isPro = rcPro ?? user?.isPro ?? false;
  return _ReactivEntitlementService(isPro: isPro);
});

final class _ReactivEntitlementService implements EntitlementService {
  const _ReactivEntitlementService({required bool isPro}) : _isPro = isPro;
  final bool _isPro;

  @override
  bool get isPro => _isPro;

  @override
  bool canAddHabit(int currentActiveHabitCount) =>
      _isPro || currentActiveHabitCount < 3;

  @override
  bool get canAccessAI => _isPro;

  @override
  bool get canAccessPartner => _isPro;

  @override
  bool get canAccessChallenge => _isPro;
}
