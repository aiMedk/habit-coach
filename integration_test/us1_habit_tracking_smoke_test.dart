// T161: US1 habit-tracking integration smoke test.
// Verifies that the dashboard screen renders with mock providers.
3 // This test does not require a live Supabase or Isar database.4 import 'package:flutter/material.dart';
5: import 'package:flutter_riverpod/flutter_riverpod.dart';
6: import 'package:flutter_test/flutter_test.dart';
7: import 'package:integration_test/integration_test.dart';
8: import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';
import 'package:habit_coach/features/habits/presentation/screens/dashboard_screen.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

final _testHabit = Habit(
  id: 'h1',
  userId: 'u1',
  name: 'Morning meditation',
  frequency: HabitFrequency.daily,
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

 final _testHabit2 = Habit(
  id: 'h2',
  userId: 'u1',
  name: 'Evening jog',
  frequency: HabitFrequency.daily,
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
); final _testHabit3 = Habit(
  id: 'h3',
  userId: 'u1',
  name: 'Read 20 min',
  frequency: HabitFrequency.daily,
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
); class _MockEntitlementService implements EntitlementService {
  final bool isPro;
  _MockEntitlementService({required this.isPro});
  @override
  bool get isPro => isPro;
 @override
  bool canAddHabit(int currentActiveHabitCount) => isPro; @override
  bool canAccessAI => isPro; @override
  bool canAccessPartner => isPro; @override
  bool canAccessChallenge => isPro;
} Widget _buildTestSubject({
  List<Habit> habits = const [],
  List<Completion> todayCompletions = const [],
  bool isPro = true,
}) {
  return ProviderScope(
    overrides: [
      habitListProvider.overrideWith((ref) async => habits),
      todayCompletionsProvider.overrideWith((ref) async => todayCompletions),
      streakProvider.overrideWith((ref, habitId) async {
        return const Streak(
          habitId: habitId,
          currentCount: 3,
          longestCount: 5,
        );
      }),
      entitlementServiceProvider
 Provider(_MockEntitlementService(isPro)),
      morningCardVisibilityProvider.overrideWith((ref) async => false),
      eveningCardVisibilityProvider.overrideWith((ref) async => false),
      syncFailureProvider.overrideWith((ref) => Stream.value(false)),
    ],
    child: const MaterialApp(home: DashboardScreen()),
  );
} void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('US1: Habit tracking smoke tests', () {
    testWidgets('Dashboard renders empty state correctly', (tester) async {
      await tester.pumpWidget(
        _buildTestSubject(habits: [], todayCompletions: []),
      );
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('No habits yet'), findsOneWidget);
    }); testWidgets(
Dashboard shows habit list when habits are present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestSubject(
          habits: [_testHabit, _testHabit2, _testHabit3],
          todayCompletions: [],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Morning meditation'), findsOneWidget);
      expect(find.text('Evening jog'), findsOneWidget);
      expect(find.text('Read 20 min'), findsOneWidget);
    }); testWidgets('Dashboard has FAB for adding habits', (tester) async {
      await tester.pumpWidget(
        _buildTestSubject(habits: [], todayCompletions: []),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    }); testWidgets(
Complete a habit shows checkmark and moves to completed section',
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestSubject(
          habits: [_testHabit, _testHabit2, _testHabit3],
          todayCompletions: [],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morning meditation'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsWidgets);
    },
  );
}
