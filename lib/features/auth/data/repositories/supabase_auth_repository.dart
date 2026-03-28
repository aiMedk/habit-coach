import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_coach/core/error/failures.dart';
import 'package:habit_coach/core/network/supabase_client.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart';
import 'package:habit_coach/features/auth/domain/repositories/auth_repository.dart';

/// T027: SupabaseAuthRepository
/// Maps Supabase Auth responses to domain [AppUser] entities and
/// Supabase exceptions to typed [Failure] subclasses.
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository() : _client = AppSupabaseClient.instance;

  final SupabaseClient _client;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      final user = response.user;
      if (user == null) throw const ServerFailure('Sign-up returned no user');
      // Upsert public profile row
      await _client.from('users').upsert({
        'id': user.id,
        'email': email,
        'display_name': displayName,
        'timezone': 'UTC',
      });
      return await _fetchUserProfile(user.id);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw const AuthFailure('Invalid credentials');
      return await _fetchUserProfile(user.id);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AppUser> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'habitcoach://auth/callback',
      );
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthFailure('Apple sign-in cancelled');
      return await _fetchUserProfile(user.id);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'habitcoach://auth/callback',
      );
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthFailure('Google sign-in cancelled');
      return await _fetchUserProfile(user.id);
    } on AuthFailure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw const AuthFailure(
          'Google sign-in is not configured yet. Please use email to sign in.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchUserProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AppUser?> get onAuthStateChange =>
      _client.auth.onAuthStateChange.asyncMap((event) async {
        final user = event.session?.user;
        if (user == null) return null;
        try {
          return await _fetchUserProfile(user.id);
        } catch (_) {
          return null;
        }
      });

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<AppUser> _fetchUserProfile(String userId) async {
    final data = await _client.from('users').select().eq('id', userId).single();
    return _mapToAppUser(data);
  }

  static AppUser _mapToAppUser(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String,
      email: row['email'] as String,
      displayName: row['display_name'] as String,
      timezone: row['timezone'] as String? ?? 'UTC',
      subscriptionTier:
          (row['subscription_tier'] as String?) == 'pro'
              ? SubscriptionTier.pro
              : SubscriptionTier.free,
      notificationPreferences:
          row['notification_preferences'] != null
              ? NotificationPreferences.fromJson(
                Map<String, dynamic>.from(
                  row['notification_preferences'] as Map,
                ),
              )
              : NotificationPreferences.allEnabled,
      deletionStatus:
          (row['deletion_status'] as String?) == 'pending_deletion'
              ? DeletionStatus.pendingDeletion
              : DeletionStatus.active,
      deletionRequestedAt:
          row['deletion_requested_at'] != null
              ? DateTime.parse(row['deletion_requested_at'] as String)
              : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
