import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/ai_coaching/presentation/providers/coaching_providers.dart';

/// T072: EveningPromptCard — dismissible card shown on the dashboard during
/// the evening window (6 PM – 11:59 PM) when reflection hasn't been done yet.
///
/// Tapping opens the AI chat screen for an evening reflection.
/// Dismissing hides the card for the remainder of the evening (local only).
class EveningPromptCard extends ConsumerStatefulWidget {
  const EveningPromptCard({super.key});

  @override
  ConsumerState<EveningPromptCard> createState() => _EveningPromptCardState();
}

class _EveningPromptCardState extends ConsumerState<EveningPromptCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.nights_stay_outlined,
              color: theme.colorScheme.onSecondaryContainer,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evening reflection ready',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reflect on your day and set intentions for tomorrow.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer.withAlpha(
                        200,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: _startReflection,
              child: const Text('Start'),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onSecondaryContainer.withAlpha(180),
                size: 18,
              ),
              onPressed: () => setState(() => _dismissed = true),
              tooltip: 'Dismiss',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startReflection() async {
    // Start the evening conversation eagerly then navigate
    ref.read(eveningChatProvider.notifier).startConversation();
    if (mounted) {
      context.push(
        AppRoutes.chat.replaceFirst(':conversationId', 'new-evening'),
      );
    }
  }
}
