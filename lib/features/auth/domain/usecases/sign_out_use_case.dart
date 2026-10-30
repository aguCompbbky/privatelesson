import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';

/// Requests sign-out through the domain repository contract.
final class SignOutUseCase {
  /// Creates the use case with its authentication repository.
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  /// Completes after sign-out or propagates the repository's [AuthFailure].
  Future<void> call() => _repository.signOut();
}
