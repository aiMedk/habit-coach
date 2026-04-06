import 'package:flutter/material.dart';
import 'package:habit_coach/features/subscription/presentation/widgets/upgrade_prompt.dart';

/// T066: AiPreviewCard — teaser shown to free-tier users on the dashboard
/// during morning/evening windows, prompting them to upgrade to access AI.
class AiPreviewCard extends StatelessWidget {
  const AiPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI coaching available',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Upgrade to Pro for personalised morning and evening check-ins.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed:
                  () => UpgradePrompt.showAsBottomSheet(
                    context,
                    title: 'Unlock AI Coaching',
                    message:
                        'Get personalised morning and evening check-ins powered by AI. '
                        'Your coach learns your habits and adapts over time.',
                  ),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      ),
    );
  }
}
