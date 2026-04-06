import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/habits/domain/entities/completion.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';
import 'package:habit_coach/features/habits/presentation/screens/dashboard_screen.dart';

/// T160: DashboardScreen widget tests.
///
/// Providers are overridden at the ProviderScope level so the widget renders
/// without a real Isar database or Supabase connection.

Habit _habit({String id = 'h1', String name = 'Morning run'}) => Habit(
  id: id,
  userId: 'u1',
  name: name,
  frequency: HabitFrequency.daily,
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Widget _buildSubject({
  List<Habit> habits = const [],
  List<Completion> todayCompletions = const [],
}) {
  return ProviderScope(
    overrides: [
      habitListProvider.overrideWith((ref) async => habits),
      todayCompletionsProvider.overrideWith((ref) async => todayCompletions),
    ],
    child: const MaterialApp(home: DashboardScreen()),
  );
}

void main() {
  group('DashboardScreen', () {
    testWidgets('shows AppBar with Today title', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('shows FAB for adding a new habit', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows empty-state message when user has no habits', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('No habits yet'), findsOneWidget);
    });

    testWidgets('renders habit cards when habits are present', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          habits: [_habit(name: 'Morning run'), _habit(id: 'h2', name: 'Read')],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Morning run'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('completed habits show checkmark indicator', (tester) async {
      final habit = _habit();
      final completion = Completion(
        id: 'c1',
        habitId: habit.id,
        userId: 'u1',
        completedAt: DateTime.now(),
        localDate: '2026-03-25',
        isUndone: false,
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(
        _buildSubject(habits: [habit], todayCompletions: [completion]),
      );
      await tester.pumpAndSettle();
      // The check icon is shown for completed habits
      expect(find.byIcon(Icons.check), findsWidgets);
    });
  });
}
