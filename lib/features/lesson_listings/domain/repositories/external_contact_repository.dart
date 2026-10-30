/// The provider-independent contract for contacting a listing's teacher.
abstract interface class ExternalContactRepository {
  /// Opens WhatsApp using a validated number with its leading country code.
  Future<void> openWhatsApp(String whatsAppNumber);

  /// Opens an email application using a validated email address.
  Future<void> openEmail(String emailAddress);

  /// Copies a nonblank contact value for use outside the application.
  Future<void> copyContactValue(String value);
}
