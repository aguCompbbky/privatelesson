/// The authenticated identity, without role or profile-completion information.
final class AuthSession {
  /// Creates a session containing only the user's identity and display name.
  const AuthSession({required this.userId, required this.displayName});

  /// The user's unique identifier.
  final String userId;

  /// The user's display name.
  final String displayName;
}
