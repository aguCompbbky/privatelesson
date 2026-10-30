/// The distinct authentication failures callers can handle.
enum AuthFailureType {
  /// The user cancelled the sign-in flow.
  cancelled,

  /// The authentication service could not be reached.
  connection,

  /// The identity could not be authenticated or the operation failed otherwise.
  authentication,

  /// The identity's profile could not be loaded.
  profileLoading,
}

/// A controlled authentication failure that contains no provider details.
final class AuthFailure implements Exception {
  /// Creates a failure with the given domain classification.
  const AuthFailure(this.type);

  /// The reason the authentication operation failed.
  final AuthFailureType type;

  /// Returns a diagnostic description, without provider or user information.
  @override
  String toString() => 'AuthFailure(${type.name})';
}
