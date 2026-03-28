import 'package:habit_coach/features/subscription/domain/entities/subscription.dart';

/// T032: SubscriptionRepository interface (domain layer — no RevenueCat imports).
///
/// The data layer implementation ([RevenueCatSubscriptionRepository]) maps
/// RevenueCat SDK responses to domain [Subscription] entities.
abstract interface class SubscriptionRepository {
  /// Returns the current subscription record for the authenticated user.
  Future<Subscription> getSubscription();

  /// Initiates the Pro subscription purchase flow via the store.
  /// Returns the updated [Subscription] on success.
  /// Throws [EntitlementFailure] if already Pro, [ServerFailure] on store error.
  Future<Subscription> purchasePro();

  /// Restores previous purchases (e.g., after reinstall).
  /// Returns the updated [Subscription].
  Future<Subscription> restorePurchases();

  /// Opens the store's subscription management page (cancellation is handled
  /// by the App Store / Play Store, not in-app).
  Future<void> manageSubscription();
}
