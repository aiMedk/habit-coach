/// T119: NotificationPreferences entity — pure Dart, no Flutter imports.

/// Notification type keys that map directly to the JSONB column in users.
enum NotificationType {
  reminder,
  streakAtRisk,
  milestone,
  partnerNudge,
  challengeUpdate,
}

/// Quiet hours window — no notifications sent between [start] and [end].
/// Both values are 0-23 (hour of day in user's local timezone).
/// When [start] == [end] the quiet hours feature is disabled.
final class QuietHours {
  const QuietHours({required this.start, required this.end});

  /// Quiet hours disabled (start == end).
  const QuietHours.disabled() : start = 0, end = 0;

  final int start;
  final int end;

  bool get isEnabled => start != end;

  /// Returns true if [hour] (0-23) falls within the quiet window.
  bool contains(int hour) {
    if (!isEnabled) return false;
    if (start < end) return hour >= start && hour < end;
    // Wraps midnight, e.g. 22 → 7
    return hour >= start || hour < end;
  }

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  factory QuietHours.fromJson(Map<String, dynamic> j) => QuietHours(
    start: (j['start'] as num?)?.toInt() ?? 0,
    end: (j['end'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuietHours && other.start == start && other.end == end);

  @override
  int get hashCode => Object.hash(start, end);
}

final class NotificationPreferences {
  const NotificationPreferences({
    this.reminder = true,
    this.streakAtRisk = true,
    this.milestone = true,
    this.partnerNudge = true,
    this.challengeUpdate = true,
    this.quietHours = const QuietHours.disabled(),
  });

  final bool reminder;
  final bool streakAtRisk;
  final bool milestone;
  final bool partnerNudge;
  final bool challengeUpdate;
  final QuietHours quietHours;

  /// Returns whether the given [type] is enabled.
  bool isEnabled(NotificationType type) => switch (type) {
    NotificationType.reminder => reminder,
    NotificationType.streakAtRisk => streakAtRisk,
    NotificationType.milestone => milestone,
    NotificationType.partnerNudge => partnerNudge,
    NotificationType.challengeUpdate => challengeUpdate,
  };

  NotificationPreferences copyWith({
    bool? reminder,
    bool? streakAtRisk,
    bool? milestone,
    bool? partnerNudge,
    bool? challengeUpdate,
    QuietHours? quietHours,
  }) => NotificationPreferences(
    reminder: reminder ?? this.reminder,
    streakAtRisk: streakAtRisk ?? this.streakAtRisk,
    milestone: milestone ?? this.milestone,
    partnerNudge: partnerNudge ?? this.partnerNudge,
    challengeUpdate: challengeUpdate ?? this.challengeUpdate,
    quietHours: quietHours ?? this.quietHours,
  );

  Map<String, dynamic> toJson() => {
    'reminder': reminder,
    'streak_at_risk': streakAtRisk,
    'milestone': milestone,
    'partner_nudge': partnerNudge,
    'challenge_update': challengeUpdate,
    'quiet_hours': quietHours.toJson(),
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> j) =>
      NotificationPreferences(
        reminder: j['reminder'] as bool? ?? true,
        streakAtRisk: j['streak_at_risk'] as bool? ?? true,
        milestone: j['milestone'] as bool? ?? true,
        partnerNudge: j['partner_nudge'] as bool? ?? true,
        challengeUpdate: j['challenge_update'] as bool? ?? true,
        quietHours:
            j['quiet_hours'] != null
                ? QuietHours.fromJson(j['quiet_hours'] as Map<String, dynamic>)
                : const QuietHours.disabled(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationPreferences &&
          other.reminder == reminder &&
          other.streakAtRisk == streakAtRisk &&
          other.milestone == milestone &&
          other.partnerNudge == partnerNudge &&
          other.challengeUpdate == challengeUpdate &&
          other.quietHours == quietHours);

  @override
  int get hashCode => Object.hash(
    reminder,
    streakAtRisk,
    milestone,
    partnerNudge,
    challengeUpdate,
    quietHours,
  );
}
