import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/weekly_review/data/repositories/supabase_review_repository.dart';
import 'package:habit_coach/features/weekly_review/domain/entities/weekly_review.dart';
import 'package:habit_coach/features/weekly_review/domain/repositories/review_repository.dart';

/// T115: Weekly review Riverpod providers.

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => SupabaseReviewRepository(),
);

/// All non-expired reviews for the current user, most recent first.
final reviewHistoryProvider = FutureProvider<List<WeeklyReview>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.watch(reviewRepositoryProvider).getReviewHistory(user.id);
});

/// The most recent review, or null if none exists.
final latestReviewProvider = FutureProvider<WeeklyReview?>((ref) async {
  final history = await ref.watch(reviewHistoryProvider.future);
  return history.isNotEmpty ? history.first : null;
});

// ── Generate review notifier ──────────────────────────────────────────────────

class GenerateReviewState {
  const GenerateReviewState({this.isLoading = false, this.error, this.review});

  final bool isLoading;
  final String? error;
  final WeeklyReview? review;

  GenerateReviewState copyWith({
    bool? isLoading,
    String? error,
    WeeklyReview? review,
  }) => GenerateReviewState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    review: review ?? this.review,
  );
}

class GenerateReviewNotifier extends StateNotifier<GenerateReviewState> {
  GenerateReviewNotifier(this._repo, this._ref)
    : super(const GenerateReviewState());

  final ReviewRepository _repo;
  final Ref _ref;

  Future<void> generate({
    required String userId,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final review = await _repo.generateReview(
        userId: userId,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
      state = state.copyWith(isLoading: false, review: review);
      _ref.invalidate(reviewHistoryProvider);
      _ref.invalidate(latestReviewProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final generateReviewProvider = StateNotifierProvider.autoDispose<
  GenerateReviewNotifier,
  GenerateReviewState
>((ref) {
  return GenerateReviewNotifier(ref.watch(reviewRepositoryProvider), ref);
});
