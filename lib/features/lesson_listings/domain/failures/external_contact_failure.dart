/// Provider-independent reasons why an external contact operation can fail.
enum ExternalContactFailureType {
  /// The supplied contact value is blank or has an unsupported format.
  invalidContactValue,

  /// No external application could open the contact URI.
  cannotOpenExternalApp,

  /// The contact value could not be written to the clipboard.
  clipboardFailed,
}

/// A controlled contact failure without platform-specific information.
final class ExternalContactFailure implements Exception {
  /// Creates a failure with its domain reason.
  const ExternalContactFailure(this.type);

  /// The reason the operation failed.
  final ExternalContactFailureType type;
}
