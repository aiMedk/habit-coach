import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/accountability/domain/entities/partnership.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';
import 'package:habit_coach/features/accountability/presentation/providers/commitment_providers.dart';
import 'package:habit_coach/features/accountability/presentation/widgets/commitment_card.dart';
import 'package:habit_coach/features/accountability/presentation/widgets/partner_actions.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';

/// T085: PartnerDashboardScreen — shows both users' habit streaks and today's
/// completion rates. No conversation data is shown here.
class PartnerDashboardScreen extends ConsumerWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnershipAsync = ref.watch(partnershipProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner dashboard')),
      body: partnershipAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (partnership) {
          if (partnership == null || !partnership.isActive) {
            return const _NoPartnerView();
          }
          return _DashboardBody(partnership: partnership);
        },
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.partnership});
  final Partnership partnership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerStreaksAsync = ref.watch(partnerStreaksProvider);
    final myHabitsAsync = ref.watch(habitListProvider);
    final myStreaksAsync = ref.watch(todayCompletionsProvider);
    final commitmentsAsync = ref.watch(partnershipCommitmentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My section
          Text('You', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          myHabitsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data:
                (habits) => myStreaksAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (completions) {
                    final completedIds =
                        completions.map((c) => c.habitId).toSet();
                    return _HabitStreakList(
                      habitNames: habits.map((h) => h.name).toList(),
                      completedIds: completedIds,
                      completionRate:
                          habits.isEmpty
                              ? 0.0
                              : completedIds.length / habits.length,
                    );
                  },
                ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Partner section
          partnerStreaksAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) {
              if (summary == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.partnerName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _HabitStreakList(
                    habitNames: summary.streaks.keys.toList(),
                    completedIds:
                        summary.streaks.entries
                            .where((e) => e.value > 0)
                            .map((e) => e.key)
                            .toSet(),
                    completionRate: summary.completionRateToday,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Commitments section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commitments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.createCommitment),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          commitmentsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              if (data.mine.isEmpty && data.theirs.isEmpty) {
                return Text(
                  'No active commitments yet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.mine.isNotEmpty) ...[
                    Text(
                      'Yours',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    ...data.mine.map((c) => CommitmentCard(commitment: c)),
                    const SizedBox(height: 12),
                  ],
                  if (data.theirs.isNotEmpty) ...[
                    Text(
                      "Partner's",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    ...data.theirs.map((c) => CommitmentCard(commitment: c)),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          // Partner management actions
          PartnerActions(partnershipId: partnership.id),
        ],
      ),
    );
  }
}

class _HabitStreakList extends StatelessWidget {
  const _HabitStreakList({
    required this.habitNames,
    required this.completedIds,
    required this.completionRate,
  });

  final List<String> habitNames;
  final Set<String> completedIds;
  final double completionRate;

  @override
  Widget build(BuildContext context) {
    final pct = (completionRate * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: completionRate,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text('$pct%', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        if (habitNames.isEmpty)
          Text(
            'No active habits',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...habitNames.map((name) {
            final done = completedIds.contains(name);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    done ? Icons.check_circle_outline : Icons.circle_outlined,
                    size: 16,
                    color:
                        done
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(name, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _NoPartnerView extends StatelessWidget {
  const _NoPartnerView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No partner yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Invite a friend from Settings to see their progress here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
