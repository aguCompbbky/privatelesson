import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/external_contact_repository.dart';

/// Normalizes and validates a WhatsApp number before opening it externally.
final class OpenWhatsAppContactUseCase {
  /// Creates the use case with a provider-independent repository.
  const OpenWhatsAppContactUseCase(this._repository);

  static final RegExp _phoneSeparators = RegExp(r'[\s\-()]');
  static final RegExp _phoneFormat = RegExp(r'^\+[1-9]\d{7,14}$');

  final ExternalContactRepository _repository;

  /// Requires a country code and removes supported formatting separators.
  Future<void> call(String whatsAppNumber) async {
    final normalizedNumber = whatsAppNumber.trim().replaceAll(
      _phoneSeparators,
      '',
    );
    if (!_phoneFormat.hasMatch(normalizedNumber)) {
      throw const ExternalContactFailure(
        ExternalContactFailureType.invalidContactValue,
      );
    }

    return _repository.openWhatsApp(normalizedNumber);
  }
}
