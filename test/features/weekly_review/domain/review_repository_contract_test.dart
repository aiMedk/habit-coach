import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/weekly_review/domain/entities/weekly_review.dart';
import 'package:habit_coach/features/weekly_review/domain/repositories/review_repository.dart';

/// T178: ReviewRepository contract tests — validates the interface behaviour
/// using a fake implementation (no Supabase dependency).
///
/// Also validates the 7-day minimum data requirement behaviour.

class _FakeReviewRepository implements ReviewRepository {
  final List<WeeklyReview> _store = [];
  bool throwInsufficientData = false;
  bool throwProRequired = false;

  @override
  Future<WeeklyReview> generateReview({
    required String userId,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    if (throwProRequired)
      throw Exception('Pro tier required for weekly reviews');
    if (throwInsufficientData) {
      throw Exception(
        'Not enough data — complete habits for at least 7 days first',
      );
    }
    final review = WeeklyReview(
      id: 'generated-1',
      userId: userId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      patterns: const [
        ReviewPattern(
          description: 'Pattern',
          confidence: PatternConfidence.medium,
        ),
      ],
      insights: const [ReviewInsight(description: 'Insight', action: 'Action')],
      summaryText: 'Summary',
      expiresAt: DateTime.now().add(const Duration(days: 90)),
      createdAt: DateTime.now(),
    );
    _store.add(review);
    return review;
  }

  @override
  Future<WeeklyReview?> getReview(String reviewId) async =>
      _store.where((r) => r.id == reviewId).firstOrNull;

  @override
  Future<List<WeeklyReview>> getReviewHistory(String userId) async =>
      _store.where((r) => r.userId == userId && !r.isExpired).toList()
        ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
}

void main() {
  late _FakeReviewRepository repo;
  final weekStart = DateTime(2025, 5, 26);
  final weekEnd = DateTime(2025, 6, 1);

  setUp(() {
    repo = _FakeReviewRepository();
  });

  group('generateReview', () {
    test('returns a WeeklyReview with correct userId and week range', () async {
      final r = await repo.generateReview(
        userId: 'user-1',
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
      expect(r.userId, 'user-1');
      expect(r.weekStart, weekStart);
      expect(r.weekEnd, weekEnd);
    });

    test('throws when user is not Pro tier', () async {
      repo.throwProRequired = true;
      await expectLater(
        () => repo.generateReview(
          userId: 'user-1',
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when fewer than 7 days of completion data', () async {
      repo.throwInsufficientData = true;
      await expectLater(
        () => repo.generateReview(
          userId: 'user-1',
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getReview', () {
    test('returns the review by id after generation', () async {
      final generated = await repo.generateReview(
        userId: 'user-1',
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
      final fetched = await repo.getReview(generated.id);
      expect(fetched, isNotNull);
      expect(fetched!.id, generated.id);
    });

    test('returns null for unknown id', () async {
      final r = await repo.getReview('no-such-id');
      expect(r, isNull);
    });
  });

  group('getReviewHistory', () {
    test('returns reviews for userId, most recent first', () async {
      await repo.generateReview(
        userId: 'user-1',
        weekStart: DateTime(2025, 5, 19),
        weekEnd: DateTime(2025, 5, 25),
      );
      await repo.generateReview(
        userId: 'user-1',
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
      final history = await repo.getReviewHistory('user-1');
      expect(history.length, 2);
      expect(history.first.weekStart, weekStart); // most recent first
    });

    test('returns empty list when no reviews exist', () async {
      final history = await repo.getReviewHistory('user-1');
      expect(history, isEmpty);
    });

    test('excludes expired reviews', () async {
      // Insert an expired review directly
      repo._store.add(
        WeeklyReview(
          id: 'expired',
          userId: 'user-1',
          weekStart: DateTime(2025, 1, 6),
          weekEnd: DateTime(2025, 1, 12),
          patterns: const [],
          insights: const [],
          summaryText: '',
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime(2025, 1, 6),
        ),
      );
      final history = await repo.getReviewHistory('user-1');
      expect(history, isEmpty);
    });

    test('does not mix reviews from different users', () async {
      await repo.generateReview(
        userId: 'user-1',
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
      final history = await repo.getReviewHistory('user-2');
      expect(history, isEmpty);
    });
  });
}
