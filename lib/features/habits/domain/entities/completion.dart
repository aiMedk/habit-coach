/// T036: Completion domain entity — pure Dart, no Flutter imports.
final class Completion {
  const Completion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    required this.localDate,
    required this.isUndone,
    required this.createdAt,
  });

  final String id;
  final String habitId;
  final String userId;

  /// Client-provided timestamp of when the user tapped "complete".
  final DateTime completedAt;

  /// Calendar date in user's timezone (yyyy-MM-dd string). Immutable once written.
  final String localDate;

  /// True if the user undid this completion within the 5-minute window.
  final bool isUndone;

  final DateTime createdAt;

  bool get isActive => !isUndone;

  Completion copyWith({bool? isUndone}) => Completion(
    id: id,
    habitId: habitId,
    userId: userId,
    completedAt: completedAt,
    localDate: localDate,
    isUndone: isUndone ?? this.isUndone,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Completion && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
