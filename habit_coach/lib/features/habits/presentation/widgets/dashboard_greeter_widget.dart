import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';

class DashboardGreeterWidget extends ConsumerWidget {
  const DashboardGreeterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dailyStatsProvider);

    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final hour = DateTime.now().hour;
        final greetingPrefix = switch (hour) {
          < 12 => 'Good morning',
          < 18 => 'Good afternoon',
          _ => 'Good evening',
        };
        final displayName =
            user.displayName.trim().isEmpty
                ? user.email.split('@').first
                : user.displayName;

        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greetingPrefix $displayName',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data:
                    (stats) => Text(
                      '${stats.completedCount} of ${stats.totalCount} habits completed today',
                      style: theme.textTheme.bodyMedium,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
