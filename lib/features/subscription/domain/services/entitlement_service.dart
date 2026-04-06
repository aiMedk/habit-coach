import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/core/constants/app_constants.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';

/// T031: EntitlementService — central gating point for all Pro-only features.
///
/// Constitution Principle IV: "All premium features MUST be gated exclusively
/// through a centralised EntitlementService in the domain layer."
///
/// No widget or use-case may query [SubscriptionTier] directly;
/// all checks go through this service.
abstract interface class EntitlementService {
  /// True if the current user has an active Pro subscription.
  bool get isPro;

  /// True if the user can create another habit (Pro: unlimited; Free: max 3).
  bool canAddHabit(int currentActiveHabitCount);

  /// True if the user can access AI coaching features (Pro only).
  bool get canAccessAI;

  /// True if the user can access accountability partner features (Pro only).
  bool get canAccessPartner;

  /// True if the user can access group challenge features (Pro only).
  bool get canAccessChallenge;
}

/// Implementation backed by the current [AppUser]'s [SubscriptionTier].
/// Provided via Riverpod so widgets stay reactive to subscription changes.
final class UserEntitlementService implements EntitlementService {
  const UserEntitlementService(this._user);
  final AppUser? _user;

  @override
  bool get isPro => _user?.isPro ?? false;

  @override
  bool canAddHabit(int currentActiveHabitCount) {
    if (isPro) return true;
    return currentActiveHabitCount < AppConstants.freeTierHabitLimit;
  }

  @override
  bool get canAccessAI => isPro;

  @override
  bool get canAccessPartner => isPro;

  @override
  bool get canAccessChallenge => isPro;
}

/// Riverpod provider for the entitlement service.
/// Re-evaluates whenever the current user's subscription tier changes.
final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  return UserEntitlementService(user);
});
