import 'package:supabase_flutter/supabase_flutter.dart';

/// T010: Supabase client accessor.
///
/// Supabase is initialised once in [main.dart] via [Supabase.initialize].
/// This accessor provides a typed singleton reference used throughout the
/// data layer. Never import SupabaseClient in domain layer files.
final class AppSupabaseClient {
  AppSupabaseClient._();

  /// The global Supabase client instance. Available after [Supabase.initialize]
  /// has completed in main.dart.
  static SupabaseClient get instance => Supabase.instance.client;
}
