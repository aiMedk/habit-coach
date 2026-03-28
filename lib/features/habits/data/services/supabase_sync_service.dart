import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_coach/features/habits/domain/repositories/completion_repository.dart';

/// T043: SupabaseSyncService — pushes offline completions to Supabase and
/// pulls remote changes back into the local Isar cache.
///
/// Uses last-write-wins semantics: the Supabase row is upserted on conflict
/// via the unique index on (habit_id, local_date) WHERE is_undone = FALSE.
/// See migration 019_completion_upsert.sql.
final class SupabaseSyncService {
  SupabaseSyncService({
    required this.supabase,
    required this.completionRepository,
    required this.userId,
  });

  final SupabaseClient supabase;
  final CompletionRepository completionRepository;
  final String userId;

  /// Pushes all locally-created completions that have not yet been synced.
  ///
  /// Each completion is upserted into the Supabase `completions` table.
  /// On success, [syncedAt] is stamped on the local record by the caller
  /// (OfflineCompletionQueue handles the full lifecycle).
  Future<void> pushOfflineCompletions() async {
    final pending = await completionRepository.getPendingSyncCompletions(
      userId,
    );
    if (pending.isEmpty) return;

    final rows =
        pending
            .map(
              (c) => {
                'id': c.id,
                'habit_id': c.habitId,
                'user_id': c.userId,
                'completed_at': c.completedAt.toIso8601String(),
                'local_date': c.localDate,
                'is_undone': c.isUndone,
                'created_at': c.createdAt.toIso8601String(),
              },
            )
            .toList();

    await supabase
        .from('completions')
        .upsert(rows, onConflict: 'habit_id,local_date');
  }

  /// Pulls completions from Supabase for the last [days] calendar days and
  /// returns them as raw maps for the caller to merge into Isar.
  ///
  /// The caller (typically [OfflineCompletionQueue]) is responsible for writing
  /// the results into the local Isar store.
  Future<List<Map<String, dynamic>>> pullRemoteChanges({int days = 30}) async {
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: days));
    final response = await supabase
        .from('completions')
        .select()
        .eq('user_id', userId)
        .gte('completed_at', cutoff.toIso8601String())
        .order('completed_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }
}
