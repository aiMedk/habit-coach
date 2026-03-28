import 'dart:io' as io;
import 'package:habit_coach/features/auth/domain/entities/user.dart';
import 'package:habit_coach/features/subscription/domain/entities/subscription.dart';
import 'package:habit_coach/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// T130: RevenueCat implementation of SubscriptionRepository.
///
/// Purchases are made via the RevenueCat SDK (purchases_flutter).
/// The canonical subscription record lives in Supabase (written by the
/// revenuecat-webhook Edge Function). This class treats RevenueCat as the
/// source-of-truth for entitlement state and Supabase as the record store.
class RevenueCatSubscriptionRepository implements SubscriptionRepository {
  SupabaseClient get _client => Supabase.instance.client;

  static const _proEntitlement = 'pro';

  @override
  Future<Subscription> getSubscription() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final row =
        await _client
            .from('subscriptions')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    if (row == null) {
      // No record yet — return a default free subscription.
      return Subscription(
        id: '',
        userId: userId,
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.active,
        platform: Platform.ios,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return _fromRow(row);
  }

  @override
  Future<Subscription> purchasePro() async {
    // Fetch available packages in the 'default' offering.
    final offerings = await rc.Purchases.getOfferings();
    final package = offerings.current?.availablePackages.firstOrNull;
    if (package == null) throw Exception('No packages available');

    final result = await rc.Purchases.purchasePackage(package);
    return _subscriptionFromCustomerInfo(result.customerInfo);
  }

  @override
  Future<Subscription> restorePurchases() async {
    final customerInfo = await rc.Purchases.restorePurchases();
    return _subscriptionFromCustomerInfo(customerInfo);
  }

  @override
  Future<void> manageSubscription() async {
    // Link to the App Store / Play Store subscription management page.
    final url =
        io.Platform.isIOS
            ? 'https://apps.apple.com/account/subscriptions'
            : 'https://play.google.com/store/account/subscriptions';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Subscription _subscriptionFromCustomerInfo(rc.CustomerInfo info) {
    final entitlement = info.entitlements.active[_proEntitlement];
    final userId = _client.auth.currentUser?.id ?? '';
    final isPro = entitlement != null && entitlement.isActive;

    return Subscription(
      id: '',
      userId: userId,
      tier: isPro ? SubscriptionTier.pro : SubscriptionTier.free,
      status: isPro ? SubscriptionStatus.active : SubscriptionStatus.expired,
      platform: io.Platform.isIOS ? Platform.ios : Platform.android,
      revenuecatId: info.originalAppUserId,
      expiresAt:
          entitlement?.expirationDate != null
              ? DateTime.tryParse(entitlement!.expirationDate!)
              : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Subscription _fromRow(Map<String, dynamic> r) => Subscription(
    id: r['id'] as String,
    userId: r['user_id'] as String,
    tier: SubscriptionTier.values.byName(r['tier'] as String),
    status: SubscriptionStatus.values.byName(r['status'] as String),
    platform: Platform.values.byName(r['platform'] as String),
    revenuecatId: r['revenuecat_id'] as String?,
    startedAt:
        r['started_at'] != null
            ? DateTime.parse(r['started_at'] as String)
            : null,
    expiresAt:
        r['expires_at'] != null
            ? DateTime.parse(r['expires_at'] as String)
            : null,
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );
}
