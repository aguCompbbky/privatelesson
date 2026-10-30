/// Contact methods explicitly selected for publication by the teacher.
final class TeacherContactInfo {
  /// Creates contact information independently of authentication details.
  const TeacherContactInfo({this.whatsAppNumber, this.emailAddress});

  /// The selected WhatsApp number including its country code.
  final String? whatsAppNumber;

  /// The selected contact email, which need not be the sign-in email.
  final String? emailAddress;

  /// Whether the teacher has shared a WhatsApp number.
  bool get hasWhatsApp => whatsAppNumber != null;

  /// Whether the teacher has shared a contact email.
  bool get hasEmail => emailAddress != null;
}
