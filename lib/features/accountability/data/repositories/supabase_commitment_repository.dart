import 'package:habit_coach/features/accountability/domain/entities/commitment.dart';
import 'package:habit_coach/features/accountability/domain/repositories/commitment_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// T092: Supabase implementation of CommitmentRepository.
///
/// The 3-active-commitment limit is also enforced by a DB trigger
/// (008_create_commitments.sql), so the repository check is a fast-fail
/// that avoids a round-trip on obvious violations.
class SupabaseCommitmentRepository implements CommitmentRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Commitment> createCommitment({
    required String userId,
    required String partnerId,
    required String habitId,
    required String habitName,
    required int targetStreak,
    required DateTime deadline,
  }) async {
    // Fast-fail: check active count before hitting DB trigger
    final activeCount = await _client
        .from('commitments')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'active');

    if ((activeCount as List).length >= 3) {
      throw Exception('Maximum 3 active commitments per user');
    }

    final row =
        await _client
            .from('commitments')
            .insert({
              'user_id': userId,
              'partner_id': partnerId,
              'habit_id': habitId,
              'target_streak': targetStreak,
              'deadline': deadline.toIso8601String().substring(0, 10),
              'status': 'active',
            })
            .select()
            .single();

    return _fromRow(row, habitName: habitName, currentStreak: 0);
  }

  @override
  Future<List<Commitment>> getActiveCommitments(String userId) async {
    final rows = await _client
        .from('commitments')
        .select('*, habits(name)')
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('created_at');

    return (rows as List).map((r) {
      final habitName =
          (r['habits'] as Map<String, dynamic>?)?['name'] as String? ?? '';
      return _fromRow(r, habitName: habitName, currentStreak: 0);
    }).toList();
  }

  @override
  Future<List<Commitment>> getCommitmentsForPartner(String partnerId) async {
    final rows = await _client
        .from('commitments')
        .select('*, habits(name)')
        .eq('partner_id', partnerId)
        .eq('status', 'active')
        .order('created_at');

    return (rows as List).map((r) {
      final habitName =
          (r['habits'] as Map<String, dynamic>?)?['name'] as String? ?? '';
      return _fromRow(r, habitName: habitName, currentStreak: 0);
    }).toList();
  }

  @override
  Future<void> updateCommitmentStatus({
    required String commitmentId,
    required CommitmentStatus status,
  }) async {
    await _client
        .from('commitments')
        .update({'status': status.name})
        .eq('id', commitmentId);
  }

  Commitment _fromRow(
    Map<String, dynamic> r, {
    required String habitName,
    required int currentStreak,
  }) => Commitment(
    id: r['id'] as String,
    userId: r['user_id'] as String,
    partnerId: r['partner_id'] as String,
    habitId: r['habit_id'] as String,
    habitName: habitName,
    targetStreak: r['target_streak'] as int,
    deadline: DateTime.parse(r['deadline'] as String),
    status: CommitmentStatus.values.byName(r['status'] as String),
    currentStreak: currentStreak,
    createdAt: DateTime.parse(r['created_at'] as String),
  );
}
