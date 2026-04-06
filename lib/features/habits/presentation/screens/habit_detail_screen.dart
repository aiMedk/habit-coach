import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';
import 'package:habit_coach/features/habits/presentation/widgets/completion_calendar.dart';
import 'package:habit_coach/features/habits/presentation/widgets/streak_badge.dart';

/// T050: HabitDetailScreen — shows streak, completion calendar, and allows
/// editing or deactivating the habit.
class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitByIdProvider(habitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context, ref),
          ),
        ],
      ),
      body: habitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (habit) {
          if (habit == null) {
            return const Center(child: Text('Habit not found'));
          }
          return _HabitDetailBody(habit: habit);
        },
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final repo = await ref.read(habitRepositoryProvider.future);
    final habit = await repo.getHabitById(habitId);
    if (habit == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _EditHabitDialog(habit: habit, ref: ref),
    );
  }
}

class _HabitDetailBody extends ConsumerWidget {
  const _HabitDetailBody({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider(habit.id));
    final completionsAsync = ref.watch(habitCompletionsProvider(habit.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (habit.description != null)
                      Text(
                        habit.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              streakAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (s) => StreakBadge(streak: s),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Streak stats
          streakAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data:
                (streak) => _StreakStats(
                  current: streak.currentCount,
                  longest: streak.longestCount,
                ),
          ),
          const SizedBox(height: 24),
          // Calendar
          completionsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (completions) {
              final dates = completions.map((c) => c.localDate).toSet();
              return CompletionCalendar(completedDates: dates);
            },
          ),
          const SizedBox(height: 32),
          // Deactivate
          OutlinedButton.icon(
            onPressed: () => _confirmDeactivate(context, ref),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive habit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Archive habit?'),
            content: const Text(
              'Archiving will hide the habit from your dashboard. '
              'You can reactivate it later.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Archive'),
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;
    final repo = await ref.read(habitRepositoryProvider.future);
    await repo.deactivateHabit(habit.id);
    ref.invalidate(habitListProvider);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _StreakStats extends StatelessWidget {
  const _StreakStats({required this.current, required this.longest});

  final int current;
  final int longest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Current streak', value: '$current')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Longest streak', value: '$longest')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditHabitDialog extends ConsumerStatefulWidget {
  const _EditHabitDialog({required this.habit, required this.ref});

  final Habit habit;
  final WidgetRef ref;

  @override
  ConsumerState<_EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends ConsumerState<_EditHabitDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _descriptionController = TextEditingController(
      text: widget.habit.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit habit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child:
              _saving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = await ref.read(habitRepositoryProvider.future);
      await repo.updateHabit(
        widget.habit.copyWith(
          name: name,
          description:
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
        ),
      );
      ref.invalidate(habitListProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
