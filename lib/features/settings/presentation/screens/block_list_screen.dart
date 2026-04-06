import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/accountability/presentation/providers/accountability_providers.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/settings/domain/entities/blocked_user.dart';

/// T087: BlockListScreen — shows all users blocked by the current user,
/// with an unblock option for each.
class BlockListScreen extends ConsumerWidget {
  const BlockListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: blockedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          if (users.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder:
                (context, index) => _BlockedUserTile(blockedUser: users[index]),
          );
        },
      ),
    );
  }
}

class _BlockedUserTile extends ConsumerWidget {
  const _BlockedUserTile({required this.blockedUser});
  final BlockedUser blockedUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          blockedUser.blockedDisplayName.isNotEmpty
              ? blockedUser.blockedDisplayName[0].toUpperCase()
              : '?',
        ),
      ),
      title: Text(blockedUser.blockedDisplayName),
      trailing: TextButton(
        onPressed: () => _unblock(context, ref),
        child: const Text('Unblock'),
      ),
    );
  }

  Future<void> _unblock(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: Text('Unblock ${blockedUser.blockedDisplayName}?'),
            content: const Text(
              'They will be able to send you a partner invite again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Unblock'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;
      await ref
          .read(blockRepositoryProvider)
          .unblockUser(
            blockerId: user.id,
            blockedUserId: blockedUser.blockedId,
          );
      ref.invalidate(blockedUsersProvider);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No blocked users',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Users you block will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
