import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/external_contact_repository.dart';

/// Validates a contact value before copying it for external use.
final class CopyContactValueUseCase {
  /// Creates the use case with a provider-independent repository.
  const CopyContactValueUseCase(this._repository);

  final ExternalContactRepository _repository;

  /// Trims surrounding whitespace and rejects empty values.
  Future<void> call(String value) async {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      throw const ExternalContactFailure(
        ExternalContactFailureType.invalidContactValue,
      );
    }

    return _repository.copyContactValue(normalizedValue);
  }
}
