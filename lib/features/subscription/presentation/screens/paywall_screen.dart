import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:url_launcher/url_launcher.dart';

/// T133: PaywallScreen — shows Pro price, feature list, purchase CTA,
/// restore purchases, and terms/privacy links.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(paywallProductsProvider);
    final purchaseState = ref.watch(purchaseProvider);

    // Navigate away after successful purchase.
    ref.listen(purchaseProvider, (_, next) {
      next.whenData((sub) {
        if (sub != null && context.mounted) {
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Welcome to Pro! 🎉')));
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero icon
            Icon(
              Icons.workspace_premium,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock your full potential',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Everything you need to build lasting habits',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Feature list
            ..._features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      f.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            f.subtitle,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Price from RevenueCat
            productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) => const Text('Could not load pricing. Try again.'),
              data: (packages) => _PriceCard(packages: packages),
            ),
            const SizedBox(height: 16),

            // Purchase CTA
            FilledButton(
              onPressed:
                  purchaseState.isLoading
                      ? null
                      : () => ref.read(purchaseProvider.notifier).purchasePro(),
              child:
                  purchaseState.isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Start Pro'),
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
            const SizedBox(height: 8),

            // Restore
            TextButton(
              onPressed:
                  purchaseState.isLoading
                      ? null
                      : () =>
                          ref
                              .read(purchaseProvider.notifier)
                              .restorePurchases(),
              child: const Text('Restore purchases'),
            ),
            const SizedBox(height: 4),

            // Terms and Privacy
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed:
                      () => launchUrl(
                        Uri.parse('https://habitcoach.app/terms'),
                        mode: LaunchMode.externalApplication,
                      ),
                  child: const Text('Terms', style: TextStyle(fontSize: 12)),
                ),
                const Text('·'),
                TextButton(
                  onPressed:
                      () => launchUrl(
                        Uri.parse('https://habitcoach.app/privacy'),
                        mode: LaunchMode.externalApplication,
                      ),
                  child: const Text('Privacy', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.packages});
  final List<rc.Package> packages;

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Pricing unavailable. Check your connection.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Show the first (typically monthly) package.
    final package = packages.first;
    final price = package.storeProduct.priceString;
    final period =
        package.packageType == rc.PackageType.annual
            ? 'per year'
            : package.packageType == rc.PackageType.monthly
            ? 'per month'
            : '';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              price,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              period,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
}

const _features = [
  _Feature(
    icon: Icons.all_inclusive,
    title: 'Unlimited habits',
    subtitle: 'Free plan is limited to 3 habits',
  ),
  _Feature(
    icon: Icons.psychology,
    title: 'AI daily coaching',
    subtitle: 'Morning check-ins and evening reflections',
  ),
  _Feature(
    icon: Icons.insights,
    title: 'Weekly AI reviews',
    subtitle: 'Deep pattern analysis and personalised insights',
  ),
  _Feature(
    icon: Icons.people,
    title: 'Accountability partner',
    subtitle: 'Shared streaks, commitments, and nudges',
  ),
  _Feature(
    icon: Icons.emoji_events,
    title: 'Group challenges',
    subtitle: 'Compete or collaborate with up to 5 people',
  ),
  _Feature(
    icon: Icons.notifications_active,
    title: 'AI-personalised notifications',
    subtitle: 'Smart reminders tailored to your habits',
  ),
];
