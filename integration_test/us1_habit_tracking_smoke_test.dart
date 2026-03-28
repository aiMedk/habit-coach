// T161: US1 habit-tracking integration smoke test.
// Verifies that the dashboard screen renders with mock providers.
// This test does not require a live Supabase or Isar database.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';
import 'package:habit_coach/features/habits/presentation/screens/dashboard_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('US1: Habit tracking smoke tests', () {
    testWidgets('Dashboard renders empty state correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitListProvider.overrideWith((ref) async => const []),
            todayCompletionsProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('No habits yet'), findsOneWidget);
    });

    testWidgets('Dashboard shows habit list when habits are present', (
      tester,
    ) async {
      final habit = Habit(
        id: 'h1',
        userId: 'u1',
        name: 'Morning meditation',
        frequency: HabitFrequency.daily,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitListProvider.overrideWith((ref) async => [habit]),
            todayCompletionsProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Morning meditation'), findsOneWidget);
    });

    testWidgets('Dashboard has FAB for adding habits', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitListProvider.overrideWith((ref) async => const []),
            todayCompletionsProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
