/// The replaceable platform adapter for external contact operations.
abstract interface class ExternalContactDataSource {
  /// Opens the URI and reports whether an external application accepted it.
  Future<bool> launchUri(Uri uri);

  /// Writes the exact supplied text to the platform clipboard.
  Future<void> copyToClipboard(String text);
}
