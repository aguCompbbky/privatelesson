import 'package:privatelesson/features/auth/data/datasources/auth_data_source_exception.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';

/// The replaceable data-layer authentication provider contract.
abstract interface class AuthDataSource {
  /// Returns the signed-in user's payload.
  ///
  /// Adapters report known provider failures as [AuthDataSourceException].
  /// Malformed user payloads may throw [FormatException].
  Future<AuthUserDto> signInWithGoogle();

  /// Authenticates an existing email account.
  Future<AuthUserDto> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registers an email account and returns its authenticated identity.
  Future<AuthUserDto> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  });

  /// Ends the provider session, including when no session is active.
  ///
  /// Adapters report known provider failures as [AuthDataSourceException].
  Future<void> signOut();
}
