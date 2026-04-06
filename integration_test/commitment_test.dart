import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/accountability/domain/entities/commitment.dart';
import 'package:integration_test/integration_test.dart';

/// T172: Commitment integration smoke test.
///
/// Validates commitment domain entity behaviour and progress tracking.
/// Full end-to-end Supabase flows (create → partner sees → fulfil) are run
/// in the CI pipeline against a test project with seeded credentials.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Commitment _make({
    CommitmentStatus status = CommitmentStatus.active,
    int currentStreak = 0,
    DateTime? deadline,
  }) => Commitment(
    id: 'c-smoke',
    userId: 'u1',
    partnerId: 'u2',
    habitId: 'h1',
    habitName: 'Meditate',
    targetStreak: 7,
    deadline: deadline ?? DateTime.now().add(const Duration(days: 14)),
    status: status,
    currentStreak: currentStreak,
    createdAt: DateTime.now(),
  );

  testWidgets('new commitment is active with 0 progress', (tester) async {
    final c = _make();
    expect(c.isActive, isTrue);
    expect(c.progress, equals(0.0));
    expect(c.daysRemaining, greaterThanOrEqualTo(13));
  });

  testWidgets('progress updates correctly mid-streak', (tester) async {
    final c = _make(currentStreak: 3);
    expect(c.progress, closeTo(3 / 7, 0.001));
  });

  testWidgets('commitment can be marked fulfilled', (tester) async {
    final c = _make(
      currentStreak: 7,
    ).copyWith(status: CommitmentStatus.fulfilled);
    expect(c.isFulfilled, isTrue);
    expect(c.progress, equals(1.0));
  });

  testWidgets('expired commitment can be marked failed', (tester) async {
    final c = _make(
      deadline: DateTime.now().subtract(const Duration(days: 1)),
    ).copyWith(status: CommitmentStatus.failed);
    expect(c.isFailed, isTrue);
    expect(c.daysRemaining, lessThan(0));
  });
}
