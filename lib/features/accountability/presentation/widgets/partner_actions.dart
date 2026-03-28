import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';

/// T086: PartnerActions — "Remove Partner" button with confirmation dialog.
/// Shown at the bottom of the partner dashboard.
class PartnerActions extends ConsumerWidget {
  const PartnerActions({super.key, required this.partnershipId});

  final String partnershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteState = ref.watch(inviteNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (inviteState.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              inviteState.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
          onPressed:
              inviteState.isLoading ? null : () => _confirmRemove(context, ref),
          icon:
              inviteState.isLoading
                  ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                  : const Icon(Icons.person_remove_outlined),
          label: const Text('Remove partner'),
        ),
      ],
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Remove partner?'),
            content: const Text(
              'You will both lose access to the shared dashboard and streak nudges. '
              'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogCtx).colorScheme.error,
                  foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await ref.read(inviteNotifierProvider.notifier).dissolve(partnershipId);
      ref.invalidate(partnershipProvider);
      ref.invalidate(partnerStreaksProvider);
    }
  }
}
