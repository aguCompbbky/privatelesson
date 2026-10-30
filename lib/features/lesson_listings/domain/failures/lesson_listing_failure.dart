/// Provider-independent reasons why a listing operation can fail.
enum LessonListingFailureType {
  /// Only teachers may publish listings.
  unauthorizedRole,

  /// The teacher identifier or display name is blank.
  invalidTeacherInfo,

  /// The lesson subject is blank.
  invalidSubject,

  /// The lesson description is blank.
  invalidDescription,

  /// A declared certificate has no description.
  missingCertificateDescription,

  /// Neither contact method has been selected and filled in.
  missingContactMethod,

  /// The WhatsApp number is not in the supported country-code format.
  invalidWhatsAppNumber,

  /// The selected email does not have a valid format.
  invalidEmailAddress,

  /// The requested listing does not exist.
  notFound,

  /// The listing provider cannot be reached.
  connection,

  /// Storage failed or returned malformed listing data.
  storage,
}

/// A controlled domain failure without provider-specific information.
final class LessonListingFailure implements Exception {
  /// Creates a failure with its domain reason.
  const LessonListingFailure(this.type);

  /// The reason the operation failed.
  final LessonListingFailureType type;
}
