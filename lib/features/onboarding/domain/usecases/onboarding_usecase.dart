import 'package:habit_coach/core/error/failures.dart';
import 'package:habit_coach/features/habits/domain/entities/habit.dart';
import 'package:habit_coach/features/habits/domain/repositories/habit_repository.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

/// T045: OnboardingUseCase — orchestrates the habit creation step during
/// the first-run onboarding flow.
///
/// Enforces the free-tier 3-habit limit via [EntitlementService] so the
/// same business rule is applied consistently outside of the settings flow.
final class OnboardingUseCase {
  const OnboardingUseCase({
    required this.habitRepository,
    required this.entitlementService,
  });

  final HabitRepository habitRepository;
  final EntitlementService entitlementService;

  /// Creates an initial habit during onboarding.
  ///
  /// Returns the created [Habit].
  /// Throws [EntitlementFailure] if the free-tier habit limit is already
  /// reached (should not happen during first-time onboarding, but guarded
  /// for safety).
  Future<Habit> createFirstHabit({
    required String name,
    String? description,
    required HabitFrequency frequency,
    List<int>? frequencyDays,
  }) async {
    final existing = await habitRepository.getHabits(activeOnly: true);
    if (!entitlementService.canAddHabit(existing.length)) {
      throw const EntitlementFailure(
        'Cannot add habit: free-tier limit of 3 active habits reached.',
      );
    }
    return habitRepository.createHabit(
      name: name,
      description: description,
      frequency: frequency,
      frequencyDays: frequencyDays,
    );
  }

  /// Returns true if onboarding can be skipped (user already has habits).
  Future<bool> hasExistingHabits() async {
    final habits = await habitRepository.getHabits(activeOnly: true);
    return habits.isNotEmpty;
  }
}
