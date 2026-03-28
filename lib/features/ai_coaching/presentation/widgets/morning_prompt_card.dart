import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/ai_coaching/presentation/providers/coaching_providers.dart';

/// T062: MorningPromptCard — dismissible card shown on the dashboard during
/// the morning window (5 AM – 11:59 AM) when check-in hasn't been done yet.
///
/// Tapping opens the AI chat screen. Dismissing hides the card for the
/// remainder of the morning (local dismiss only — no server write).
class MorningPromptCard extends ConsumerStatefulWidget {
  const MorningPromptCard({super.key});

  @override
  ConsumerState<MorningPromptCard> createState() => _MorningPromptCardState();
}

class _MorningPromptCardState extends ConsumerState<MorningPromptCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              color: theme.colorScheme.onPrimaryContainer,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Morning check-in ready',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your AI coach is ready to set the tone for today.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withAlpha(
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
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: _startCheckin,
              child: const Text('Start'),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
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

  Future<void> _startCheckin() async {
    // Start the conversation eagerly then navigate
    ref.read(chatProvider.notifier).startConversation();
    if (mounted)
      context.push(AppRoutes.chat.replaceFirst(':conversationId', 'new'));
  }
}
