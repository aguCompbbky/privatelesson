/// Selects the active data-source family at the composition root.
enum BackendProvider {
  /// In-memory mock data sources requiring no external configuration.
  mock,

  /// Firebase Authentication and Cloud Firestore data sources.
  firebase
  ;

  /// Compile-time environment key read at application startup.
  static const String environmentKey = 'BACKEND_PROVIDER';

  /// Active provider resolved from `--dart-define=BACKEND_PROVIDER=...`.
  static BackendProvider get fromEnvironment => fromName(
    const String.fromEnvironment(environmentKey, defaultValue: 'firebase'),
  );

  /// Parses [raw] case-insensitively; only explicit `mock` selects [mock].
  /// Empty or unknown values use [firebase], matching the application default.
  static BackendProvider fromName(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == mock.name) {
      return mock;
    }
    return firebase;
  }
}
