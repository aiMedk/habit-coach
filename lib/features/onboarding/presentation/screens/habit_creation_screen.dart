import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/onboarding/presentation/providers/onboarding_providers.dart';

/// T047b: Habit creation screen — second onboarding step and post-onboarding
/// add-habit entry point.
///
/// [afterSaveRoute] controls where the app navigates after a habit is saved.
/// Defaults to [AppRoutes.onboardingComplete] (onboarding flow).
/// Pass [AppRoutes.dashboard] when opened from the dashboard FAB.
class HabitCreationScreen extends ConsumerStatefulWidget {
  const HabitCreationScreen({super.key, this.afterSaveRoute});

  final String? afterSaveRoute;

  @override
  ConsumerState<HabitCreationScreen> createState() =>
      _HabitCreationScreenState();
}

class _HabitCreationScreenState extends ConsumerState<HabitCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  HabitFrequency _frequency = HabitFrequency.daily;
  final List<bool> _selectedDays = List.filled(7, false);
  bool _submitting = false;
  String? _error;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your first habit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  _ErrorBanner(
                    message: _error!,
                    onDismiss: () => setState(() => _error = null),
                  ),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Habit name',
                    hintText: 'e.g. Morning meditation',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a habit name';
                    }
                    if (v.trim().length > 80) {
                      return 'Name must be 80 characters or fewer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g. 10 minutes of mindful breathing',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Text(
                  'Frequency',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _FrequencySelector(
                  selected: _frequency,
                  onChanged: (f) => setState(() => _frequency = f),
                ),
                if (_frequency == HabitFrequency.specificDays) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Which days?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _DayPicker(
                    selected: _selectedDays,
                    labels: _dayLabels,
                    onToggle:
                        (i) => setState(
                          () => _selectedDays[i] = !_selectedDays[i],
                        ),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child:
                      _submitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Create habit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frequency == HabitFrequency.specificDays &&
        !_selectedDays.contains(true)) {
      setState(() => _error = 'Please select at least one day');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final useCaseAsync = ref.read(onboardingUseCaseProvider);
      final useCase = useCaseAsync.valueOrNull;
      if (useCase == null) {
        setState(() => _error = 'Loading — please try again.');
        return;
      }

      final frequencyDays =
          _frequency == HabitFrequency.specificDays
              ? _selectedDays
                  .asMap()
                  .entries
                  .where((e) => e.value)
                  .map((e) => e.key)
                  .toList()
              : null;

      await useCase.createFirstHabit(
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        frequency: _frequency,
        frequencyDays: frequencyDays,
      );

      final dest = widget.afterSaveRoute ?? AppRoutes.onboardingComplete;
      if (mounted) context.pushReplacement(dest);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({required this.selected, required this.onChanged});

  final HabitFrequency selected;
  final ValueChanged<HabitFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<HabitFrequency>(
      segments: const [
        ButtonSegment(value: HabitFrequency.daily, label: Text('Every day')),
        ButtonSegment(
          value: HabitFrequency.specificDays,
          label: Text('Specific days'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({
    required this.selected,
    required this.labels,
    required this.onToggle,
  });

  final List<bool> selected;
  final List<String> labels;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        return FilterChip(
          label: Text(labels[i]),
          selected: selected[i],
          onSelected: (_) => onToggle(i),
          padding: EdgeInsets.zero,
        );
      }),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onDismiss,
            color: Theme.of(context).colorScheme.onErrorContainer,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
