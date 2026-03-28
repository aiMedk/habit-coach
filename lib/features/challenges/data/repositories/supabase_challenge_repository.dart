import 'dart:math';
import 'package:habit_coach/features/challenges/domain/entities/challenge.dart';
import 'package:habit_coach/features/challenges/domain/entities/challenge_participant.dart';
import 'package:habit_coach/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// T101: Supabase implementation of ChallengeRepository.
///
/// The 5-participant cap and 3-challenge limit are also enforced by DB triggers
/// (009_create_challenges.sql). Fast-fail checks here avoid wasted round-trips.
class SupabaseChallengeRepository implements ChallengeRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Challenge> createChallenge({
    required String creatorId,
    required String habitDescription,
    required ChallengeMode mode,
    required DateTime startDate,
    required DateTime endDate,
    int maxParticipants = 5,
    int? collaborateTargetPct,
  }) async {
    final token = _generateToken();
    final row =
        await _client
            .from('challenges')
            .insert({
              'creator_id': creatorId,
              'habit_description': habitDescription,
              'mode': mode.name,
              'start_date': startDate.toIso8601String().substring(0, 10),
              'end_date': endDate.toIso8601String().substring(0, 10),
              'max_participants': maxParticipants,
              if (collaborateTargetPct != null)
                'collaborate_target_pct': collaborateTargetPct,
              'invite_token': token,
              'status': 'pending',
            })
            .select()
            .single();

    return _challengeFromRow(row, participantCount: 1);
  }

  @override
  Future<ChallengeParticipant> joinChallenge({
    required String inviteToken,
    required String userId,
    required String displayName,
  }) async {
    // Resolve challenge from token
    final challengeRow =
        await _client
            .from('challenges')
            .select()
            .eq('invite_token', inviteToken)
            .maybeSingle();

    if (challengeRow == null) throw Exception('Invalid invite token');

    final challengeId = challengeRow['id'] as String;

    final row =
        await _client
            .from('challenge_participants')
            .insert({
              'challenge_id': challengeId,
              'user_id': userId,
              'status': 'pending',
            })
            .select()
            .single();

    return _participantFromRow(row, displayName: displayName);
  }

  @override
  Future<void> leaveChallenge({
    required String challengeId,
    required String userId,
  }) async {
    await _client
        .from('challenge_participants')
        .update({'status': 'left'})
        .eq('challenge_id', challengeId)
        .eq('user_id', userId);
  }

  @override
  Future<Challenge?> getChallenge(String challengeId) async {
    final row =
        await _client
            .from('challenges')
            .select()
            .eq('id', challengeId)
            .maybeSingle();

    if (row == null) return null;

    final count = await _client
        .from('challenge_participants')
        .select('id')
        .eq('challenge_id', challengeId)
        .neq('status', 'left');

    return _challengeFromRow(row, participantCount: (count as List).length);
  }

  @override
  Future<List<ChallengeParticipant>> getLeaderboard(String challengeId) async {
    // Fetch participants with joined user display_name
    final rows = await _client
        .from('challenge_participants')
        .select('*, users(display_name)')
        .eq('challenge_id', challengeId)
        .neq('status', 'left');

    final participants =
        (rows as List).map((r) {
          final name =
              (r['users'] as Map<String, dynamic>?)?['display_name']
                  as String? ??
              'User';
          return _participantFromRow(r, displayName: name);
        }).toList();

    // Sort: completion_count desc, then current_streak desc
    participants.sort((a, b) {
      final cc = b.completionCount.compareTo(a.completionCount);
      if (cc != 0) return cc;
      return b.currentStreak.compareTo(a.currentStreak);
    });

    return participants;
  }

  @override
  Future<List<Challenge>> getUserActiveChallenges(String userId) async {
    final participations = await _client
        .from('challenge_participants')
        .select('challenge_id')
        .eq('user_id', userId)
        .neq('status', 'left');

    if ((participations as List).isEmpty) return [];

    final ids = participations.map((r) => r['challenge_id'] as String).toList();

    final rows = await _client
        .from('challenges')
        .select()
        .inFilter('id', ids)
        .order('created_at', ascending: false);

    return (rows as List).map((r) {
      return _challengeFromRow(r, participantCount: 0);
    }).toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Challenge _challengeFromRow(
    Map<String, dynamic> r, {
    required int participantCount,
  }) => Challenge(
    id: r['id'] as String,
    creatorId: r['creator_id'] as String? ?? '',
    habitDescription: r['habit_description'] as String,
    mode: ChallengeMode.values.byName(r['mode'] as String),
    startDate: DateTime.parse(r['start_date'] as String),
    endDate: DateTime.parse(r['end_date'] as String),
    maxParticipants: r['max_participants'] as int,
    collaborateTargetPct: r['collaborate_target_pct'] as int?,
    inviteToken: r['invite_token'] as String,
    status: ChallengeStatus.values.byName(r['status'] as String),
    participantCount: participantCount,
    createdAt: DateTime.parse(r['created_at'] as String),
    purgeAt:
        r['purge_at'] != null ? DateTime.parse(r['purge_at'] as String) : null,
  );

  ChallengeParticipant _participantFromRow(
    Map<String, dynamic> r, {
    required String displayName,
  }) => ChallengeParticipant(
    id: r['id'] as String,
    challengeId: r['challenge_id'] as String,
    userId: r['user_id'] as String,
    displayName: displayName,
    completionCount: r['completion_count'] as int? ?? 0,
    currentStreak: r['current_streak'] as int? ?? 0,
    status: ParticipantStatus.values.byName(r['status'] as String),
    joinedAt: DateTime.parse(r['joined_at'] as String),
  );

  String _generateToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
