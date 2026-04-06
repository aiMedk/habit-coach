import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/accountability/domain/entities/partnership.dart';
import 'package:habit_coach/features/accountability/domain/repositories/partner_repository.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';
import 'package:habit_coach/features/accountability/presentation/widgets/partner_actions.dart';

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
  Widget _wrap({String partnershipId = 'p-1'}) => ProviderScope(
    overrides: [
      partnerRepositoryProvider.overrideWithValue(_FakePartnerRepo()),
    ],
    child: MaterialApp(
      home: Scaffold(body: PartnerActions(partnershipId: partnershipId)),
    ),
  );

  testWidgets('shows Remove partner button', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Remove partner'), findsOneWidget);
  });

  testWidgets('tapping Remove partner shows confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Remove partner'));
    await tester.pumpAndSettle();
    expect(find.text('Remove partner?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Remove'), findsOneWidget);
  });

  testWidgets('tapping Cancel dismisses the dialog', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Remove partner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Remove partner?'), findsNothing);
  });
}
