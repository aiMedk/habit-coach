import 'package:habit_coach/features/weekly_review/domain/entities/weekly_review.dart';

/// T111: ReviewRepository interface — domain layer, no Supabase imports.
abstract interface class ReviewRepository {
  /// Triggers AI generation for the given week. Returns the saved review.
  ///
  /// Throws if user is not Pro, has <7 days of completion data, or the AI
  /// service is unavailable after retry.
  Future<WeeklyReview> generateReview({
    required String userId,
    required DateTime weekStart,
    required DateTime weekEnd,
  });

  /// Returns a saved review by ID, or null if not found / expired.
  Future<WeeklyReview?> getReview(String reviewId);

  /// Returns all non-expired reviews for [userId], most recent first.
  Future<List<WeeklyReview>> getReviewHistory(String userId);
}
