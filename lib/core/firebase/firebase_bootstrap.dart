import 'package:firebase_core/firebase_core.dart';
import 'package:privatelesson/core/di/backend_provider.dart';
import 'package:privatelesson/core/firebase/firebase_options.dart';

/// Signature used to initialize the default Firebase application instance.
typedef FirebaseAppInitializer =
    Future<FirebaseApp> Function({FirebaseOptions? options});

/// Initializes Firebase only when the Firebase backend provider is selected.
abstract final class FirebaseBootstrap {
  /// Ensures Firebase is ready when [provider] resolves to Firebase.
  ///
  /// Returns `false` immediately without touching native channels when
  /// [BackendProvider.mock] is active.
  /// Uses generated platform options unless [options] are supplied.
  static Future<bool> ensureInitialized({
    BackendProvider? provider,
    FirebaseOptions? options,
    bool Function()? hasInitializedApps,
    FirebaseAppInitializer? initializeApp,
  }) async {
    final effectiveProvider = provider ?? BackendProvider.fromEnvironment;
    if (effectiveProvider == BackendProvider.mock) {
      return false;
    }
    final checkApps = hasInitializedApps ?? _defaultHasInitializedApps;
    if (checkApps()) {
      return true;
    }
    final runInitialize = initializeApp ?? _defaultInitializeApp;
    await runInitialize(
      options: options ?? DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  }

  static bool _defaultHasInitializedApps() => Firebase.apps.isNotEmpty;

  static Future<FirebaseApp> _defaultInitializeApp({
    FirebaseOptions? options,
  }) => Firebase.initializeApp(options: options);
}
