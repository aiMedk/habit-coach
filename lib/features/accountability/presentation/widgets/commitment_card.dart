import 'package:flutter/material.dart';
import 'package:habit_coach/features/accountability/domain/entities/commitment.dart';

/// T096: CommitmentCard — shows a single commitment's progress, days remaining,
/// and a status badge (active / fulfilled / failed).
class CommitmentCard extends StatelessWidget {
  const CommitmentCard({super.key, required this.commitment});

  final Commitment commitment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daysLeft = commitment.daysRemaining;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    commitment.habitName,
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: commitment.status),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: commitment.progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              color: _progressColor(context, commitment.status),
              backgroundColor: cs.surfaceContainerHighest,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${commitment.currentStreak} / ${commitment.targetStreak} days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  commitment.isActive
                      ? (daysLeft >= 0 ? '$daysLeft days left' : 'Overdue')
                      : '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        daysLeft < 3 && commitment.isActive
                            ? cs.error
                            : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _progressColor(BuildContext context, CommitmentStatus status) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      CommitmentStatus.fulfilled => Colors.green,
      CommitmentStatus.failed => cs.error,
      CommitmentStatus.active => cs.primary,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final CommitmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CommitmentStatus.active => (
        'Active',
        Theme.of(context).colorScheme.primary,
      ),
      CommitmentStatus.fulfilled => ('Fulfilled', Colors.green),
      CommitmentStatus.failed => (
        'Failed',
        Theme.of(context).colorScheme.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
