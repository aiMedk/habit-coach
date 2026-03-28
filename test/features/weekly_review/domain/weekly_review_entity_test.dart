import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/weekly_review/domain/entities/weekly_review.dart';

void main() {
  final now = DateTime(2025, 6, 2);

  group('ReviewPattern', () {
    test('toJson / fromJson round-trip', () {
      const p = ReviewPattern(
        description: 'Morning workouts are consistent',
        confidence: PatternConfidence.high,
      );
      final json = p.toJson();
      final p2 = ReviewPattern.fromJson(json);
      expect(p2.description, p.description);
      expect(p2.confidence, p.confidence);
    });

    test('fromJson defaults to medium confidence when key missing', () {
      final p = ReviewPattern.fromJson({
        'description': 'Test',
        'confidence': null,
      });
      expect(p.confidence, PatternConfidence.medium);
    });
  });

  group('ReviewInsight', () {
    test('toJson / fromJson round-trip', () {
      const i = ReviewInsight(
        description: 'You skip habits on Fridays',
        action: 'Schedule a Friday reminder',
      );
      final json = i.toJson();
      final i2 = ReviewInsight.fromJson(json);
      expect(i2.description, i.description);
      expect(i2.action, i.action);
    });

    test('fromJson defaults action to empty string when missing', () {
      final i = ReviewInsight.fromJson({'description': 'Desc'});
      expect(i.action, '');
    });
  });

  group('PartnerReviewSummary', () {
    test('fromJson parses partner name, topStreaks, sharedWins', () {
      final s = PartnerReviewSummary.fromJson({
        'partner_name': 'Alice',
        'top_streaks': [
          {'habit': 'Run', 'days': 7},
        ],
        'shared_wins': ['Both hit 7-day streaks!'],
      });
      expect(s.partnerName, 'Alice');
      expect(s.topStreaks.first['habit'], 'Run');
      expect(s.sharedWins.first, 'Both hit 7-day streaks!');
    });

    test('fromJson defaults to empty lists when keys absent', () {
      final s = PartnerReviewSummary.fromJson({'partner_name': 'Bob'});
      expect(s.topStreaks, isEmpty);
      expect(s.sharedWins, isEmpty);
    });
  });

  group('WeeklyReview', () {
    WeeklyReview makeReview({String id = 'rev-1', DateTime? expiresAt}) =>
        WeeklyReview(
          id: id,
          userId: 'user-1',
          weekStart: DateTime(2025, 5, 26),
          weekEnd: DateTime(2025, 6, 1),
          patterns: const [
            ReviewPattern(
              description: 'Pattern A',
              confidence: PatternConfidence.high,
            ),
          ],
          insights: const [
            ReviewInsight(description: 'Insight A', action: 'Do B'),
          ],
          summaryText: 'Great week!',
          expiresAt: expiresAt ?? now.add(const Duration(days: 90)),
          createdAt: now,
        );

    test('isExpired returns false for future expiresAt', () {
      final r = makeReview(
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      expect(r.isExpired, isFalse);
    });

    test('isExpired returns true for past expiresAt', () {
      final r = makeReview(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(r.isExpired, isTrue);
    });

    test('equality is id-based', () {
      final r1 = makeReview(id: 'rev-1');
      final r2 = makeReview(id: 'rev-1');
      final r3 = makeReview(id: 'rev-2');
      expect(r1, equals(r2));
      expect(r1, isNot(equals(r3)));
    });

    test('hashCode is id-based', () {
      final r1 = makeReview(id: 'rev-1');
      final r2 = makeReview(id: 'rev-1');
      expect(r1.hashCode, r2.hashCode);
    });

    test('partnerSummary is nullable and defaults to null', () {
      final r = makeReview();
      expect(r.partnerSummary, isNull);
    });
  });
}
