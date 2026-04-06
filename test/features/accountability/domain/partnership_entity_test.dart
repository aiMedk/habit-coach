import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/accountability/domain/entities/partnership.dart';

void main() {
  final now = DateTime.now();

  Partnership _make({
    PartnershipStatus status = PartnershipStatus.active,
    String? inviteeId = 'invitee-1',
  }) => Partnership(
    id: 'p-1',
    inviterId: 'inviter-1',
    inviteeId: inviteeId,
    inviteToken: 'tok-abc',
    status: status,
    createdAt: now,
    updatedAt: now,
  );

  group('PartnershipStatus helpers', () {
    test('isPending true when status is pending', () {
      expect(_make(status: PartnershipStatus.pending).isPending, isTrue);
    });

    test('isActive true when status is active', () {
      expect(_make(status: PartnershipStatus.active).isActive, isTrue);
    });

    test('isSuspended true when status is suspended', () {
      expect(_make(status: PartnershipStatus.suspended).isSuspended, isTrue);
    });

    test('isDissolvedOrSuspended covers both statuses', () {
      expect(
        _make(status: PartnershipStatus.dissolved).isDissolvedOrSuspended,
        isTrue,
      );
      expect(
        _make(status: PartnershipStatus.suspended).isDissolvedOrSuspended,
        isTrue,
      );
      expect(
        _make(status: PartnershipStatus.active).isDissolvedOrSuspended,
        isFalse,
      );
    });
  });

  group('partnerIdFor', () {
    test('returns inviteeId when caller is inviter', () {
      final p = _make();
      expect(p.partnerIdFor('inviter-1'), equals('invitee-1'));
    });

    test('returns inviterId when caller is invitee', () {
      final p = _make();
      expect(p.partnerIdFor('invitee-1'), equals('inviter-1'));
    });

    test('returns null for unrelated userId', () {
      expect(_make().partnerIdFor('stranger'), isNull);
    });

    test('returns null when inviteeId is null (pending invite)', () {
      expect(_make(inviteeId: null).partnerIdFor('inviter-1'), isNull);
    });
  });

  group('copyWith', () {
    test('updates status and preserves other fields', () {
      final p = _make();
      final dissolved = p.copyWith(status: PartnershipStatus.dissolved);
      expect(dissolved.status, PartnershipStatus.dissolved);
      expect(dissolved.id, equals(p.id));
      expect(dissolved.inviteeId, equals(p.inviteeId));
    });

    test('updates inviteeId', () {
      final p = _make(inviteeId: null);
      final accepted = p.copyWith(inviteeId: 'new-invitee');
      expect(accepted.inviteeId, equals('new-invitee'));
    });
  });

  group('equality', () {
    test('two partnerships with same id are equal', () {
      final a = _make();
      final b = _make(status: PartnershipStatus.dissolved);
      expect(a, equals(b));
    });

    test('different ids are not equal', () {
      final a = _make();
      final b = Partnership(
        id: 'p-2',
        inviterId: 'inviter-1',
        inviteToken: 'tok-abc',
        status: PartnershipStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
