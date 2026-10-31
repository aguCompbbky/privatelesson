import 'package:privatelesson/features/auth/data/datasources/auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source_exception.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';

/// The deterministic sign-in scenarios supported by the mock provider.
enum MockAuthOutcome {
  /// Sign-in returns the configured user.
  success,

  /// The user cancels sign-in.
  cancelled,

  /// Sign-in cannot reach the provider.
  connectionFailure,

  /// Sign-in fails to authenticate the identity.
  authenticationFailure,

  /// Sign-in fails to load the user's profile.
  profileLoadingFailure,
}

/// An in-memory authentication source with no network or SDK dependencies.
///
/// Only a successful sign-in stores a user; profile completion is not modelled.
final class MockAuthDataSource implements AuthDataSource {
  /// Creates a source with an explicit user fixture and fixed sign-in outcome.
  MockAuthDataSource({
    required AuthUserDto user,
    this.outcome = MockAuthOutcome.success,
  }) : _user = user;

  final AuthUserDto _user;

  /// The scenario returned on each sign-in attempt.
  final MockAuthOutcome outcome;

  AuthUserDto? _currentUser;
  final Map<String, ({AuthUserDto user, String password})> _emailAccounts = {};

  /// The user stored by a successful sign-in, or null after sign-out.
  AuthUserDto? get currentUser => _currentUser;

  /// Applies the configured scenario without accessing an external service.
  @override
  Future<AuthUserDto> signInWithGoogle() async {
    switch (outcome) {
      case MockAuthOutcome.success:
        _currentUser = _user;
        return _user;
      case MockAuthOutcome.cancelled:
        throw const AuthDataSourceException(AuthDataSourceError.cancelled);
      case MockAuthOutcome.connectionFailure:
        throw const AuthDataSourceException(AuthDataSourceError.connection);
      case MockAuthOutcome.authenticationFailure:
        throw const AuthDataSourceException(AuthDataSourceError.authentication);
      case MockAuthOutcome.profileLoadingFailure:
        throw const AuthDataSourceException(AuthDataSourceError.profileLoading);
    }
  }

  /// Creates a deterministic account that survives signing out.
  @override
  Future<AuthUserDto> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (outcome != MockAuthOutcome.success) {
      return signInWithGoogle();
    }
    final key = email.trim().toLowerCase();
    if (_emailAccounts.containsKey(key)) {
      throw const AuthDataSourceException(
        AuthDataSourceError.emailAlreadyInUse,
      );
    }
    final user = AuthUserDto(
      userId: 'email-user-${_emailAccounts.length + 1}',
      displayName: displayName,
    );
    _emailAccounts[key] = (user: user, password: password);
    _currentUser = user;
    return user;
  }

  /// Checks the stored credentials without modifying either password.
  @override
  Future<AuthUserDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (outcome != MockAuthOutcome.success) {
      return signInWithGoogle();
    }
    final account = _emailAccounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthDataSourceException(
        AuthDataSourceError.invalidCredentials,
      );
    }
    _currentUser = account.user;
    return account.user;
  }

  /// Clears the in-memory session; repeated sign-out calls also succeed.
  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
}
