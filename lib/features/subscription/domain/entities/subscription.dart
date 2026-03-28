import 'package:habit_coach/features/auth/domain/entities/user.dart';

/// Domain entity representing the user's subscription record.
/// Mirrors data-model.md Subscription entity — pure Dart.
enum SubscriptionStatus { active, cancelled, expired }

enum Platform { ios, android }

final class Subscription {
  const Subscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.status,
    required this.platform,
    this.revenuecatId,
    this.startedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final Platform platform;
  final String? revenuecatId;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPro =>
      tier == SubscriptionTier.pro && status == SubscriptionStatus.active;

  bool get isExpired =>
      status == SubscriptionStatus.expired ||
      (expiresAt != null && expiresAt!.isBefore(DateTime.now()));
}
