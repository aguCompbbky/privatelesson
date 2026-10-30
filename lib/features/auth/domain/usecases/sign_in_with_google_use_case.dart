import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';

/// Requests Google sign-in through the domain repository contract.
final class SignInWithGoogleUseCase {
  /// Creates the use case with its authentication repository.
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  /// Returns the session or propagates the repository's [AuthFailure].
  Future<AuthSession> call() => _repository.signInWithGoogle();
}
