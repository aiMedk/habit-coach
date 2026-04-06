/// T076: BlockedUser domain entity — pure Dart, no Flutter imports.
final class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.blockedDisplayName,
    required this.createdAt,
  });

  final String id;
  final String blockerId;
  final String blockedId;

  /// Cached display name of the blocked user for list rendering.
  final String blockedDisplayName;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockedUser &&
          other.blockerId == blockerId &&
          other.blockedId == blockedId);

  @override
  int get hashCode => Object.hash(blockerId, blockedId);
}
