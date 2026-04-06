import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/constants/app_constants.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/core/utils/date_utils.dart';
import 'package:habit_coach/features/ai_coaching/presentation/providers/coaching_providers.dart';
import 'package:habit_coach/features/ai_coaching/presentation/widgets/ai_preview_card.dart';
import 'package:habit_coach/features/ai_coaching/presentation/widgets/evening_prompt_card.dart';
import 'package:habit_coach/features/ai_coaching/presentation/widgets/morning_prompt_card.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';
import 'package:habit_coach/features/habits/presentation/widgets/bottom_stats_bar.dart';
import 'package:habit_coach/features/habits/presentation/widgets/dashboard_greeter_widget.dart';
import 'package:habit_coach/features/habits/presentation/widgets/streak_badge.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

/// T049: Dashboard screen — main home screen showing today's habits.
///
/// Features:
/// - Personalised greeting header with today's date and "X of Y" summary
/// - AI coaching prompt card (time-gated, Pro/free-tier aware)
/// - List of active habits with completion state
/// - Tap to complete; completed habits show a strikethrough
/// - 5-minute undo via snackbar
/// - Streak badge per habit
/// - Persistent bottom stats bar (best streak, this week)
/// - FAB to add a new habit (gated by entitlement)
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final todayAsync = ref.watch(todayCompletionsProvider);
    final dailyStatsAsync = ref.watch(dailyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          // T021: Sync-failure banner — appears when offline sync fails
          _SyncFailureBanner(),
          // T012: Personalised greeting, date, and "X of Y" summary — FR-001–FR-003.
          const DashboardGreeterWidget(),
          _AiCard(),
          Expanded(
            child: habitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(message: e.toString()),
              data:
                  (habits) => todayAsync.when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _ErrorView(message: e.toString()),
                    data: (todayCompletions) {
                      final completedHabitIds =
                          todayCompletions.map((c) => c.habitId).toSet();
                      return _HabitList(
                        habits: habits,
                        completedHabitIds: completedHabitIds,
                        todayCompletionIdByHabit: {
                          for (final c in todayCompletions) c.habitId: c.id,
                        },
                      );
                    },
                  ),
            ),
          ),
          // T014: Persistent stats bar — always visible below the list — FR-008.
          dailyStatsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => BottomStatsBar(stats: stats),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => context.push(AppRoutes.habitNew),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HabitList extends ConsumerWidget {
  const _HabitList({
    required this.habits,
    required this.completedHabitIds,
    required this.todayCompletionIdByHabit,
  });

  final List<Habit> habits;
  final Set<String> completedHabitIds;
  final Map<String, String> todayCompletionIdByHabit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (habits.isEmpty) {
      return const _EmptyState();
    }

    final entitlementService = ref.watch(entitlementServiceProvider);
    final isPro = entitlementService.isPro;

    // For free-tier users: split habits into interactive (0-2) and locked (3+)
    final interactiveLimit =
        isPro ? habits.length : AppConstants.freeTierHabitLimit;
    final clampedLimit = interactiveLimit.clamp(0, habits.length);
    final interactiveHabits = habits.sublist(0, clampedLimit);
    final lockedHabits = isPro ? <Habit>[] : habits.sublist(clampedLimit);

    return CustomScrollView(
      slivers: [
        // Active habits (interactive for all tiers)
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final habit = interactiveHabits[index];
            final isCompleted = completedHabitIds.contains(habit.id);
            final completionId = todayCompletionIdByHabit[habit.id];
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: index == 0 ? 16 : 4,
              ),
              child: _HabitCard(
                habit: habit,
                isCompleted: isCompleted,
                completionId: completionId,
              ),
            );
          }, childCount: interactiveHabits.length),
        ),

        // Locked habits section (for free-tier users)
        if (lockedHabits.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Upgrade to see more',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
        if (lockedHabits.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final habit = lockedHabits[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: _LockedHabitRow(habit: habit),
              );
            }, childCount: lockedHabits.length),
          ),

        // Completed habits section
        if (completedHabitIds.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Completed today',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
        if (completedHabitIds.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final completedHabits =
                  habits
                      .where((h) => completedHabitIds.contains(h.id))
                      .toList();
              final habit = completedHabits[index];
              final completionId = todayCompletionIdByHabit[habit.id];
              final habitIndexInAll = habits.indexOf(habit);

              // Only show completed habits that were interactive when completed
              // (index within free-tier limit, or user is Pro)
              if (!isPro &&
                  habitIndexInAll >= AppConstants.freeTierHabitLimit) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: _HabitCard(
                  habit: habit,
                  isCompleted: true,
                  completionId: completionId,
                ),
              );
            }, childCount: completedHabitIds.length),
          ),
      ],
    );
  }
}

class _HabitCard extends ConsumerWidget {
  const _HabitCard({
    required this.habit,
    required this.isCompleted,
    this.completionId,
  });

  final Habit habit;
  final bool isCompleted;
  final String? completionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider(habit.id));

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isCompleted ? null : () => _complete(context, ref),
        onLongPress: () => context.push('/habit/${habit.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _CompletionIndicator(isCompleted: isCompleted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color:
                            isCompleted
                                ? Theme.of(context).colorScheme.outline
                                : null,
                      ),
                    ),
                    if (habit.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        habit.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              streakAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (streak) => StreakBadge(streak: streak),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    final repo = await ref.read(completionRepositoryProvider.future);

    final now = DateTime.now();
    final localDate = HabitDateUtils.toDateString(now);

    try {
      final completion = await repo.completeHabit(
        habitId: habit.id,
        userId: user.id,
        completedAt: now.toUtc(),
        localDate: localDate,
      );
      // Invalidate providers so the list refreshes
      ref.invalidate(todayCompletionsProvider);
      ref.invalidate(streakProvider(habit.id));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.name} completed!'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await repo.undoCompletion(completion.id);
                ref.invalidate(todayCompletionsProvider);
                ref.invalidate(streakProvider(habit.id));
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot undo: 5-minute window has elapsed.'),
                  ),
                );
              }
            },
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _CompletionIndicator extends StatelessWidget {
  const _CompletionIndicator({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isCompleted
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
        border:
            isCompleted
                ? null
                : Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
      ),
      child:
          isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_task,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first habit.',
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Something went wrong:\n$message',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

/// T016: LockedHabitRow — displays a locked habit with upgrade prompt.
class _LockedHabitRow extends StatelessWidget {
  const _LockedHabitRow({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppRoutes.paywall),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: colorScheme.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade to Pro',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// T021: Sync-failure banner — shows when offline sync fails.
class _SyncFailureBanner extends ConsumerWidget {
  const _SyncFailureBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncFailureAsync = ref.watch(syncFailureProvider);

    return syncFailureAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (hasSyncFailure) {
        if (!hasSyncFailure) return const SizedBox.shrink();

        return MaterialBanner(
          content: const Text(
            'Some completions could not sync. Will retry shortly.',
          ),
          actions: [
            TextButton(
              onPressed: () => ref.invalidate(syncFailureProvider),
              child: const Text('Dismiss'),
            ),
          ],
        );
      },
    );
  }
}

/// T015 verification: AI card requirements satisfied by existing implementation.
/// - FR-010: morningCardVisibilityProvider gates MorningPromptCard (5AM–noon, Pro)
/// - FR-011: eveningCardVisibilityProvider gates EveningPromptCard (6PM–midnight, Pro)
/// - FR-012: Tapping Start navigates to chat, suppresses card for window
/// - FR-013: Dismissal (_dismissed state) suppresses card for session
/// - FR-014: AiPreviewCard renders for free-tier during morning/evening windows
/// - FR-009: MainShell (main_shell.dart) renders 4 NavigationDestination items, always visible
/// All verified — no patches required.
class _AiCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final morningAsync = ref.watch(morningCardVisibilityProvider);
    final eveningAsync = ref.watch(eveningCardVisibilityProvider);

    return morningAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (showMorning) {
        if (showMorning) return const MorningPromptCard();

        return eveningAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (showEvening) {
            if (showEvening) return const EveningPromptCard();
            if (HabitDateUtils.isMorningWindow(DateTime.now()) ||
                HabitDateUtils.isEveningWindow(DateTime.now())) {
              return const AiPreviewCard();
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
