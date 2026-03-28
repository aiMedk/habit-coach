import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';

/// T047c: Onboarding completion screen — final onboarding step.
/// Celebrates habit creation and transitions to the main dashboard.
class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _CelebrationSection(),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Start my journey'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CelebrationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.check_circle, size: 96, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'You\'re all set!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your first habit is ready. Check in every morning and '
          'evening to build momentum — your AI coach will be there '
          'to guide you.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
