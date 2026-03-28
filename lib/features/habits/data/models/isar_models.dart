import 'package:isar/isar.dart';

// T033: Isar schema definitions for local offline cache.
// Run `dart run build_runner build` (with pinned isar_generator 3.1.0+1) to
// regenerate the *.g.dart files.
//
// Note: firebase_options.dart and *.g.dart are in .gitignore.
// The generated parts are included below — regenerate after schema changes.

part 'isar_models.g.dart';

/// Local cache model for Habit.
/// Mirrors the domain Habit entity fields relevant for offline display.
@collection
class HabitLocal {
  HabitLocal({
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

  Id get isarId => Isar.autoIncrement;

  /// Supabase UUID — used for sync
  @Index(unique: true)
  late String id;

  @Index()
  late String userId;

  late String name;
  late String? description;

  /// 'daily' or 'specific_days'
  late String frequency;

  /// Day-of-week indices (0=Mon … 6=Sun) for specific_days frequency
  late List<int>? frequencyDays;

  late bool isActive;
  late DateTime createdAt;
  late DateTime updatedAt;
}

/// Local cache model for Completion.
@collection
class CompletionLocal {
  CompletionLocal({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    required this.localDate,
    required this.isUndone,
    required this.createdAt,
    this.syncedAt,
  });

  Id get isarId => Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index()
  late String habitId;

  @Index()
  late String userId;

  late DateTime completedAt;

  /// yyyy-MM-dd as a string for easy date queries
  @Index(composite: [CompositeIndex('habitId')])
  late String localDate;

  late bool isUndone;
  late DateTime createdAt;

  /// Null until successfully synced to Supabase
  late DateTime? syncedAt;

  bool get isPendingSync => syncedAt == null && !isUndone;
}

/// Local cache model for Conversation (AI check-ins).
@collection
class ConversationLocal {
  ConversationLocal({
    required this.id,
    required this.userId,
    required this.type,
    required this.date,
    required this.messagesJson,
    required this.expiresAt,
    required this.createdAt,
  });

  Id get isarId => Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index()
  late String userId;

  /// 'morning' or 'evening'
  late String type;

  @Index(composite: [CompositeIndex('type'), CompositeIndex('userId')])
  late String date;

  /// JSON-encoded messages array
  late String messagesJson;

  late DateTime expiresAt;
  late DateTime createdAt;
}
