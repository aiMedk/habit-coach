/// T006: Core failure classes for clean-architecture error propagation.
/// Domain layer uses these — no Flutter imports permitted here.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

/// Remote API or Supabase returned an error response.
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

/// Local Isar database operation failed.
final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Device has no network connectivity.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Authentication/authorisation error (e.g. expired token, 403).
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// User is not on Pro tier but attempted a Pro-only action.
final class EntitlementFailure extends Failure {
  const EntitlementFailure([
    super.message = 'This feature requires a Pro subscription',
  ]);
}

/// Validation failed on input or business rule.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
