import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';

/// T053: UpgradePrompt — shown when a free-tier user attempts to exceed the
/// 3-habit limit or access a Pro-only feature.
///
/// Displays a contextual message explaining the limitation and a CTA to
/// navigate to the subscription settings screen.
class UpgradePrompt extends StatelessWidget {
  const UpgradePrompt({
    super.key,
    this.title = 'Upgrade to Pro',
    this.message =
        'You\'ve reached the free plan limit of 3 habits. '
            'Upgrade to Pro for unlimited habits, AI coaching, '
            'weekly reviews, and accountability features.',
  });

  final String title;
  final String message;

  /// Shows the prompt as a bottom sheet.
  static Future<void> showAsBottomSheet(
    BuildContext context, {
    String? title,
    String? message,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder:
          (_) => UpgradePrompt(
            title: title ?? 'Upgrade to Pro',
            message:
                message ??
                'You\'ve reached the free plan limit of 3 habits. '
                    'Upgrade to Pro for unlimited habits, AI coaching, '
                    'weekly reviews, and accountability features.',
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.workspace_premium,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.paywall);
            },
            icon: const Icon(Icons.upgrade),
            label: const Text('See Pro plans'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}
