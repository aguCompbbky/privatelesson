import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';

/// Provides authentication independently of the underlying service.
abstract interface class AuthRepository {
  /// Signs in with Google and returns the minimal authenticated identity.
  ///
  /// Throws [AuthFailure] on cancellation or an authentication operation error.
  /// A returned session does not imply that profile completion has occurred.
  Future<AuthSession> signInWithGoogle();

  /// Authenticates an existing email account.
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registers an email account and returns its authenticated identity.
  Future<AuthSession> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  });

  /// Ends the current session, or throws [AuthFailure] if sign-out fails.
  Future<void> signOut();
}
