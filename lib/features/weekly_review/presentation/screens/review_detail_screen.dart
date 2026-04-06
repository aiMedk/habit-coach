import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/weekly_review/domain/entities/weekly_review.dart';
import 'package:habit_coach/features/weekly_review/presentation/providers/review_providers.dart';

/// T116: ReviewDetailScreen — shows a weekly review with patterns,
/// insights, and partner summary. Users can dismiss or navigate away.
class ReviewDetailScreen extends ConsumerWidget {
  const ReviewDetailScreen({super.key, required this.reviewId});

  final String reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(
      reviewHistoryProvider.selectAsync(
        (list) => list.where((r) => r.id == reviewId).firstOrNull,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly review')),
      body: FutureBuilder<WeeklyReview?>(
        future: reviewAsync,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final review = snap.data;
          if (review == null) {
            return const Center(child: Text('Review not found'));
          }
          return _ReviewBody(review: review);
        },
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.review});
  final WeeklyReview review;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date range header
          Text(
            '${_fmt(review.weekStart)} – ${_fmt(review.weekEnd)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Patterns section
          if (review.patterns.isNotEmpty) ...[
            Text('Patterns', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...review.patterns.map((p) => _PatternCard(pattern: p)),
            const SizedBox(height: 20),
          ],

          // Insights section
          if (review.insights.isNotEmpty) ...[
            Text('Insights', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...review.insights.map((i) => _InsightCard(insight: i)),
            const SizedBox(height: 20),
          ],

          // Partner summary section
          if (review.partnerSummary != null) ...[
            Text(
              'Partner highlights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _PartnerSummaryCard(summary: review.partnerSummary!),
            const SizedBox(height: 20),
          ],

          // Summary text
          if (review.summaryText.isNotEmpty) ...[
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  review.summaryText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});
  final ReviewPattern pattern;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (pattern.confidence) {
      PatternConfidence.high => (Colors.green, Icons.trending_up),
      PatternConfidence.medium => (Colors.orange, Icons.trending_flat),
      PatternConfidence.low => (
        Theme.of(context).colorScheme.outline,
        Icons.trending_down,
      ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          pattern.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            pattern.confidence.name,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final ReviewInsight insight;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              insight.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (insight.action.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      insight.action,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PartnerSummaryCard extends StatelessWidget {
  const _PartnerSummaryCard({required this.summary});
  final PartnerReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.partnerName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (summary.topStreaks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...summary.topStreaks.map(
                (s) => Text(
                  '• ${s['habit']}: ${s['days']} days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (summary.sharedWins.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...summary.sharedWins.map(
                (w) =>
                    Text('🎉 $w', style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
