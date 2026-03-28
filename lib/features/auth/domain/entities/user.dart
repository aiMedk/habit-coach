/// T025: User domain entity.
/// Pure Dart — no Flutter or Supabase imports permitted in the domain layer.
enum SubscriptionTier { free, pro }

enum DeletionStatus { active, pendingDeletion }

final class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.timezone,
    required this.subscriptionTier,
    required this.notificationPreferences,
    required this.deletionStatus,
    this.deletionRequestedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String timezone;
  final SubscriptionTier subscriptionTier;
  final NotificationPreferences notificationPreferences;
  final DeletionStatus deletionStatus;
  final DateTime? deletionRequestedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPro => subscriptionTier == SubscriptionTier.pro;
  bool get isPendingDeletion =>
      deletionStatus == DeletionStatus.pendingDeletion;

  AppUser copyWith({
    String? displayName,
    String? timezone,
    SubscriptionTier? subscriptionTier,
    NotificationPreferences? notificationPreferences,
    DeletionStatus? deletionStatus,
    DateTime? deletionRequestedAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      timezone: timezone ?? this.timezone,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      deletionStatus: deletionStatus ?? this.deletionStatus,
      deletionRequestedAt: deletionRequestedAt ?? this.deletionRequestedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppUser && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Per-type notification preferences stored as part of the User entity.
final class NotificationPreferences {
  const NotificationPreferences({
    this.reminder = true,
    this.streakAtRisk = true,
    this.milestone = true,
    this.partnerNudge = true,
    this.challengeUpdate = true,
  });

  final bool reminder;
  final bool streakAtRisk;
  final bool milestone;
  final bool partnerNudge;
  final bool challengeUpdate;

  static const NotificationPreferences allEnabled = NotificationPreferences();

  NotificationPreferences copyWith({
    bool? reminder,
    bool? streakAtRisk,
    bool? milestone,
    bool? partnerNudge,
    bool? challengeUpdate,
  }) {
    return NotificationPreferences(
      reminder: reminder ?? this.reminder,
      streakAtRisk: streakAtRisk ?? this.streakAtRisk,
      milestone: milestone ?? this.milestone,
      partnerNudge: partnerNudge ?? this.partnerNudge,
      challengeUpdate: challengeUpdate ?? this.challengeUpdate,
    );
  }

  Map<String, dynamic> toJson() => {
    'reminder': reminder,
    'streak_at_risk': streakAtRisk,
    'milestone': milestone,
    'partner_nudge': partnerNudge,
    'challenge_update': challengeUpdate,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        reminder: json['reminder'] as bool? ?? true,
        streakAtRisk: json['streak_at_risk'] as bool? ?? true,
        milestone: json['milestone'] as bool? ?? true,
        partnerNudge: json['partner_nudge'] as bool? ?? true,
        challengeUpdate: json['challenge_update'] as bool? ?? true,
      );
}
