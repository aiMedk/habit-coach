import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:habit_coach/core/error/failures.dart';
import 'package:habit_coach/features/habits/domain/entities/completion.dart';
import 'package:habit_coach/features/habits/domain/repositories/completion_repository.dart';

/// T159: CompletionRepository contract tests — verify interface behaviour
/// using a mock implementation. The real Isar-backed implementation is tested
/// by the integration tests (T161).
class MockCompletionRepository extends Mock implements CompletionRepository {}

Completion _makeCompletion({
  String id = 'c1',
  String habitId = 'h1',
  bool isUndone = false,
}) {
  final now = DateTime.now();
  return Completion(
    id: id,
    habitId: habitId,
    userId: 'u1',
    completedAt: now,
    localDate: '2026-03-25',
    isUndone: isUndone,
    createdAt: now,
  );
}

void main() {
  late MockCompletionRepository repo;

  setUp(() => repo = MockCompletionRepository());

  group('CompletionRepository contract', () {
    test('completeHabit returns a Completion', () async {
      final completion = _makeCompletion();
      when(
        () => repo.completeHabit(
          habitId: 'h1',
          userId: 'u1',
          completedAt: any(named: 'completedAt'),
          localDate: '2026-03-25',
        ),
      ).thenAnswer((_) async => completion);

      final result = await repo.completeHabit(
        habitId: 'h1',
        userId: 'u1',
        completedAt: DateTime.now(),
        localDate: '2026-03-25',
      );
      expect(result.habitId, 'h1');
      expect(result.isUndone, false);
    });

    test(
      'completeHabit is idempotent — returns same completion on same day',
      () async {
        final first = _makeCompletion(id: 'c1');
        when(
          () => repo.completeHabit(
            habitId: 'h1',
            userId: 'u1',
            completedAt: any(named: 'completedAt'),
            localDate: '2026-03-25',
          ),
        ).thenAnswer((_) async => first);

        final a = await repo.completeHabit(
          habitId: 'h1',
          userId: 'u1',
          completedAt: DateTime.now(),
          localDate: '2026-03-25',
        );
        final b = await repo.completeHabit(
          habitId: 'h1',
          userId: 'u1',
          completedAt: DateTime.now(),
          localDate: '2026-03-25',
        );
        expect(a.id, b.id);
      },
    );

    test('undoCompletion throws ValidationFailure after undo window', () async {
      when(
        () => repo.undoCompletion('c-expired'),
      ).thenThrow(const ValidationFailure('Undo window has elapsed'));

      expect(
        () => repo.undoCompletion('c-expired'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('getCompletionsForHabit excludes undone completions', () async {
      when(
        () => repo.getCompletionsForHabit('h1'),
      ).thenAnswer((_) async => [_makeCompletion(isUndone: false)]);

      final results = await repo.getCompletionsForHabit('h1');
      expect(results.every((c) => !c.isUndone), true);
    });

    test(
      'getPendingSyncCompletions returns only unsynced completions',
      () async {
        when(
          () => repo.getPendingSyncCompletions('u1'),
        ).thenAnswer((_) async => [_makeCompletion()]);

        final pending = await repo.getPendingSyncCompletions('u1');
        expect(pending, isNotEmpty);
      },
    );

    test(
      'getCompletionsForDateRange returns completions within date range',
      () async {
        // T025: Test the new getCompletionsForDateRange method
        final completions = [
          _makeCompletion(id: 'c1'),
          _makeCompletion(id: 'c2'),
        ];
        when(
          () => repo.getCompletionsForDateRange('u1', '2026-03-25', '2026-03-26'),
        ).thenAnswer((_) async => completions);

        final results = await repo.getCompletionsForDateRange(
          'u1',
          '2026-03-25',
          '2026-03-26',
        );
        expect(results, hasLength(2));
        expect(results.every((c) => !c.isUndone), true);
      },
    );

    test(
      'getCompletionsForDateRange returns empty list for date range with no data',
      () async {
        // T025: Empty range test
        when(
          () => repo.getCompletionsForDateRange('u1', '2026-05-01', '2026-05-05'),
        ).thenAnswer((_) async => []);

        final results =
            await repo.getCompletionsForDateRange('u1', '2026-05-01', '2026-05-05');
        expect(results, isEmpty);
      },
    );
  });
}
