import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';

/// Validates email credentials before requesting authentication.
final class SignInWithEmailUseCase {
  /// Creates the use case with a provider-independent repository.
  const SignInWithEmailUseCase(this._repository);

  final AuthRepository _repository;
  static final RegExp _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Trims the email while preserving every character of the password.
  Future<AuthSession> call({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (!_emailFormat.hasMatch(normalizedEmail)) {
      throw const AuthFailure(AuthFailureType.invalidEmail);
    }
    if (password.length < AppConstants.minPasswordLength) {
      throw const AuthFailure(AuthFailureType.weakPassword);
    }
    return _repository.signInWithEmail(
      email: normalizedEmail,
      password: password,
    );
  }
}
