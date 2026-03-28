import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge.dart';
import 'package:habit_coach/features/challenges/presentation/providers/challenge_providers.dart';
import 'package:habit_coach/features/challenges/presentation/widgets/leaderboard_widget.dart';

/// T105: ChallengeDetailScreen — shows challenge info, participant list,
/// leaderboard ranked by completion rate and streak length.
class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeDetailProvider(challengeId));
    final leaderboardAsync = ref.watch(leaderboardProvider(challengeId));
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (challenge) {
          if (challenge == null) {
            return const Center(child: Text('Challenge not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ChallengeHeader(challenge: challenge),
                const SizedBox(height: 24),
                // Invite link (only for open challenges)
                if (challenge.isOpen)
                  _InviteCard(inviteToken: challenge.inviteToken),
                const SizedBox(height: 24),
                Text(
                  'Leaderboard',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                leaderboardAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data:
                      (participants) => currentUserAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data:
                            (user) => LeaderboardWidget(
                              participants: participants,
                              currentUserId: user?.id ?? '',
                            ),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChallengeHeader extends StatelessWidget {
  const _ChallengeHeader({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.habitDescription,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _StatusChip(status: challenge.status),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.people_outline,
              label:
                  '${challenge.participantCount} / ${challenge.maxParticipants} participants',
            ),
            _InfoRow(
              icon:
                  challenge.mode == ChallengeMode.compete
                      ? Icons.emoji_events_outlined
                      : Icons.handshake_outlined,
              label:
                  challenge.mode == ChallengeMode.compete
                      ? 'Compete mode'
                      : 'Collaborate mode'
                          '${challenge.collaborateTargetPct != null ? ' — ${challenge.collaborateTargetPct}% target' : ''}',
            ),
            _InfoRow(
              icon: Icons.date_range,
              label:
                  '${_fmt(challenge.startDate)} → ${_fmt(challenge.endDate)}',
            ),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: '${challenge.durationDays} days',
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ChallengeStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ChallengeStatus.pending => ('Pending', Colors.orange),
      ChallengeStatus.active => (
        'Active',
        Theme.of(context).colorScheme.primary,
      ),
      ChallengeStatus.completed => ('Completed', Colors.green),
      ChallengeStatus.cancelled => (
        'Cancelled',
        Theme.of(context).colorScheme.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.inviteToken});
  final String inviteToken;

  String get _link => 'habitcoach://challenge/$inviteToken';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Invite link', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            SelectableText(
              _link,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _link));
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
