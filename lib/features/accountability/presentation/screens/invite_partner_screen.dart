import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/accountability/domain/entities/partnership.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';

/// T084: InvitePartnerScreen — lets Pro users invite a friend as an
/// accountability partner via a shareable invite link.
class InvitePartnerScreen extends ConsumerWidget {
  const InvitePartnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnershipAsync = ref.watch(partnershipProvider);
    final inviteState = ref.watch(inviteNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invite a partner')),
      body: partnershipAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (existing) {
          if (existing != null && existing.isActive) {
            return _ActivePartnershipView(partnership: existing);
          }
          if (existing != null && existing.isPending) {
            return _PendingInviteView(partnership: existing);
          }
          return _CreateInviteView(inviteState: inviteState);
        },
      ),
    );
  }
}

/// No partnership yet — show "Create invite" button.
class _CreateInviteView extends ConsumerWidget {
  const _CreateInviteView({required this.inviteState});
  final InviteState inviteState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Invite an accountability partner',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Share a link with a friend. You\'ll be able to see each other\'s streaks and cheer each other on.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (inviteState.error != null) ...[
              const SizedBox(height: 12),
              Text(
                inviteState.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed:
                  inviteState.isLoading
                      ? null
                      : () async {
                        final user = await ref.read(currentUserProvider.future);
                        if (user == null) return;
                        await ref
                            .read(inviteNotifierProvider.notifier)
                            .createInvite();
                        ref.invalidate(partnershipProvider);
                      },
              icon:
                  inviteState.isLoading
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.link),
              label: const Text('Generate invite link'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Invite link generated — show link to copy/share.
class _PendingInviteView extends StatelessWidget {
  const _PendingInviteView({required this.partnership});
  final Partnership partnership;

  String get _inviteLink => 'habitcoach://invite/${partnership.inviteToken}';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Waiting for your partner',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Share this link with your friend. It expires in 7 days.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _InviteLinkCard(link: _inviteLink),
          ],
        ),
      ),
    );
  }
}

/// Already has an active partner.
class _ActivePartnershipView extends StatelessWidget {
  const _ActivePartnershipView({required this.partnership});
  final Partnership partnership;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'You already have a partner!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Dissolve your current partnership first to invite someone new.',
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

class _InviteLinkCard extends StatelessWidget {
  const _InviteLinkCard({required this.link});
  final String link;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              link,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy link'),
            ),
          ],
        ),
      ),
    );
  }
}
