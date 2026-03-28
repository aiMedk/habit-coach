import 'dart:async';

import 'package:isar/isar.dart';
import 'package:habit_coach/core/network/connectivity_checker.dart';
import 'package:habit_coach/features/habits/data/models/isar_models.dart';
import 'package:habit_coach/features/habits/data/services/supabase_sync_service.dart';

/// T044: OfflineCompletionQueue — drains pending completions to Supabase
/// whenever the device comes back online.
///
/// Lifecycle:
///   1. Call [start] once (e.g. in app startup after the Isar + Supabase
///      providers are ready).
///   2. The queue listens to [ConnectivityChecker.onConnectivityChanged].
///   3. On each transition to online, [_drain] is called:
///      - push pending local completions via [SupabaseSyncService]
///      - stamp syncedAt on each pushed record
///      - pull remote changes and merge them into Isar
///   4. Call [dispose] when tearing down (e.g. on sign-out).
final class OfflineCompletionQueue {
  OfflineCompletionQueue({
    required this.isar,
    required this.syncService,
    required this.connectivity,
  });

  final Isar isar;
  final SupabaseSyncService syncService;
  final ConnectivityChecker connectivity;

  StreamSubscription<bool>? _subscription;
  bool _draining = false;

  /// Starts listening for connectivity changes and drains immediately if online.
  Future<void> start() async {
    _subscription = connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) _drain();
    });

    // Attempt an immediate drain if already connected.
    if (await connectivity.hasConnection()) {
      await _drain();
    }
  }

  /// Cancels the connectivity listener.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      await _pushAndStamp();
      await _pullAndMerge();
    } catch (_) {
      // Silently swallow: next connectivity event will retry.
    } finally {
      _draining = false;
    }
  }

  Future<void> _pushAndStamp() async {
    await syncService.pushOfflineCompletions();

    // Stamp syncedAt on all records that are now confirmed remote.
    final now = DateTime.now().toUtc();
    final pending =
        await isar.completionLocals
            .filter()
            .isUndoneEqualTo(false)
            .syncedAtIsNull()
            .findAll();

    if (pending.isEmpty) return;

    final stamped =
        pending.map((c) {
          return CompletionLocal(
            id: c.id,
            habitId: c.habitId,
            userId: c.userId,
            completedAt: c.completedAt,
            localDate: c.localDate,
            isUndone: c.isUndone,
            createdAt: c.createdAt,
            syncedAt: now,
          );
        }).toList();

    await isar.writeTxn(() => isar.completionLocals.putAll(stamped));
  }

  Future<void> _pullAndMerge() async {
    final rows = await syncService.pullRemoteChanges();
    if (rows.isEmpty) return;

    final remotes =
        rows.map((row) {
          return CompletionLocal(
            id: row['id'] as String,
            habitId: row['habit_id'] as String,
            userId: row['user_id'] as String,
            completedAt: DateTime.parse(row['completed_at'] as String),
            localDate: row['local_date'] as String,
            isUndone: (row['is_undone'] as bool?) ?? false,
            createdAt: DateTime.parse(row['created_at'] as String),
            syncedAt:
                row['synced_at'] != null
                    ? DateTime.parse(row['synced_at'] as String)
                    : DateTime.now().toUtc(),
          );
        }).toList();

    await isar.writeTxn(() => isar.completionLocals.putAll(remotes));
  }
}
