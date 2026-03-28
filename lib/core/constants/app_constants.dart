/// T009: App-wide constants.
/// All business rule limits are defined here so they can be updated in one place.
abstract final class AppConstants {
  // ── Free tier limits ──────────────────────────────────────────────────────
  /// Maximum number of active habits on the free tier.
  static const int freeTierHabitLimit = 3;

  // ── Accountability limits ─────────────────────────────────────────────────
  /// Maximum active commitments a user may hold at once.
  static const int maxActiveCommitments = 3;

  /// Maximum active group challenges a user may participate in at once.
  static const int maxActiveChallenges = 3;

  /// Maximum participants in a single group challenge (including creator).
  static const int maxChallengeParticipants = 5;

  // ── Completion rules ──────────────────────────────────────────────────────
  /// Window (in minutes) after a completion during which it can be undone.
  static const int undoWindowMinutes = 5;

  // ── AI coaching limits ────────────────────────────────────────────────────
  /// Maximum number of messages (user + assistant) in a single conversation.
  static const int conversationTurnLimit = 20;

  /// Number of days conversations and weekly reviews are retained.
  static const int retentionDays = 90;

  // ── Partnership & invite expiry ───────────────────────────────────────────
  /// Days before a pending partnership invite expires.
  static const int partnerInviteExpiryDays = 7;

  /// Hours before a challenge start_date when the challenge invite expires.
  static const int challengeInviteExpiryHoursBeforeStart = 48;

  /// Days before a suspended partnership is automatically dissolved.
  static const int partnershipSuspensionDissolveDays = 90;

  // ── Account deletion ──────────────────────────────────────────────────────
  /// Grace period (in days) before a pending deletion account is permanently purged.
  static const int deletionGracePeriodDays = 30;

  // ── Notification fatigue ──────────────────────────────────────────────────
  /// Number of consecutive days without notification response before
  /// the push-scheduler reduces frequency for a user.
  static const int notificationFatigueDays = 3;

  // ── AI service ────────────────────────────────────────────────────────────
  /// Timeout (in seconds) waiting for first token from the AI service.
  static const int aiFirstTokenTimeoutSeconds = 5;
}
