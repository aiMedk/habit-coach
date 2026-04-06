/// T035: Habit domain entity — pure Dart, no Flutter imports.
enum HabitFrequency { daily, specificDays }

final class Habit {
  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.frequency,
    this.frequencyDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final HabitFrequency frequency;

  /// Day-of-week indices: 0 = Monday … 6 = Sunday.
  /// Required when [frequency] is [HabitFrequency.specificDays].
  final List<int>? frequencyDays;

  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns true if this habit is scheduled on the given [weekday]
  /// (1 = Monday … 7 = Sunday, matching [DateTime.weekday]).
  bool isScheduledOn(int weekday) {
    if (frequency == HabitFrequency.daily) return true;
    // frequencyDays uses 0-indexed Mon=0; DateTime.weekday uses 1-indexed Mon=1
    final zeroIndexed = weekday - 1;
    return frequencyDays?.contains(zeroIndexed) ?? false;
  }

  Habit copyWith({
    String? name,
    String? description,
    HabitFrequency? frequency,
    List<int>? frequencyDays,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Habit && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
