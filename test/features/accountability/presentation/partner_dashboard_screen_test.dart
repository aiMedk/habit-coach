import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/accountability/domain/entities/partnership.dart';
import 'package:habit_coach/features/accountability/domain/repositories/partner_repository.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';
import 'package:habit_coach/features/accountability/presentation/screens/partner_dashboard_screen.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';

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

  Partnership _activePartnership() => Partnership(
    id: 'p-1',
    inviterId: 'u1',
    inviteeId: 'u2',
    inviteToken: 'tok',
    status: PartnershipStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  PartnerStreakSummary _partnerSummary() => const PartnerStreakSummary(
    partnerId: 'u2',
    partnerName: 'Alice',
    streaks: {'Meditate': 5, 'Run': 3},
    completionRateToday: 1.0,
  );

  List<Override> _baseOverrides() => [
    partnerRepositoryProvider.overrideWithValue(_FakePartnerRepo()),
  ];

  Widget _wrap(List<Override> overrides) => ProviderScope(
    overrides: [..._baseOverrides(), ...overrides],
    child: const MaterialApp(home: PartnerDashboardScreen()),
  );

  testWidgets('shows no-partner view when partnership is null', (tester) async {
    await tester.pumpWidget(
      _wrap([
        partnershipProvider.overrideWith((_) async => null),
        partnerStreaksProvider.overrideWith((_) async => null),
        habitListProvider.overrideWith((_) async => []),
        todayCompletionsProvider.overrideWith((_) async => []),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('No partner yet'), findsOneWidget);
  });

  testWidgets('shows both sections when active partnership exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([
        partnershipProvider.overrideWith((_) async => _activePartnership()),
        partnerStreaksProvider.overrideWith((_) async => _partnerSummary()),
        habitListProvider.overrideWith(
          (_) async => [
            Habit(
              id: 'h1',
              userId: 'u1',
              name: 'Run',
              frequency: HabitFrequency.daily,
              isActive: true,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        ),
        todayCompletionsProvider.overrideWith((_) async => []),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Run'), findsWidgets);
  });

  testWidgets('shows remove partner button', (tester) async {
    await tester.pumpWidget(
      _wrap([
        partnershipProvider.overrideWith((_) async => _activePartnership()),
        partnerStreaksProvider.overrideWith((_) async => _partnerSummary()),
        habitListProvider.overrideWith((_) async => []),
        todayCompletionsProvider.overrideWith((_) async => []),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Remove partner'), findsOneWidget);
  });
}
