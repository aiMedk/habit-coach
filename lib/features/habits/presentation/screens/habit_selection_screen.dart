import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/constants/app_constants.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';

/// T135: HabitSelectionScreen — shown after Pro downgrade when the user has
/// more than [AppConstants.freeTierHabitLimit] active habits.
///
/// The user selects which habits to keep active (max 3). The rest are
/// deactivated. Cannot be dismissed without making a selection.
class HabitSelectionScreen extends ConsumerStatefulWidget {
  const HabitSelectionScreen({super.key});

  @override
  ConsumerState<HabitSelectionScreen> createState() =>
      _HabitSelectionScreenState();
}

class _HabitSelectionScreenState extends ConsumerState<HabitSelectionScreen> {
  final Set<String> _selected = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitListProvider);

    return PopScope(
      canPop: false, // Must complete selection
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Choose your habits'),
          automaticallyImplyLeading: false,
        ),
        body: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (habits) {
            final active = habits.where((h) => h.isActive).toList();
            if (active.length <= AppConstants.freeTierHabitLimit) {
              // Nothing to select — navigate away.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go(AppRoutes.dashboard);
              });
              return const SizedBox.shrink();
            }
            return _SelectionBody(
              habits: active,
              selected: _selected,
              saving: _saving,
              onToggle: _toggle,
              onConfirm: _confirm,
            );
          },
        ),
      ),
    );
  }

  void _toggle(String habitId) {
    setState(() {
      if (_selected.contains(habitId)) {
        _selected.remove(habitId);
      } else if (_selected.length < AppConstants.freeTierHabitLimit) {
        _selected.add(habitId);
      }
    });
  }

  Future<void> _confirm(List<Habit> activeHabits) async {
    if (_selected.length != AppConstants.freeTierHabitLimit) return;
    setState(() => _saving = true);

    final repo = await ref.read(habitRepositoryProvider.future);
    final toDeactivate = activeHabits
        .where((h) => !_selected.contains(h.id))
        .map((h) => h.id);

    for (final id in toDeactivate) {
      await repo.deactivateHabit(id);
    }

    if (mounted) context.go(AppRoutes.dashboard);
  }
}

class _SelectionBody extends StatelessWidget {
  const _SelectionBody({
    required this.habits,
    required this.selected,
    required this.saving,
    required this.onToggle,
    required this.onConfirm,
  });

  final List<Habit> habits;
  final Set<String> selected;
  final bool saving;
  final ValueChanged<String> onToggle;
  final ValueChanged<List<Habit>> onConfirm;

  @override
  Widget build(BuildContext context) {
    final limit = AppConstants.freeTierHabitLimit;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Theme.of(context).colorScheme.primary,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Your subscription has ended',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Free plan allows $limit active habits. '
                'Choose which $limit to keep.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${selected.length} / $limit selected',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: habits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final habit = habits[i];
              final isSelected = selected.contains(habit.id);
              final canSelect = isSelected || selected.length < limit;
              return CheckboxListTile(
                value: isSelected,
                onChanged: canSelect ? (_) => onToggle(habit.id) : null,
                title: Text(habit.name),
                secondary:
                    isSelected
                        ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                        : const Icon(Icons.circle_outlined),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed:
                    selected.length == limit && !saving
                        ? () => onConfirm(habits)
                        : null,
                child:
                    saving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Confirm selection'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
