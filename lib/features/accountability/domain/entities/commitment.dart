/// T090: Commitment domain entity — pure Dart, no Flutter imports.
enum CommitmentStatus { active, fulfilled, failed }

final class Commitment {
  const Commitment({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.habitId,
    required this.habitName,
    required this.targetStreak,
    required this.deadline,
    required this.status,
    required this.currentStreak,
    required this.createdAt,
  });

  final String id;
  final String userId;

  /// The accountability partner who can see this commitment.
  final String partnerId;

  final String habitId;

  /// Denormalised for display without an extra habits query.
  final String habitName;

  /// Target consecutive days the user commits to completing the habit.
  final int targetStreak;

  /// The date by which the target streak must be achieved.
  final DateTime deadline;

  final CommitmentStatus status;

  /// Current streak count at time of last sync (not stored in DB — derived).
  final int currentStreak;

  final DateTime createdAt;

  bool get isActive => status == CommitmentStatus.active;
  bool get isFulfilled => status == CommitmentStatus.fulfilled;
  bool get isFailed => status == CommitmentStatus.failed;

  /// Fraction of target achieved (0.0 – 1.0, capped at 1.0).
  double get progress =>
      targetStreak == 0 ? 0.0 : (currentStreak / targetStreak).clamp(0.0, 1.0);

  /// Days remaining until deadline (negative if past).
  int get daysRemaining => deadline.difference(DateTime.now()).inDays;

  Commitment copyWith({CommitmentStatus? status, int? currentStreak}) =>
      Commitment(
        id: id,
        userId: userId,
        partnerId: partnerId,
        habitId: habitId,
        habitName: habitName,
        targetStreak: targetStreak,
        deadline: deadline,
        status: status ?? this.status,
        currentStreak: currentStreak ?? this.currentStreak,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Commitment && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
