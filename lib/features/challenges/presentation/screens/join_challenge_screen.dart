import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/challenges/presentation/providers/challenge_providers.dart';

/// T109: JoinChallengeScreen — handles deep-link `habitcoach://challenge/:token`.
/// Validates participant limit and Pro tier, then joins the challenge.
class JoinChallengeScreen extends ConsumerStatefulWidget {
  const JoinChallengeScreen({super.key, required this.inviteToken});

  final String inviteToken;

  @override
  ConsumerState<JoinChallengeScreen> createState() =>
      _JoinChallengeScreenState();
}

class _JoinChallengeScreenState extends ConsumerState<JoinChallengeScreen> {
  bool _loading = true;
  String? _error;
  String? _joinedChallengeId;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'You must be signed in to join a challenge.';
        });
        return;
      }

      final displayName = user.email;

      await ref
          .read(joinChallengeProvider.notifier)
          .join(
            inviteToken: widget.inviteToken,
            userId: user.id,
            displayName: displayName,
          );

      final state = ref.read(joinChallengeProvider);
      if (state.error != null) {
        setState(() {
          _loading = false;
          _error = state.error;
        });
        return;
      }

      setState(() {
        _loading = false;
        _joinedChallengeId = state.joined?.challengeId;
      });

      if (mounted && _joinedChallengeId != null) {
        context.go(
          AppRoutes.challengeDetail.replaceFirst(':id', _joinedChallengeId!),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Joining challenge')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child:
              _loading
                  ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Joining the challenge…'),
                    ],
                  )
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Could not join challenge',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ?? 'Unknown error',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.go(AppRoutes.challenges),
                        child: const Text('Back to challenges'),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
