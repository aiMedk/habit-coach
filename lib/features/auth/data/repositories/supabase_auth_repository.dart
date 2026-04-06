import 'package:flutter/foundation.dart' show visibleForTesting;
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show User;
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
    // Generate a cryptographically secure nonce.
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null)
        throw const AuthFailure('Apple sign-in failed: no identity token');

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final user = response.user;
      if (user == null) throw const AuthFailure('Apple sign-in failed');

      // Apple only provides name on the very first authorisation.
      // Persist it now before it disappears from future credentials.
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      return await _fetchOrCreateUserProfile(
        user,
        overrideDisplayName: fullName.isEmpty ? null : fullName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthFailure('Apple sign-in cancelled');
      }
      throw AuthFailure(e.message);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  /// Generates a URL-safe random nonce (43 chars).
  String _generateNonce() {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      43,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'habitcoach://auth/callback',
      );
      // signInWithOAuth opens a browser and returns immediately on mobile.
      // The actual session arrives via deep link and is handled by
      // onAuthStateChange, which drives the router redirect.
      // Return a dummy value — the UI discards it for OAuth flows.
      throw const AuthFailure('_oauth_pending');
    } on AuthFailure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw const AuthFailure(
        'Google sign-in is not configured. Please use email to sign in.',
      );
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
          return await _fetchOrCreateUserProfile(user);
        } catch (_) {
          return null;
        }
      });

  /// Fetches the user profile, creating it first if it doesn't exist yet
  /// (e.g. first-time Apple/Google Sign-In).
  ///
  /// [overrideDisplayName] is used for Apple Sign-In where the credential
  /// supplies the name only on the first authorisation.
  Future<AppUser> _fetchOrCreateUserProfile(
    supabase.User authUser, {
    String? overrideDisplayName,
  }) async {
    final existing =
        await _client
            .from('users')
            .select()
            .eq('id', authUser.id)
            .maybeSingle();

    if (existing == null) {
      // First sign-in via OAuth — create the profile row.
      final displayName =
          overrideDisplayName ??
          authUser.userMetadata?['full_name'] as String? ??
          authUser.userMetadata?['name'] as String? ??
          authUser.email?.split('@').first ??
          'User';
      await _client.from('users').insert({
        'id': authUser.id,
        'email': authUser.email ?? '',
        'display_name': displayName,
        'timezone': 'UTC',
        'subscription_tier': 'free',
        'deletion_status': 'active',
      });
    }

    return await _fetchUserProfile(authUser.id);
  }

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

  @visibleForTesting
  static AppUser mapToAppUser(Map<String, dynamic> row) => _mapToAppUser(row);

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
