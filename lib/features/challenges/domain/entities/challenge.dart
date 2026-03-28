/// T098: Challenge domain entity — pure Dart, no Flutter imports.
enum ChallengeMode { compete, collaborate }

enum ChallengeStatus { pending, active, completed, cancelled }

final class Challenge {
  const Challenge({
    required this.id,
    required this.creatorId,
    required this.habitDescription,
    required this.mode,
    required this.startDate,
    required this.endDate,
    required this.maxParticipants,
    this.collaborateTargetPct,
    required this.inviteToken,
    required this.status,
    required this.participantCount,
    required this.createdAt,
    this.purgeAt,
  });

  final String id;
  final String creatorId;

  /// Describes the habit participants commit to (max 200 chars).
  final String habitDescription;

  final ChallengeMode mode;
  final DateTime startDate;
  final DateTime endDate;

  /// 2–5 participants.
  final int maxParticipants;

  /// Required when mode is [ChallengeMode.collaborate].
  final int? collaborateTargetPct;

  /// Used for shareable invite links.
  final String inviteToken;

  final ChallengeStatus status;

  /// Denormalised participant count for quick display.
  final int participantCount;

  final DateTime createdAt;
  final DateTime? purgeAt;

  bool get isPending => status == ChallengeStatus.pending;
  bool get isActive => status == ChallengeStatus.active;
  bool get isCompleted => status == ChallengeStatus.completed;
  bool get isCancelled => status == ChallengeStatus.cancelled;
  bool get isOpen => isPending || isActive;

  /// True if the challenge can still accept participants.
  bool get hasCapacity => participantCount < maxParticipants;

  /// Duration of the challenge in days.
  int get durationDays => endDate.difference(startDate).inDays;

  Challenge copyWith({ChallengeStatus? status, int? participantCount}) =>
      Challenge(
        id: id,
        creatorId: creatorId,
        habitDescription: habitDescription,
        mode: mode,
        startDate: startDate,
        endDate: endDate,
        maxParticipants: maxParticipants,
        collaborateTargetPct: collaborateTargetPct,
        inviteToken: inviteToken,
        status: status ?? this.status,
        participantCount: participantCount ?? this.participantCount,
        createdAt: createdAt,
        purgeAt: purgeAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Challenge && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
