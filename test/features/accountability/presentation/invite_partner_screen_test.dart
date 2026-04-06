import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/accountability/domain/entities/partnership.dart';
import 'package:habit_coach/features/accountability/domain/repositories/partner_repository.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';
import 'package:habit_coach/features/accountability/presentation/screens/invite_partner_screen.dart';

class _FakePartnerRepo implements PartnerRepository {
  @override
  Future<Partnership> invitePartner(String inviterId) =>
      throw UnimplementedError();
  @override
  Future<Partnership> acceptInvite({
    required String inviteToken,
    required String inviteeId,
  }) => throw UnimplementedError();
  @override
  Future<Partnership?> getPartnership(String userId) async => null;
  @override
  Future<void> dissolvePartnership(String partnershipId) async {}
  @override
  Future<PartnerStreakSummary?> getPartnerStreaks(String partnershipId) async =>
      null;
}

void main() {
  final now = DateTime.now();

  Widget _wrap(List<Override> overrides) => ProviderScope(
    overrides: [
      partnerRepositoryProvider.overrideWithValue(_FakePartnerRepo()),
      ...overrides,
    ],
    child: const MaterialApp(home: InvitePartnerScreen()),
  );

  testWidgets('shows Generate invite link button when no partnership', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([partnershipProvider.overrideWith((_) async => null)]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Generate invite link'), findsOneWidget);
  });

  testWidgets('shows waiting state for pending invite', (tester) async {
    final pending = Partnership(
      id: 'p-1',
      inviterId: 'u1',
      inviteToken: 'abc123',
      status: PartnershipStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await tester.pumpWidget(
      _wrap([partnershipProvider.overrideWith((_) async => pending)]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Waiting for your partner'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
  });

  testWidgets('shows already has partner message for active partnership', (
    tester,
  ) async {
    final active = Partnership(
      id: 'p-1',
      inviterId: 'u1',
      inviteeId: 'u2',
      inviteToken: 'abc123',
      status: PartnershipStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    await tester.pumpWidget(
      _wrap([partnershipProvider.overrideWith((_) async => active)]),
    );
    await tester.pumpAndSettle();
    expect(find.text('You already have a partner!'), findsOneWidget);
  });
}
