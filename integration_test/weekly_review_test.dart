import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/weekly_review/domain/entities/weekly_review.dart';
import 'package:habit_coach/features/weekly_review/domain/repositories/review_repository.dart';
import 'package:integration_test/integration_test.dart';

/// T179: Weekly Review integration smoke tests.
///
/// These tests validate the domain layer in isolation (no Supabase / Claude).
/// They confirm contracts and entity behaviours work end-to-end without
/// requiring a live back-end.

class _InMemoryReviewRepository implements ReviewRepository {
  final _store = <String, WeeklyReview>{};
  int _seq = 0;

  @override
  Future<WeeklyReview> generateReview({
    required String userId,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    final id = 'review-${++_seq}';
    final review = WeeklyReview(
      id: id,
      userId: userId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      patterns: const [
        ReviewPattern(
          description: 'Consistent mornings',
          confidence: PatternConfidence.high,
        ),
      ],
      insights: const [
        ReviewInsight(
          description: 'Skips habits on Fridays',
          action: 'Set a Friday reminder',
        ),
      ],
      summaryText: 'Solid week overall.',
      expiresAt: DateTime.now().add(const Duration(days: 90)),
      createdAt: DateTime.now(),
    );
    _store[id] = review;
    return review;
  }

  @override
  Future<WeeklyReview?> getReview(String reviewId) async => _store[reviewId];

  @override
  Future<List<WeeklyReview>> getReviewHistory(String userId) async =>
      _store.values.where((r) => r.userId == userId && !r.isExpired).toList()
        ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ReviewRepository repo;
  final weekStart = DateTime(2025, 5, 26);
  final weekEnd = DateTime(2025, 6, 1);

  setUp(() {
    repo = _InMemoryReviewRepository();
  });

  testWidgets('US7 smoke: generate review and retrieve by id', (tester) async {
    final review = await repo.generateReview(
      userId: 'user-1',
      weekStart: weekStart,
      weekEnd: weekEnd,
    );
    expect(review.id, isNotEmpty);
    expect(review.patterns, isNotEmpty);
    expect(review.insights, isNotEmpty);

    final fetched = await repo.getReview(review.id);
    expect(fetched, isNotNull);
    expect(fetched!.id, review.id);
  });

  testWidgets('US7 smoke: history ordered most recent first', (tester) async {
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
    expect(history.first.weekStart, weekStart);
  });

  testWidgets('US7 smoke: 90-day expiry respected in history', (tester) async {
    // Simulate an expired review by manipulating store after generation
    final inMemRepo = repo as _InMemoryReviewRepository;
    final r = await repo.generateReview(
      userId: 'user-1',
      weekStart: DateTime(2025, 1, 6),
      weekEnd: DateTime(2025, 1, 12),
    );
    // Replace with expired version
    inMemRepo._store[r.id] = WeeklyReview(
      id: r.id,
      userId: r.userId,
      weekStart: r.weekStart,
      weekEnd: r.weekEnd,
      patterns: r.patterns,
      insights: r.insights,
      summaryText: r.summaryText,
      expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      createdAt: r.createdAt,
    );
    final history = await repo.getReviewHistory('user-1');
    expect(history, isEmpty);
  });

  testWidgets('US7 smoke: getReview returns null for unknown id', (
    tester,
  ) async {
    final r = await repo.getReview('no-such-id');
    expect(r, isNull);
  });
}
