import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';
import 'package:habit_coach/features/onboarding/domain/usecases/onboarding_usecase.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

/// T046: Onboarding feature Riverpod providers.

/// Provides [OnboardingUseCase] assembled from its dependencies.
final onboardingUseCaseProvider = FutureProvider<OnboardingUseCase>((
  ref,
) async {
  final habitRepo = await ref.watch(habitRepositoryProvider.future);
  final entitlement = ref.watch(entitlementServiceProvider);
  return OnboardingUseCase(
    habitRepository: habitRepo,
    entitlementService: entitlement,
  );
});

/// Tracks whether onboarding has already been completed (user has habits).
/// Used by the router to decide whether to show the onboarding flow.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final useCase = await ref.watch(onboardingUseCaseProvider.future);
  return useCase.hasExistingHabits();
});
