import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';

/// T047a: Welcome screen — first onboarding step.
/// Introduces the app value proposition and invites the user to create their
/// first habit.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              _HeroSection(),
              const Spacer(),
              _ActionSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.self_improvement,
          size: 96,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Build habits that stick.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your AI coach checks in every morning and evening to '
          'keep you on track. Let\'s set up your first habit.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ActionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: () => context.push(AppRoutes.habitCreation),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('Get started'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go(AppRoutes.dashboard),
          child: const Text('Skip for now'),
        ),
      ],
    );
  }
}
