import 'package:flutter/material.dart';
import 'package:habit_coach/features/habits/domain/entities/streak.dart';

/// T052: StreakBadge — displays the current streak count with a fire icon.
///
/// At milestones (7, 30, 100 days) the badge glows in the primary colour to
/// signal celebration. A count of 0 renders nothing.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    if (!streak.hasActiveStreak) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isMilestone = streak.isMilestone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isMilestone
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 16,
            color:
                isMilestone
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            '${streak.currentCount}',
            style: theme.textTheme.labelMedium?.copyWith(
              color:
                  isMilestone
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
              fontWeight: isMilestone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
