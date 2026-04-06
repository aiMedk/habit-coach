import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/subscription/domain/entities/subscription.dart';
import 'package:habit_coach/features/subscription/presentation/providers/subscription_providers.dart';

/// T134: SubscriptionScreen — current plan, expiry, manage/cancel link,
/// and restore purchases.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionStateProvider);
    final purchaseState = ref.watch(purchaseProvider);

    ref.listen(purchaseProvider, (_, next) {
      next.whenData((sub) {
        if (sub != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchases restored successfully')),
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: subAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data:
            (sub) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Current plan card
                Card(
                  color:
                      sub.isPro
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              sub.isPro
                                  ? Icons.workspace_premium
                                  : Icons.person_outline,
                              color:
                                  sub.isPro
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              sub.isPro ? 'Pro' : 'Free',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (sub.status == SubscriptionStatus.cancelled)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Chip(
                                  label: const Text('Cancelled'),
                                  labelStyle: const TextStyle(fontSize: 12),
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.errorContainer,
                                ),
                              ),
                          ],
                        ),
                        if (sub.expiresAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            sub.status == SubscriptionStatus.cancelled
                                ? 'Access until ${_fmt(sub.expiresAt!)}'
                                : 'Renews ${_fmt(sub.expiresAt!)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (!sub.isPro) ...[
                  FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.paywall),
                    icon: const Icon(Icons.upgrade),
                    label: const Text('Upgrade to Pro'),
                  ),
                  const SizedBox(height: 8),
                ],

                if (sub.isPro) ...[
                  OutlinedButton.icon(
                    onPressed:
                        () =>
                            ref
                                .read(subscriptionRepositoryProvider)
                                .manageSubscription(),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Manage / Cancel in App Store'),
                  ),
                  const SizedBox(height: 8),
                ],

                TextButton(
                  onPressed:
                      purchaseState.isLoading
                          ? null
                          : () =>
                              ref
                                  .read(purchaseProvider.notifier)
                                  .restorePurchases(),
                  child:
                      purchaseState.isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Restore purchases'),
                ),

                if (purchaseState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      purchaseState.error.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
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
