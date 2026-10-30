import 'package:privatelesson/features/lesson_listings/domain/entities/certification_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';

/// Validated listing information awaiting an identifier from storage.
final class NewLessonListing {
  /// Creates the normalized result of listing validation.
  const NewLessonListing({
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.description,
    required this.deliveryMode,
    required this.certification,
    required this.contact,
  });

  /// The identifier of the teacher publishing the listing.
  final String teacherId;

  /// The teacher's publicly displayed name.
  final String teacherName;

  /// The subject taught in this lesson.
  final String subject;

  /// The teacher's description of the lesson.
  final String description;

  /// How the lesson is delivered outside the platform.
  final LessonDeliveryMode deliveryMode;

  /// The teacher's certificate declaration, without platform verification.
  final CertificationInfo certification;

  /// The explicitly selected and validated contact methods.
  final TeacherContactInfo contact;
}
