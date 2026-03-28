import 'package:habit_coach/core/error/failures.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart';

/// T026: AuthRepository interface (domain layer — no Supabase imports).
///
/// Returns [AppUser] or throws a typed [Failure] subclass for error cases.
/// The data layer implementation ([SupabaseAuthRepository]) maps Supabase
/// exceptions to these typed failures.
abstract interface class AuthRepository {
  /// Signs up a new user with email, password, and display name.
  /// Throws [ServerFailure] on Supabase error, [ValidationFailure] if inputs invalid.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  /// Signs in with email and password.
  /// Throws [AuthFailure] on wrong credentials, [ServerFailure] on network/server error.
  Future<AppUser> signIn({required String email, required String password});

  /// Signs in with Apple (OAuth).
  /// Throws [AuthFailure] if cancelled, [ServerFailure] on error.
  Future<AppUser> signInWithApple();

  /// Signs in with Google (OAuth).
  /// Throws [AuthFailure] if cancelled, [ServerFailure] on error.
  Future<AppUser> signInWithGoogle();

  /// Signs out the current user.
  Future<void> signOut();

  /// Returns the currently authenticated user, or null if not signed in.
  Future<AppUser?> getCurrentUser();

  /// Stream of auth state changes. Emits [AppUser] when signed in, null when signed out.
  Stream<AppUser?> get onAuthStateChange;

  /// Sends a password reset email to [email].
  Future<void> sendPasswordResetEmail(String email);
}
