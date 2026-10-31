/// The failures an authentication provider adapter can report.
enum AuthDataSourceError {
  /// The email or password is incorrect.
  invalidCredentials,

  /// The email address is already registered.
  emailAlreadyInUse,

  /// The provider's sign-in flow was cancelled.
  cancelled,

  /// The provider could not be reached.
  connection,

  /// The provider could not authenticate the identity.
  authentication,

  /// The provider could not load the user's profile.
  profileLoading,
}

/// A data-layer exception translated by the repository before leaving data.
final class AuthDataSourceException implements Exception {
  /// Creates a provider failure with the given data-layer code.
  const AuthDataSourceException(this.code);

  /// The provider adapter's failure classification.
  final AuthDataSourceError code;
}
