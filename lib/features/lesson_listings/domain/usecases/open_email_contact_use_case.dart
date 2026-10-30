import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/external_contact_repository.dart';

/// Trims and validates an email address before opening it externally.
final class OpenEmailContactUseCase {
  /// Creates the use case with a provider-independent repository.
  const OpenEmailContactUseCase(this._repository);

  static final RegExp _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final ExternalContactRepository _repository;

  /// Rejects invalid addresses while preserving the supplied email case.
  Future<void> call(String emailAddress) async {
    final normalizedAddress = emailAddress.trim();
    if (!_emailFormat.hasMatch(normalizedAddress)) {
      throw const ExternalContactFailure(
        ExternalContactFailureType.invalidContactValue,
      );
    }

    return _repository.openEmail(normalizedAddress);
  }
}
