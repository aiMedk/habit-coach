import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge.dart';
import 'package:habit_coach/features/challenges/presentation/providers/challenge_providers.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

/// T107: ChallengesListScreen — shows user's active/pending/completed challenges
/// with tabs for filtering. FloatingActionButton opens challenge creation.
class ChallengesListScreen extends ConsumerStatefulWidget {
  const ChallengesListScreen({super.key});

  @override
  ConsumerState<ChallengesListScreen> createState() =>
      _ChallengesListScreenState();
}

class _ChallengesListScreenState extends ConsumerState<ChallengesListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entitlementService = ref.watch(entitlementServiceProvider);
    final isPro = entitlementService.isPro;

    // T018: Show upgrade prompt for free-tier users
    if (!isPro) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenges')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Challenges are a Pro feature',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock group challenges and accountability partners.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.paywall),
                  child: const Text('Upgrade to Pro'),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: () {}, child: const Text('Maybe later')),
              ],
            ),
          ),
        ),
      );
    }

    final challengesAsync = ref.watch(userChallengesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => context.push(AppRoutes.challengeCreate),
        child: const Icon(Icons.add),
      ),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (challenges) {
          final active = challenges.where((c) => c.isActive).toList();
          final pending = challenges.where((c) => c.isPending).toList();
          final completed =
              challenges.where((c) => c.isCompleted || c.isCancelled).toList();

          return TabBarView(
            controller: _tabs,
            children: [
              _ChallengeList(
                challenges: active,
                emptyLabel: 'No active challenges',
              ),
              _ChallengeList(
                challenges: pending,
                emptyLabel: 'No pending challenges',
              ),
              _ChallengeList(
                challenges: completed,
                emptyLabel: 'No completed challenges',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChallengeList extends StatelessWidget {
  const _ChallengeList({required this.challenges, required this.emptyLabel});

  final List<Challenge> challenges;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _ChallengeCard(challenge: challenges[i]),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap:
            () => context.push(
              AppRoutes.challengeDetail.replaceFirst(':id', challenge.id),
            ),
        leading: Icon(
          challenge.mode == ChallengeMode.compete
              ? Icons.emoji_events_outlined
              : Icons.handshake_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          challenge.habitDescription,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${challenge.participantCount}/${challenge.maxParticipants} participants'
          ' · ${challenge.durationDays} days',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
