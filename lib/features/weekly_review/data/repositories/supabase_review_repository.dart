import 'package:habit_coach/features/weekly_review/domain/entities/weekly_review.dart';
import 'package:habit_coach/features/weekly_review/domain/repositories/review_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// T113: Supabase implementation of ReviewRepository.
/// Calls the ai-weekly-review Edge Function for generation,
/// and reads weekly_reviews directly for history.
class SupabaseReviewRepository implements ReviewRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<WeeklyReview> generateReview({
    required String userId,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    final weekStartStr = _dateStr(weekStart);
    final weekEndStr = _dateStr(weekEnd);

    final response = await _client.functions.invoke(
      'ai-weekly-review',
      body: {'week_start': weekStartStr, 'week_end': weekEndStr},
    );

    if (response.status == 403) {
      throw Exception('Pro tier required for weekly reviews');
    }
    if (response.status == 422) {
      throw Exception(
        'Not enough data — complete habits for at least 7 days first',
      );
    }
    if (response.status != 200) {
      throw Exception('Weekly review generation failed (${response.status})');
    }

    final data = response.data as Map<String, dynamic>;

    // Fetch the saved review by ID
    return getReview(data['review_id'] as String).then(
      (r) => r ?? _reviewFromEdgeResponse(userId, weekStart, weekEnd, data),
    );
  }

  @override
  Future<WeeklyReview?> getReview(String reviewId) async {
    final row =
        await _client
            .from('weekly_reviews')
            .select()
            .eq('id', reviewId)
            .maybeSingle();

    if (row == null) return null;
    return _fromRow(row);
  }

  @override
  Future<List<WeeklyReview>> getReviewHistory(String userId) async {
    final rows = await _client
        .from('weekly_reviews')
        .select()
        .eq('user_id', userId)
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('week_start', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>().map(_fromRow).toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  WeeklyReview _fromRow(Map<String, dynamic> r) {
    final patterns =
        (r['patterns'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(ReviewPattern.fromJson)
            .toList();

    final insights =
        (r['insights'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(ReviewInsight.fromJson)
            .toList();

    PartnerReviewSummary? partnerSummary;
    if (r['partner_summary'] != null) {
      partnerSummary = PartnerReviewSummary.fromJson(
        r['partner_summary'] as Map<String, dynamic>,
      );
    }

    return WeeklyReview(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      weekStart: DateTime.parse(r['week_start'] as String),
      weekEnd: DateTime.parse(r['week_end'] as String),
      patterns: patterns,
      insights: insights,
      partnerSummary: partnerSummary,
      summaryText: '',
      expiresAt: DateTime.parse(r['expires_at'] as String),
      createdAt: DateTime.parse(r['created_at'] as String),
    );
  }

  /// Constructs a WeeklyReview from the Edge Function response when the DB
  /// fetch fails (should not normally happen).
  WeeklyReview _reviewFromEdgeResponse(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
    Map<String, dynamic> data,
  ) {
    final patterns =
        (data['patterns'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(ReviewPattern.fromJson)
            .toList();

    final insights =
        (data['insights'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(ReviewInsight.fromJson)
            .toList();

    return WeeklyReview(
      id: data['review_id'] as String? ?? '',
      userId: userId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      patterns: patterns,
      insights: insights,
      summaryText: data['summary_text'] as String? ?? '',
      expiresAt: DateTime.now().add(const Duration(days: 90)),
      createdAt: DateTime.now(),
    );
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
