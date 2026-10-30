import 'package:privatelesson/features/auth/data/datasources/auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source_exception.dart';
import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';

/// Converts data payloads and provider exceptions into domain types.
final class AuthRepositoryImpl implements AuthRepository {
  /// Creates a repository using any adapter for the data source contract.
  const AuthRepositoryImpl(this._dataSource);

  final AuthDataSource _dataSource;

  /// Returns the identity and translates provider failures to [AuthFailure].
  ///
  /// Malformed payloads become profile-loading failures. Other exceptions
  /// become authentication failures; programming errors are not intercepted.
  @override
  Future<AuthSession> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return user.toEntity();
    } on AuthDataSourceException catch (error) {
      throw _mapFailure(error);
    } on FormatException {
      throw const AuthFailure(AuthFailureType.profileLoading);
    } on Exception {
      throw const AuthFailure(AuthFailureType.authentication);
    }
  }

  /// Waits for sign-out and translates provider failures to [AuthFailure].
  ///
  /// Unclassified exceptions become authentication failures.
  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } on AuthDataSourceException catch (error) {
      throw _mapFailure(error);
    } on Exception {
      throw const AuthFailure(AuthFailureType.authentication);
    }
  }

  AuthFailure _mapFailure(AuthDataSourceException error) =>
      AuthFailure(switch (error.code) {
        AuthDataSourceError.cancelled => AuthFailureType.cancelled,
        AuthDataSourceError.connection => AuthFailureType.connection,
        AuthDataSourceError.authentication => AuthFailureType.authentication,
        AuthDataSourceError.profileLoading => AuthFailureType.profileLoading,
      });
}
