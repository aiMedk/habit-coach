import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/accountability/data/repositories/supabase_partner_repository.dart';
import 'package:habit_coach/features/accountability/domain/entities/partnership.dart';
import 'package:habit_coach/features/accountability/domain/repositories/partner_repository.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/settings/data/repositories/supabase_block_repository.dart';
import 'package:habit_coach/features/settings/domain/entities/blocked_user.dart';
import 'package:habit_coach/features/settings/domain/repositories/block_repository.dart';

/// T083: Accountability feature Riverpod providers.

final partnerRepositoryProvider = Provider<PartnerRepository>(
  (ref) => SupabasePartnerRepository(),
);

final blockRepositoryProvider = Provider<BlockRepository>(
  (ref) => SupabaseBlockRepository(),
);

/// The current user's active or pending partnership.
final partnershipProvider = FutureProvider<Partnership?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  return ref.watch(partnerRepositoryProvider).getPartnership(user.id);
});

/// The partner's streak summary for the shared dashboard.
final partnerStreaksProvider = FutureProvider<PartnerStreakSummary?>((
  ref,
) async {
  final partnership = await ref.watch(partnershipProvider.future);
  if (partnership == null || !partnership.isActive) return null;
  return ref.watch(partnerRepositoryProvider).getPartnerStreaks(partnership.id);
});

/// List of users blocked by the current user.
final blockedUsersProvider = FutureProvider<List<BlockedUser>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.watch(blockRepositoryProvider).getBlockedUsers(user.id);
});

// ── Invite flow state ─────────────────────────────────────────────────────────

class InviteState {
  const InviteState({this.partnership, this.isLoading = false, this.error});

  final Partnership? partnership;
  final bool isLoading;
  final String? error;

  InviteState copyWith({
    Partnership? partnership,
    bool? isLoading,
    String? error,
  }) => InviteState(
    partnership: partnership ?? this.partnership,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class InviteNotifier extends StateNotifier<InviteState> {
  InviteNotifier(this._repo, this._userId) : super(const InviteState());

  final PartnerRepository _repo;
  final String _userId;

  Future<void> createInvite() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final partnership = await _repo.invitePartner(_userId);
      state = state.copyWith(partnership: partnership, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> dissolve(String partnershipId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.dissolvePartnership(partnershipId);
      state = const InviteState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final inviteNotifierProvider = StateNotifierProvider.autoDispose<
  InviteNotifier,
  InviteState
>((ref) {
  final repo = ref.watch(partnerRepositoryProvider);
  // Provide a placeholder userId — resolved in the screen from currentUserProvider
  return InviteNotifier(repo, '');
});
