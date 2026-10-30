/// The distinct failures of profile validation and persistence.
enum ProfileFailureType {
  /// The display name is empty after trimming whitespace.
  invalidDisplayName,

  /// The user identifier is empty after trimming whitespace.
  invalidUserId,

  /// The stored profile could not be loaded or decoded.
  loadFailed,

  /// The profile could not be saved or the saved payload was invalid.
  saveFailed,
}

/// A profile failure kept separate from authentication failures.
final class ProfileFailure implements Exception {
  /// Creates a failure with the given profile classification.
  const ProfileFailure(this.type);

  /// The reason the profile operation failed.
  final ProfileFailureType type;
}
