/// T075: Partnership domain entity — pure Dart, no Flutter imports.
enum PartnershipStatus { pending, active, suspended, dissolved }

final class Partnership {
  const Partnership({
    required this.id,
    required this.inviterId,
    this.inviteeId,
    required this.inviteToken,
    required this.status,
    this.suspendedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String inviterId;

  /// Null until the invite is accepted.
  final String? inviteeId;

  /// Used for generating and validating invite links.
  final String inviteToken;

  final PartnershipStatus status;
  final DateTime? suspendedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == PartnershipStatus.pending;
  bool get isActive => status == PartnershipStatus.active;
  bool get isSuspended => status == PartnershipStatus.suspended;
  bool get isDissolvedOrSuspended =>
      status == PartnershipStatus.dissolved ||
      status == PartnershipStatus.suspended;

  /// Returns the partner's user ID relative to [currentUserId].
  String? partnerIdFor(String currentUserId) {
    if (currentUserId == inviterId) return inviteeId;
    if (currentUserId == inviteeId) return inviterId;
    return null;
  }

  Partnership copyWith({
    PartnershipStatus? status,
    String? inviteeId,
    DateTime? suspendedAt,
    DateTime? updatedAt,
  }) => Partnership(
    id: id,
    inviterId: inviterId,
    inviteeId: inviteeId ?? this.inviteeId,
    inviteToken: inviteToken,
    status: status ?? this.status,
    suspendedAt: suspendedAt ?? this.suspendedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Partnership && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Lightweight partner streak summary shown on the shared dashboard.
final class PartnerStreakSummary {
  const PartnerStreakSummary({
    required this.partnerId,
    required this.partnerName,
    required this.streaks,
    required this.completionRateToday,
  });

  final String partnerId;
  final String partnerName;

  /// Map of habit name → current streak days.
  final Map<String, int> streaks;

  /// Fraction of habits completed today (0.0 – 1.0).
  final double completionRateToday;
}
