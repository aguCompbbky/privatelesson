import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';

/// Raw form values to be validated before publishing a lesson.
final class CreateLessonListingInput {
  /// Creates input without assuming that any text has been validated.
  const CreateLessonListingInput({
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.description,
    required this.deliveryMode,
    required this.hasCertificate,
    this.certificateDescription,
    this.whatsAppNumber,
    this.emailAddress,
  });

  /// The identifier of the teacher publishing the listing.
  final String teacherId;

  /// The teacher's entered display name.
  final String teacherName;

  /// The entered lesson subject.
  final String subject;

  /// The entered lesson description.
  final String description;

  /// The teacher's selected delivery mode.
  final LessonDeliveryMode deliveryMode;

  /// Whether the teacher declares a relevant certificate.
  final bool hasCertificate;

  /// The entered certificate description, if any.
  final String? certificateDescription;

  /// The selected WhatsApp input; null means the channel was not selected.
  final String? whatsAppNumber;

  /// The selected contact email; null means the channel was not selected.
  /// This value is independent of authentication details.
  final String? emailAddress;
}
