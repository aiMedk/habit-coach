import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/settings/data/repositories/supabase_settings_repository.dart';
import 'package:habit_coach/features/settings/domain/usecases/account_deletion_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// T140: SettingsScreen — account info, subscription, notifications,
/// block list, timezone, weekly review day, account deletion.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _settingsRepo = SupabaseSettingsRepository();
  bool _deleting = false;
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return ListView(
            children: [
              // ── Account section ────────────────────────────────────────
              _SectionHeader('Account'),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(user.displayName),
                subtitle: Text(user.email),
              ),
              ListTile(
                leading: Icon(
                  user.isPro ? Icons.workspace_premium : Icons.person_outline,
                  color:
                      user.isPro ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(user.isPro ? 'Pro plan' : 'Free plan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsSubscription),
              ),
              const Divider(height: 1),

              // ── Preferences section ────────────────────────────────────
              _SectionHeader('Preferences'),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsNotifications),
              ),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Timezone'),
                subtitle: Text(user.timezone),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickTimezone(context, user.id),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Weekly review day'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickReviewDay(context, user.id),
              ),
              const Divider(height: 1),

              // ── Privacy section ────────────────────────────────────────
              _SectionHeader('Privacy'),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('Blocked users'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsBlocked),
              ),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Sign out',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: _signingOut ? null : () => _confirmSignOut(context),
              ),
              const Divider(height: 1),

              // ── Danger zone ────────────────────────────────────────────
              _SectionHeader('Danger zone'),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete account',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text(
                  'Permanently deletes your data after 30 days',
                ),
                onTap:
                    _deleting ? null : () => _confirmDelete(context, user.id),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickTimezone(BuildContext context, String userId) async {
    // Simple text input for timezone — a full timezone picker would be a
    // separate package. For MVP, prompt the user with a text field.
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Update timezone'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'IANA timezone (e.g. America/New_York)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      await _settingsRepo.updateTimezone(userId, result);
      ref.invalidate(currentUserProvider);
    }
  }

  Future<void> _pickReviewDay(BuildContext context, String userId) async {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final result = await showDialog<int>(
      context: context,
      builder:
          (ctx) => SimpleDialog(
            title: const Text('Weekly review day'),
            children: [
              for (var i = 0; i < days.length; i++)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(i),
                  child: Text(days[i]),
                ),
            ],
          ),
    );
    if (result != null && mounted) {
      await _settingsRepo.updateReviewDay(userId, result);
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text(
              'You will need to sign in again to access your habits.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sign out'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
      // Router redirect guard will navigate to /login automatically.
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String userId) async {
    // Capture before any async gap.
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete account?'),
            content: const Text(
              'This will:\n'
              '• Cancel your Pro subscription\n'
              '• Dissolve your accountability partnership\n'
              '• Cancel your group challenges\n'
              '• Permanently delete all your data after 30 days\n\n'
              'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep account'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete account'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final useCase = AccountDeletionUseCase(Supabase.instance.client);
      await useCase.execute(userId);
      // auth state change will redirect to login via router
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
