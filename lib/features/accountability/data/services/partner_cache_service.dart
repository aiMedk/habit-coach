import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';

/// T167: PartnerCacheService — invalidates partnership-related providers
/// when a partnership is dissolved or a partner account is deleted.
///
/// Call [onPartnershipDissolved] after any dissolve / block operation so
/// stale data (streaks, dashboard) is cleared from the Riverpod cache.
class PartnerCacheService {
  const PartnerCacheService(this._ref);

  final Ref _ref;

  /// Clears all partnership and streak providers from the Riverpod cache.
  void onPartnershipDissolved() {
    _ref.invalidate(partnershipProvider);
    _ref.invalidate(partnerStreaksProvider);
  }

  /// Clears partner data and the block list when a user is blocked
  /// (which also dissolves the partnership).
  void onUserBlocked() {
    onPartnershipDissolved();
    _ref.invalidate(blockedUsersProvider);
  }
}

final partnerCacheServiceProvider = Provider<PartnerCacheService>(
  (ref) => PartnerCacheService(ref),
);
