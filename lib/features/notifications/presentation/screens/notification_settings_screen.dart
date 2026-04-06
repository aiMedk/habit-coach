import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/notifications/domain/entities/notification_preferences.dart';
import 'package:habit_coach/features/notifications/presentation/providers/notification_providers.dart';

/// T126: NotificationSettingsScreen — per-type toggles, quiet hours picker,
/// and FCM permission request.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification settings')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prefs) => _SettingsBody(preferences: prefs),
      ),
    );
  }
}

class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody({required this.preferences});
  final NotificationPreferences preferences;

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  late NotificationPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = widget.preferences;
  }

  Future<void> _save() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(updatePreferencesProvider.notifier).update(user.id, _prefs);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved')),
      );
    }
  }

  Future<void> _pickQuietHours() async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _prefs.quietHours.start, minute: 0),
      helpText: 'Quiet hours start',
    );
    if (start == null || !mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _prefs.quietHours.end, minute: 0),
      helpText: 'Quiet hours end',
    );
    if (end == null) return;

    setState(() {
      _prefs = _prefs.copyWith(
        quietHours: QuietHours(start: start.hour, end: end.hour),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Notification types',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _Toggle(
          label: 'Daily reminders',
          subtitle: 'Remind you to complete your habits',
          value: _prefs.reminder,
          onChanged:
              (v) => setState(() => _prefs = _prefs.copyWith(reminder: v)),
        ),
        _Toggle(
          label: 'Streak at risk',
          subtitle: 'Alert when a streak is about to break',
          value: _prefs.streakAtRisk,
          onChanged:
              (v) => setState(() => _prefs = _prefs.copyWith(streakAtRisk: v)),
        ),
        _Toggle(
          label: 'Milestones',
          subtitle: 'Celebrate streak milestones',
          value: _prefs.milestone,
          onChanged:
              (v) => setState(() => _prefs = _prefs.copyWith(milestone: v)),
        ),
        _Toggle(
          label: 'Partner nudges',
          subtitle: 'When your partner breaks a streak',
          value: _prefs.partnerNudge,
          onChanged:
              (v) => setState(() => _prefs = _prefs.copyWith(partnerNudge: v)),
        ),
        _Toggle(
          label: 'Challenge updates',
          subtitle: 'Leaderboard changes in your challenges',
          value: _prefs.challengeUpdate,
          onChanged:
              (v) =>
                  setState(() => _prefs = _prefs.copyWith(challengeUpdate: v)),
        ),
        const Divider(height: 32),
        Text('Quiet hours', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _prefs.quietHours.isEnabled
                ? '${_prefs.quietHours.start}:00 – ${_prefs.quietHours.end}:00'
                : 'Disabled',
          ),
          subtitle: const Text('No notifications during quiet hours'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_prefs.quietHours.isEnabled)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Disable quiet hours',
                  onPressed:
                      () => setState(
                        () =>
                            _prefs = _prefs.copyWith(
                              quietHours: const QuietHours.disabled(),
                            ),
                      ),
                ),
              TextButton(onPressed: _pickQuietHours, child: const Text('Set')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
