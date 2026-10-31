import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';

/// Validates and normalizes registration independently of the provider.
final class RegisterWithEmailUseCase {
  /// Creates registration with the authentication repository contract.
  const RegisterWithEmailUseCase(this._repository);

  final AuthRepository _repository;
  static final RegExp _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Trims identity fields and preserves the password exactly as entered.
  Future<AuthSession> call({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedDisplayName = displayName.trim();
    final normalizedEmail = email.trim();
    if (normalizedDisplayName.isEmpty) {
      throw const AuthFailure(AuthFailureType.invalidDisplayName);
    }
    if (!_emailFormat.hasMatch(normalizedEmail)) {
      throw const AuthFailure(AuthFailureType.invalidEmail);
    }
    if (password.length < AppConstants.minPasswordLength) {
      throw const AuthFailure(AuthFailureType.weakPassword);
    }
    if (password != confirmPassword) {
      throw const AuthFailure(AuthFailureType.passwordMismatch);
    }
    return _repository.registerWithEmail(
      displayName: normalizedDisplayName,
      email: normalizedEmail,
      password: password,
    );
  }
}
