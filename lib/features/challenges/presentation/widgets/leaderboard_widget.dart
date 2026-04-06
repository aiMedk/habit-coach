import 'package:flutter/material.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge_participant.dart';

/// T106: LeaderboardWidget — ranked participant list with completion bars
/// and a crown icon for the leader.
class LeaderboardWidget extends StatelessWidget {
  const LeaderboardWidget({
    super.key,
    required this.participants,
    required this.currentUserId,
  });

  /// Already sorted by [ChallengeRepository.getLeaderboard].
  final List<ChallengeParticipant> participants;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Center(
        child: Text(
          'No participants yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final maxCount = participants
        .map((p) => p.completionCount)
        .fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          participants.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final p = entry.value;
            final isMe = p.userId == currentUserId;
            final barValue = maxCount > 0 ? p.completionCount / maxCount : 0.0;

            return _LeaderboardRow(
              rank: rank,
              participant: p,
              barValue: barValue.toDouble(),
              isMe: isMe,
              isLeader: rank == 1,
            );
          }).toList(),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.participant,
    required this.barValue,
    required this.isMe,
    required this.isLeader,
  });

  final int rank;
  final ChallengeParticipant participant;
  final double barValue;
  final bool isMe;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rowColor = isMe ? cs.primaryContainer.withAlpha(80) : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(8),
        border: isMe ? Border.all(color: cs.primary.withAlpha(100)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child:
                    isLeader
                        ? const Icon(
                          Icons.emoji_events,
                          size: 20,
                          color: Colors.amber,
                        )
                        : Text(
                          '$rank',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
              ),
              Expanded(
                child: Text(
                  isMe
                      ? '${participant.displayName} (you)'
                      : participant.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                '${participant.completionCount} days',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: barValue,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
            color: isLeader ? Colors.amber : cs.primary,
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}
