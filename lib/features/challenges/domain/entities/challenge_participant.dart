/// T099: ChallengeParticipant domain entity — pure Dart, no Flutter imports.
enum ParticipantStatus { pending, active, left }

final class ChallengeParticipant {
  const ChallengeParticipant({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.displayName,
    required this.completionCount,
    required this.currentStreak,
    required this.status,
    required this.joinedAt,
  });

  final String id;
  final String challengeId;
  final String userId;

  /// Denormalised for leaderboard display.
  final String displayName;

  final int completionCount;
  final int currentStreak;
  final ParticipantStatus status;
  final DateTime joinedAt;

  bool get isActive => status == ParticipantStatus.active;
  bool get hasLeft => status == ParticipantStatus.left;

  ChallengeParticipant copyWith({
    int? completionCount,
    int? currentStreak,
    ParticipantStatus? status,
  }) => ChallengeParticipant(
    id: id,
    challengeId: challengeId,
    userId: userId,
    displayName: displayName,
    completionCount: completionCount ?? this.completionCount,
    currentStreak: currentStreak ?? this.currentStreak,
    status: status ?? this.status,
    joinedAt: joinedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChallengeParticipant && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
