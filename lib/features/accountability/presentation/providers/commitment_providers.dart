import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/accountability/data/repositories/supabase_commitment_repository.dart';
import 'package:habit_coach/features/accountability/domain/entities/commitment.dart';
import 'package:habit_coach/features/accountability/domain/repositories/commitment_repository.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';

/// T094: Commitment feature Riverpod providers.

final commitmentRepositoryProvider = Provider<CommitmentRepository>(
  (ref) => SupabaseCommitmentRepository(),
);

/// Active commitments made by the current user.
final activeCommitmentsProvider = FutureProvider<List<Commitment>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.watch(commitmentRepositoryProvider).getActiveCommitments(user.id);
});

/// Commitments the current user's partner made (visible on shared dashboard).
final partnerCommitmentsProvider = FutureProvider<List<Commitment>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref
      .watch(commitmentRepositoryProvider)
      .getCommitmentsForPartner(user.id);
});

// ── Create commitment notifier ────────────────────────────────────────────────

class CreateCommitmentState {
  const CreateCommitmentState({
    this.isLoading = false,
    this.error,
    this.created,
  });

  final bool isLoading;
  final String? error;
  final Commitment? created;

  CreateCommitmentState copyWith({
    bool? isLoading,
    String? error,
    Commitment? created,
  }) => CreateCommitmentState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    created: created ?? this.created,
  );
}

class CreateCommitmentNotifier extends StateNotifier<CreateCommitmentState> {
  CreateCommitmentNotifier(this._repo, this._ref)
    : super(const CreateCommitmentState());

  final CommitmentRepository _repo;
  final Ref _ref;

  Future<void> create({
    required String userId,
    required String partnerId,
    required String habitId,
    required String habitName,
    required int targetStreak,
    required DateTime deadline,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final commitment = await _repo.createCommitment(
        userId: userId,
        partnerId: partnerId,
        habitId: habitId,
        habitName: habitName,
        targetStreak: targetStreak,
        deadline: deadline,
      );
      state = state.copyWith(isLoading: false, created: commitment);
      _ref.invalidate(activeCommitmentsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final createCommitmentProvider = StateNotifierProvider.autoDispose<
  CreateCommitmentNotifier,
  CreateCommitmentState
>((ref) {
  return CreateCommitmentNotifier(ref.watch(commitmentRepositoryProvider), ref);
});

/// Convenience provider: active count guard (true when limit reached).
final commitmentLimitReachedProvider = FutureProvider<bool>((ref) async {
  final commitments = await ref.watch(activeCommitmentsProvider.future);
  return commitments.length >= 3;
});

/// Computes commitment progress snapshot from the partner's active partnership.
final partnershipCommitmentsProvider =
    FutureProvider<({List<Commitment> mine, List<Commitment> theirs})>((
      ref,
    ) async {
      final mine = await ref.watch(activeCommitmentsProvider.future);
      final partnership = await ref.watch(partnershipProvider.future);
      if (partnership == null || !partnership.isActive) {
        return (mine: mine, theirs: <Commitment>[]);
      }
      final theirs = await ref.watch(partnerCommitmentsProvider.future);
      return (mine: mine, theirs: theirs);
    });
