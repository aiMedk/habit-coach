import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';
import 'package:habit_coach/features/weekly_review/domain/entities/weekly_review.dart';
import 'package:habit_coach/features/weekly_review/presentation/providers/review_providers.dart';

/// T117: ReviewsListScreen — shows past reviews within 90-day retention window
/// and provides a "Generate this week's review" button.
class ReviewsListScreen extends ConsumerWidget {
  const ReviewsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementService = ref.watch(entitlementServiceProvider);
    final isPro = entitlementService.isPro;

    // T019: Show upgrade prompt for free-tier users
    if (!isPro) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly reviews')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Reviews are a Pro feature',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Access your weekly AI reviews and past coaching conversations.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.paywall),
                  child: const Text('Upgrade to Pro'),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: () {}, child: const Text('Maybe later')),
              ],
            ),
          ),
        ),
      );
    }

    final historyAsync = ref.watch(reviewHistoryProvider);
    final generateState = ref.watch(generateReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly reviews')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (generateState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      generateState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                FilledButton.icon(
                  onPressed:
                      generateState.isLoading
                          ? null
                          : () => _generateThisWeek(context, ref),
                  icon:
                      generateState.isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.auto_awesome, size: 18),
                  label: const Text("Generate this week's review"),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insights_outlined,
                            size: 64,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generate your first weekly review above after 7+ days of habit data.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ReviewTile(review: reviews[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateThisWeek(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final now = DateTime.now();
    // Monday of current ISO week
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    await ref
        .read(generateReviewProvider.notifier)
        .generate(userId: user.id, weekStart: weekStart, weekEnd: weekEnd);

    final state = ref.read(generateReviewProvider);
    if (state.review != null && context.mounted) {
      context.push(
        AppRoutes.reviewDetail.replaceFirst(':id', state.review!.id),
      );
    }
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final WeeklyReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap:
            () => context.push(
              AppRoutes.reviewDetail.replaceFirst(':id', review.id),
            ),
        leading: const Icon(Icons.insights_outlined),
        title: Text(
          '${_fmt(review.weekStart)} – ${_fmt(review.weekEnd)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          '${review.patterns.length} patterns · ${review.insights.length} insights',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]}';

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
