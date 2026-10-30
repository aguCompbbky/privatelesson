import 'package:privatelesson/features/lesson_listings/data/datasources/external_contact_data_source.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/external_contact_repository.dart';

/// Builds contact URIs and translates platform exceptions to domain failures.
final class ExternalContactRepositoryImpl implements ExternalContactRepository {
  /// Creates a repository with a replaceable external contact adapter.
  const ExternalContactRepositoryImpl(this._dataSource);

  final ExternalContactDataSource _dataSource;

  /// Opens a WhatsApp URL using a validated international number.
  @override
  Future<void> openWhatsApp(String whatsAppNumber) {
    final digits = whatsAppNumber.startsWith('+')
        ? whatsAppNumber.substring(1)
        : whatsAppNumber;
    return _launchUri(Uri.https('wa.me', digits));
  }

  /// Opens an email URI while keeping the address in its path component.
  @override
  Future<void> openEmail(String emailAddress) =>
      _launchUri(Uri(scheme: 'mailto', path: emailAddress));

  /// Copies the value, mapping platform exceptions to a clipboard failure.
  @override
  Future<void> copyContactValue(String value) async {
    try {
      await _dataSource.copyToClipboard(value);
    } on Exception {
      throw const ExternalContactFailure(
        ExternalContactFailureType.clipboardFailed,
      );
    }
  }

  Future<void> _launchUri(Uri uri) async {
    final bool launched;
    try {
      launched = await _dataSource.launchUri(uri);
    } on Exception {
      throw const ExternalContactFailure(
        ExternalContactFailureType.cannotOpenExternalApp,
      );
    }
    if (!launched) {
      throw const ExternalContactFailure(
        ExternalContactFailureType.cannotOpenExternalApp,
      );
    }
  }
}
