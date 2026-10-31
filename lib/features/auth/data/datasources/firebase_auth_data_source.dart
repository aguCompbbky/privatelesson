import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source_exception.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';

/// Minimal identity fields returned by an authentication SDK session.
final class FirebaseAuthIdentity {
  /// Creates a provider identity snapshot without leaking SDK user objects.
  const FirebaseAuthIdentity({
    required this.uid,
    required this.displayName,
  });

  /// Unique provider identifier of the authenticated user.
  final String uid;

  /// Display name reported by the provider, or an empty string when absent.
  final String displayName;
}

/// Google token and profile snapshot exchanged for a Firebase session.
final class GoogleAuthTokens {
  /// Creates a Google token bundle from an interactive sign-in result.
  const GoogleAuthTokens({
    required this.idToken,
    required this.displayName,
  });

  /// OpenID Connect ID token issued by Google Sign-In.
  final String? idToken;

  /// Optional display name supplied by the Google account.
  final String? displayName;
}

/// Replaceable SDK gateway that keeps [FirebaseAuthDataSource] unit-testable.
abstract interface class FirebaseAuthGateway {
  /// Runs interactive Google sign-in and returns its token snapshot.
  Future<GoogleAuthTokens> authenticateWithGoogle();

  /// Exchanges a Google [idToken] for a Firebase session.
  Future<FirebaseAuthIdentity?> signInWithGoogleIdToken(String idToken);

  /// Signs in with [email] and [password].
  Future<FirebaseAuthIdentity?> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates an account with [email] and [password], applying [displayName].
  Future<FirebaseAuthIdentity?> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  });

  /// Ends active Firebase and Google sessions.
  Future<void> signOut();
}

/// Concrete [AuthDataSource] backed by `firebase_auth` and `google_sign_in`.
///
/// Firebase and Google SDK dependencies remain strictly inside this adapter.
final class FirebaseAuthDataSource implements AuthDataSource {
  /// Creates a Firebase authentication data source with an optional gateway.
  FirebaseAuthDataSource({
    FirebaseAuthGateway? gateway,
    String? googleClientId,
    String? googleServerClientId,
  }) : _gateway =
           gateway ??
           _SdkFirebaseAuthGateway(
             googleClientId: googleClientId,
             googleServerClientId: googleServerClientId,
           );

  final FirebaseAuthGateway _gateway;

  @override
  Future<AuthUserDto> signInWithGoogle() async {
    try {
      final google = await _gateway.authenticateWithGoogle();
      final idToken = google.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const AuthDataSourceException(
          AuthDataSourceError.authentication,
        );
      }
      final identity = await _gateway.signInWithGoogleIdToken(idToken);
      if (identity == null || identity.uid.trim().isEmpty) {
        throw const AuthDataSourceException(
          AuthDataSourceError.authentication,
        );
      }
      final resolvedName = identity.displayName.trim().isNotEmpty
          ? identity.displayName.trim()
          : (google.displayName?.trim() ?? '');
      return AuthUserDto(userId: identity.uid, displayName: resolvedName);
    } on AuthDataSourceException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw _mapGoogleException(error);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthException(error);
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  @override
  Future<AuthUserDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final identity = await _gateway.signInWithEmail(
        email: email,
        password: password,
      );
      if (identity == null || identity.uid.trim().isEmpty) {
        throw const AuthDataSourceException(
          AuthDataSourceError.authentication,
        );
      }
      return AuthUserDto(
        userId: identity.uid,
        displayName: identity.displayName.trim(),
      );
    } on AuthDataSourceException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthException(error);
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  @override
  Future<AuthUserDto> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final trimmedName = displayName.trim();
      final identity = await _gateway.registerWithEmail(
        displayName: trimmedName,
        email: email,
        password: password,
      );
      if (identity == null || identity.uid.trim().isEmpty) {
        throw const AuthDataSourceException(
          AuthDataSourceError.authentication,
        );
      }
      final resolvedName = identity.displayName.trim().isNotEmpty
          ? identity.displayName.trim()
          : trimmedName;
      return AuthUserDto(userId: identity.uid, displayName: resolvedName);
    } on AuthDataSourceException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthException(error);
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _gateway.signOut();
    } on AuthDataSourceException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw _mapGoogleException(error);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthException(error);
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  AuthDataSourceException _mapGoogleException(GoogleSignInException error) =>
      AuthDataSourceException(switch (error.code) {
        GoogleSignInExceptionCode.canceled => AuthDataSourceError.cancelled,
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.uiUnavailable =>
          AuthDataSourceError.connection,
        GoogleSignInExceptionCode.unknownError ||
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError ||
        GoogleSignInExceptionCode.userMismatch =>
          AuthDataSourceError.authentication,
      });

  AuthDataSourceException _mapFirebaseAuthException(
    FirebaseAuthException error,
  ) => AuthDataSourceException(switch (error.code) {
    'canceled' ||
    'cancelled' ||
    'popup-closed-by-user' ||
    'web-context-canceled' => AuthDataSourceError.cancelled,
    'network-request-failed' || 'unavailable' => AuthDataSourceError.connection,
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' => AuthDataSourceError.invalidCredentials,
    'email-already-in-use' => AuthDataSourceError.emailAlreadyInUse,
    _ => AuthDataSourceError.authentication,
  });

  AuthDataSourceException _mapFirebaseException(FirebaseException error) =>
      AuthDataSourceException(
        error.code == 'network-request-failed' || error.code == 'unavailable'
            ? AuthDataSourceError.connection
            : AuthDataSourceError.authentication,
      );
}

final class _SdkFirebaseAuthGateway implements FirebaseAuthGateway {
  _SdkFirebaseAuthGateway({
    this.googleClientId,
    this.googleServerClientId,
  });

  static Future<void>? _googleInitialization;

  final String? googleClientId;
  final String? googleServerClientId;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  GoogleSignIn get _google => GoogleSignIn.instance;

  Future<void> _ensureGoogleInitialized() {
    final existing = _googleInitialization;
    if (existing != null) {
      return existing;
    }
    final pending = _google.initialize(
      clientId: googleClientId,
      serverClientId: googleServerClientId,
    );
    _googleInitialization = pending;
    return pending;
  }

  @override
  Future<GoogleAuthTokens> authenticateWithGoogle() async {
    await _ensureGoogleInitialized();
    final account = await _google.authenticate();
    return GoogleAuthTokens(
      idToken: account.authentication.idToken,
      displayName: account.displayName,
    );
  }

  @override
  Future<FirebaseAuthIdentity?> signInWithGoogleIdToken(String idToken) async {
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    return _toIdentity(result.user);
  }

  @override
  Future<FirebaseAuthIdentity?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _toIdentity(result.user);
  }

  @override
  Future<FirebaseAuthIdentity?> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;
    if (user == null) {
      return null;
    }
    if (displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }
    return FirebaseAuthIdentity(
      uid: user.uid,
      displayName: displayName.isNotEmpty
          ? displayName
          : (user.displayName ?? ''),
    );
  }

  @override
  Future<void> signOut() async {
    if (_googleInitialization != null) {
      await _ensureGoogleInitialized();
      await _google.signOut();
    }
    await _auth.signOut();
  }

  FirebaseAuthIdentity? _toIdentity(User? user) {
    if (user == null) {
      return null;
    }
    return FirebaseAuthIdentity(
      uid: user.uid,
      displayName: user.displayName ?? '',
    );
  }
}
