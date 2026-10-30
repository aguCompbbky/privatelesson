/// Certificate information declared by the teacher, without verification.
final class CertificationInfo {
  /// Creates the teacher's certificate declaration.
  const CertificationInfo({
    required this.hasCertificate,
    this.certificateDescription,
  });

  /// Whether the teacher declares a relevant certificate.
  final bool hasCertificate;

  /// The teacher's description of the declared certificate, when present.
  final String? certificateDescription;
}
