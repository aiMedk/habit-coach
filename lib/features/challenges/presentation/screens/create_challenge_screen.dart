import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge.dart';
import 'package:habit_coach/features/challenges/presentation/providers/challenge_providers.dart';

/// T104: CreateChallengeScreen — habit description, mode picker, date range,
/// collaborate target % (when collaborate mode), and invite link shown on creation.
class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _descController = TextEditingController();
  final _targetPctController = TextEditingController(text: '80');
  ChallengeMode _mode = ChallengeMode.compete;
  int _maxParticipants = 5;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _descController.dispose();
    _targetPctController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createChallengeProvider);

    // Navigate to challenge detail on success
    ref.listen(createChallengeProvider, (_, next) {
      if (next.created != null && context.mounted) {
        context.pushReplacement(
          AppRoutes.challengeDetail.replaceFirst(':id', next.created!.id),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('New challenge')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Habit description
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'What habit will you all do?',
                hintText: 'e.g. Run 1 km every day',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // Mode picker
            Text('Mode', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            SegmentedButton<ChallengeMode>(
              segments: const [
                ButtonSegment(
                  value: ChallengeMode.compete,
                  icon: Icon(Icons.emoji_events_outlined),
                  label: Text('Compete'),
                ),
                ButtonSegment(
                  value: ChallengeMode.collaborate,
                  icon: Icon(Icons.handshake_outlined),
                  label: Text('Collaborate'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            if (_mode == ChallengeMode.collaborate) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetPctController,
                decoration: const InputDecoration(
                  labelText: 'Group target completion % (1–100)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 16),
            // Date range
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                _dateRange == null
                    ? 'Pick start & end date'
                    : '${_fmt(_dateRange!.start)} → ${_fmt(_dateRange!.end)}',
              ),
            ),
            const SizedBox(height: 16),
            // Max participants
            Row(
              children: [
                Text(
                  'Max participants',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _maxParticipants,
                  items:
                      [2, 3, 4, 5]
                          .map(
                            (n) =>
                                DropdownMenuItem(value: n, child: Text('$n')),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _maxParticipants = v ?? 5),
                ),
              ],
            ),
            if (createState.error != null) ...[
              const SizedBox(height: 12),
              Text(
                createState.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: createState.isLoading ? null : _submit,
              child:
                  createState.isLoading
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Create challenge'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange:
          _dateRange ??
          DateTimeRange(
            start: now.add(const Duration(days: 1)),
            end: now.add(const Duration(days: 31)),
          ),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _submit() async {
    final desc = _descController.text.trim();
    final range = _dateRange;

    if (desc.isEmpty || range == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    int? targetPct;
    if (_mode == ChallengeMode.collaborate) {
      targetPct = int.tryParse(_targetPctController.text);
      if (targetPct == null || targetPct < 1 || targetPct > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collaborate target must be between 1 and 100'),
          ),
        );
        return;
      }
    }

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    await ref
        .read(createChallengeProvider.notifier)
        .create(
          creatorId: user.id,
          habitDescription: desc,
          mode: _mode,
          startDate: range.start,
          endDate: range.end,
          maxParticipants: _maxParticipants,
          collaborateTargetPct: targetPct,
        );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
