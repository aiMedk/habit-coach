import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart';
import 'package:habit_coach/features/auth/domain/repositories/auth_repository.dart';

/// T028: Auth Riverpod providers.

/// Provides the [AuthRepository] implementation (data layer).
/// Other providers depend on this rather than importing Supabase directly.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(),
);

/// Emits [AppUser] when signed in, null when signed out.
/// Components listen to this to drive redirect guards.
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).onAuthStateChange,
);

/// Returns the currently authenticated [AppUser], or null.
/// Prefer [authStateProvider] for reactive auth state;
/// use this for one-shot reads (e.g., getting the user ID before a write).
final currentUserProvider = FutureProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).getCurrentUser(),
);
