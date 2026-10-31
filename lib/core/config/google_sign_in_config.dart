/// Compile-time Google client identifiers, independent of provider SDKs.
final class GoogleSignInConfig {
  /// Creates configuration; blank identifiers defer to platform configuration.
  const GoogleSignInConfig({
    String serverClientId = '',
    String iosClientId = '',
  }) : _serverClientId = serverClientId,
       _iosClientId = iosClientId;

  /// Reads identifiers supplied using `--dart-define` at build time.
  const GoogleSignInConfig.fromEnvironment()
    : this(
        serverClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
        iosClientId: const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      );

  final String _serverClientId;
  final String _iosClientId;

  /// OAuth web client ID used as the Google ID token audience.
  String? get serverClientId => _nullableClientId(_serverClientId);

  /// OAuth iOS client ID used when platform configuration is unavailable.
  String? get iosClientId => _nullableClientId(_iosClientId);

  static String? _nullableClientId(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
