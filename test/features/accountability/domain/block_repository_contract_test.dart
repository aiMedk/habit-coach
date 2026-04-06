import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/settings/domain/entities/blocked_user.dart';
import 'package:habit_coach/features/settings/domain/repositories/block_repository.dart';

void main() {
  late BlockRepository repo;

  setUp(() {
    repo = _FakeBlockRepository();
  });

  test('blockUser returns a BlockedUser', () async {
    final b = await repo.blockUser(blockerId: 'u1', targetUserId: 'u2');
    expect(b.blockerId, equals('u1'));
    expect(b.blockedId, equals('u2'));
  });

  test('getBlockedUsers returns empty list initially', () async {
    final list = await repo.getBlockedUsers('nobody');
    expect(list, isEmpty);
  });

  test('getBlockedUsers returns blocked users after block', () async {
    await repo.blockUser(blockerId: 'u1', targetUserId: 'u2');
    await repo.blockUser(blockerId: 'u1', targetUserId: 'u3');
    final list = await repo.getBlockedUsers('u1');
    expect(list.length, equals(2));
  });

  test('isBlocked returns true after blocking', () async {
    await repo.blockUser(blockerId: 'u1', targetUserId: 'u2');
    expect(await repo.isBlocked(userId1: 'u1', userId2: 'u2'), isTrue);
  });

  test('isBlocked is bidirectional', () async {
    await repo.blockUser(blockerId: 'u1', targetUserId: 'u2');
    expect(await repo.isBlocked(userId1: 'u2', userId2: 'u1'), isTrue);
  });

  test('unblockUser removes the block', () async {
    await repo.blockUser(blockerId: 'u1', targetUserId: 'u2');
    await repo.unblockUser(blockerId: 'u1', blockedUserId: 'u2');
    expect(await repo.isBlocked(userId1: 'u1', userId2: 'u2'), isFalse);
  });
}

// ── Fake implementation ───────────────────────────────────────────────────────

class _FakeBlockRepository implements BlockRepository {
  final _blocks = <(String, String)>{};

  @override
  Future<BlockedUser> blockUser({
    required String blockerId,
    required String targetUserId,
  }) async {
    _blocks.add((blockerId, targetUserId));
    return BlockedUser(
      id: '$blockerId-$targetUserId',
      blockerId: blockerId,
      blockedId: targetUserId,
      blockedDisplayName: 'User $targetUserId',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    _blocks.remove((blockerId, blockedUserId));
  }

  @override
  Future<List<BlockedUser>> getBlockedUsers(String blockerId) async {
    return _blocks
        .where((pair) => pair.$1 == blockerId)
        .map(
          (pair) => BlockedUser(
            id: '${pair.$1}-${pair.$2}',
            blockerId: pair.$1,
            blockedId: pair.$2,
            blockedDisplayName: 'User ${pair.$2}',
            createdAt: DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  Future<bool> isBlocked({
    required String userId1,
    required String userId2,
  }) async {
    return _blocks.contains((userId1, userId2)) ||
        _blocks.contains((userId2, userId1));
  }
}
