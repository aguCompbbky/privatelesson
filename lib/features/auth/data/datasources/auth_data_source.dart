import 'package:privatelesson/features/auth/data/datasources/auth_data_source_exception.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';

/// The replaceable data-layer authentication provider contract.
abstract interface class AuthDataSource {
  /// Returns the signed-in user's payload.
  ///
  /// Adapters report known provider failures as [AuthDataSourceException].
  /// Malformed user payloads may throw [FormatException].
  Future<AuthUserDto> signInWithGoogle();

  /// Ends the provider session, including when no session is active.
  ///
  /// Adapters report known provider failures as [AuthDataSourceException].
  Future<void> signOut();
}
