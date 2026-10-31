import 'package:privatelesson/features/auth/data/datasources/auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source_exception.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';
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
  Future<AuthSession> signInWithGoogle() => _authenticate(
    _dataSource.signInWithGoogle,
  );

  /// Converts an email sign-in response and classifies provider failures.
  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) => _authenticate(
    () => _dataSource.signInWithEmail(email: email, password: password),
  );

  /// Converts a registration response and classifies provider failures.
  @override
  Future<AuthSession> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) => _authenticate(
    () => _dataSource.registerWithEmail(
      displayName: displayName,
      email: email,
      password: password,
    ),
  );

  Future<AuthSession> _authenticate(
    Future<AuthUserDto> Function() authenticate,
  ) async {
    try {
      final user = await authenticate();
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
        AuthDataSourceError.invalidCredentials =>
          AuthFailureType.invalidCredentials,
        AuthDataSourceError.emailAlreadyInUse =>
          AuthFailureType.emailAlreadyInUse,
        AuthDataSourceError.cancelled => AuthFailureType.cancelled,
        AuthDataSourceError.connection => AuthFailureType.connection,
        AuthDataSourceError.authentication => AuthFailureType.authentication,
        AuthDataSourceError.profileLoading => AuthFailureType.profileLoading,
      });
}
