import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';
import 'package:habit_coach/features/accountability/presentation/providers/commitment_providers.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';

/// T095: CreateCommitmentScreen — lets Pro users with an active partner create
/// a public commitment (habit + target streak + deadline).
/// Enforces the 3-active-commitment limit before submission.
class CreateCommitmentScreen extends ConsumerStatefulWidget {
  const CreateCommitmentScreen({super.key});

  @override
  ConsumerState<CreateCommitmentScreen> createState() =>
      _CreateCommitmentScreenState();
}

class _CreateCommitmentScreenState
    extends ConsumerState<CreateCommitmentScreen> {
  Habit? _selectedHabit;
  final _streakController = TextEditingController(text: '7');
  DateTime? _deadline;

  @override
  void dispose() {
    _streakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitListProvider);
    final limitReachedAsync = ref.watch(commitmentLimitReachedProvider);
    final createState = ref.watch(createCommitmentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New commitment')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (habits) {
          final activeHabits = habits.where((h) => h.isActive).toList();

          return limitReachedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (limitReached) {
              if (limitReached) {
                return const _LimitReachedView();
              }
              return _Form(
                habits: activeHabits,
                selectedHabit: _selectedHabit,
                streakController: _streakController,
                deadline: _deadline,
                isLoading: createState.isLoading,
                error: createState.error,
                onHabitChanged: (h) => setState(() => _selectedHabit = h),
                onDeadlinePicked: () => _pickDeadline(context),
                onSubmit: () => _submit(context),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final targetStreak = int.tryParse(_streakController.text) ?? 7;
    final earliest = DateTime.now().add(Duration(days: targetStreak));
    final picked = await showDatePicker(
      context: context,
      initialDate: earliest,
      firstDate: earliest,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submit(BuildContext context) async {
    final habit = _selectedHabit;
    final targetStreak = int.tryParse(_streakController.text);
    final deadline = _deadline;

    if (habit == null || targetStreak == null || deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final partnership = await ref.read(partnershipProvider.future);
    if (partnership == null || !partnership.isActive) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need an active partner to create a commitment'),
          ),
        );
      }
      return;
    }

    final partnerId = partnership.partnerIdFor(user.id);
    if (partnerId == null) return;

    await ref
        .read(createCommitmentProvider.notifier)
        .create(
          userId: user.id,
          partnerId: partnerId,
          habitId: habit.id,
          habitName: habit.name,
          targetStreak: targetStreak,
          deadline: deadline,
        );

    final state = ref.read(createCommitmentProvider);
    if (state.error == null && context.mounted) {
      context.pop();
    }
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.habits,
    required this.selectedHabit,
    required this.streakController,
    required this.deadline,
    required this.isLoading,
    required this.error,
    required this.onHabitChanged,
    required this.onDeadlinePicked,
    required this.onSubmit,
  });

  final List<Habit> habits;
  final Habit? selectedHabit;
  final TextEditingController streakController;
  final DateTime? deadline;
  final bool isLoading;
  final String? error;
  final ValueChanged<Habit?> onHabitChanged;
  final VoidCallback onDeadlinePicked;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Make a commitment to your partner',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          // Habit picker
          DropdownButtonFormField<Habit>(
            initialValue: selectedHabit,
            decoration: const InputDecoration(
              labelText: 'Habit',
              border: OutlineInputBorder(),
            ),
            items:
                habits
                    .map((h) => DropdownMenuItem(value: h, child: Text(h.name)))
                    .toList(),
            onChanged: onHabitChanged,
          ),
          const SizedBox(height: 16),
          // Target streak
          TextFormField(
            controller: streakController,
            decoration: const InputDecoration(
              labelText: 'Target streak (days)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          // Deadline picker
          OutlinedButton.icon(
            onPressed: onDeadlinePicked,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              deadline == null
                  ? 'Pick a deadline'
                  : 'Deadline: ${deadline!.year}-'
                      '${deadline!.month.toString().padLeft(2, '0')}-'
                      '${deadline!.day.toString().padLeft(2, '0')}',
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child:
                isLoading
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Commit'),
          ),
        ],
      ),
    );
  }
}

class _LimitReachedView extends StatelessWidget {
  const _LimitReachedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Commitment limit reached',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'You already have 3 active commitments. Fulfil or wait for one to expire before creating a new one.',
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
