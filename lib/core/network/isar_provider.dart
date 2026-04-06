import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:habit_coach/features/habits/data/models/isar_models.dart';

/// Lazily opens and caches the Isar database instance.
/// All feature repositories read from this provider.
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [HabitLocalSchema, CompletionLocalSchema, ConversationLocalSchema],
    directory: dir.path,
    inspector: false,
  );
});
