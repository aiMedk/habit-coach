import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';

/// T089: AcceptInviteScreen — handles incoming deep-link
/// `habitcoach://invite/:token`. Calls acceptInvite on the partner repository,
/// then navigates to the partner dashboard on success.
class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key, required this.inviteToken});

  final String inviteToken;

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accept();
  }

  Future<void> _accept() async {
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'You must be signed in to accept an invite.';
        });
        return;
      }
      await ref
          .read(partnerRepositoryProvider)
          .acceptInvite(inviteToken: widget.inviteToken, inviteeId: user.id);
      ref.invalidate(partnershipProvider);
      if (mounted) {
        context.go(AppRoutes.partnerDashboard);
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
      appBar: AppBar(title: const Text('Accepting invite')),
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
                      Text('Connecting you with your partner…'),
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
                        'Could not accept invite',
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
                        onPressed: () => context.go(AppRoutes.dashboard),
                        child: const Text('Go to dashboard'),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
