import 'package:flutter/material.dart';
import 'package:habit_coach/features/habits/domain/entities/daily_stats.dart';

class BottomStatsBar extends StatelessWidget {
  const BottomStatsBar({super.key, required this.stats});

  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Container(
          color: colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                label: 'Best streak',
                value: '${stats.bestStreak} days',
                labelStyle: textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                valueStyle: textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _StatItem(
                label: 'This week',
                value:
                    '${stats.weekCompletedCount}/${stats.weekTotalCount} habits',
                labelStyle: textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                valueStyle: textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 2),
        Text(value, style: valueStyle),
      ],
    );
  }
}
