import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/accountability/domain/entities/partnership.dart';
import 'package:habit_coach/features/accountability/domain/repositories/partner_repository.dart';

/// Contract tests for PartnerRepository.
/// These tests run against a fake in-memory implementation to validate the
/// contract expectations without hitting Supabase.
void main() {
  late PartnerRepository repo;

  setUp(() {
    repo = _FakePartnerRepository();
  });

  test('invitePartner returns pending partnership', () async {
    final p = await repo.invitePartner('user-1');
    expect(p.isPending, isTrue);
    expect(p.inviterId, equals('user-1'));
    expect(p.inviteToken, isNotEmpty);
  });

  test('getPartnership returns null when none exists', () async {
    final p = await repo.getPartnership('unknown');
    expect(p, isNull);
  });

  test('acceptInvite activates the partnership', () async {
    final pending = await repo.invitePartner('inviter');
    final active = await repo.acceptInvite(
      inviteToken: pending.inviteToken,
      inviteeId: 'invitee',
    );
    expect(active.isActive, isTrue);
    expect(active.inviteeId, equals('invitee'));
  });

  test('acceptInvite throws on invalid token', () async {
    await expectLater(
      () => repo.acceptInvite(inviteToken: 'bad-token', inviteeId: 'u'),
      throwsException,
    );
  });

  test('dissolvePartnership removes the partnership', () async {
    final p = await repo.invitePartner('user-1');
    await repo.dissolvePartnership(p.id);
    final after = await repo.getPartnership('user-1');
    expect(after, isNull);
  });
}

// ── Fake implementation ───────────────────────────────────────────────────────

class _FakePartnerRepository implements PartnerRepository {
  final _store = <String, Partnership>{};

  @override
  Future<Partnership> invitePartner(String inviterId) async {
    final p = Partnership(
      id: 'p-${_store.length}',
      inviterId: inviterId,
      inviteToken: 'token-$inviterId',
      status: PartnershipStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store[p.id] = p;
    return p;
  }

  @override
  Future<Partnership> acceptInvite({
    required String inviteToken,
    required String inviteeId,
  }) async {
    final entry = _store.values.where((p) => p.inviteToken == inviteToken);
    if (entry.isEmpty) throw Exception('Invalid token');
    final p = entry.first;
    final updated = p.copyWith(
      status: PartnershipStatus.active,
      inviteeId: inviteeId,
      updatedAt: DateTime.now(),
    );
    _store[p.id] = updated;
    return updated;
  }

  @override
  Future<Partnership?> getPartnership(String userId) async {
    try {
      return _store.values.firstWhere(
        (p) => p.inviterId == userId || p.inviteeId == userId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> dissolvePartnership(String partnershipId) async {
    _store.remove(partnershipId);
  }

  @override
  Future<PartnerStreakSummary?> getPartnerStreaks(String partnershipId) async {
    return null;
  }
}
