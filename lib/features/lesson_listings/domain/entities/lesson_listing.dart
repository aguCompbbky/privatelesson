import 'package:privatelesson/features/lesson_listings/domain/entities/certification_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';

/// A published lesson and the information its teacher chose to share.
final class LessonListing {
  /// Creates a listing with its assigned identifier.
  const LessonListing({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.description,
    required this.deliveryMode,
    required this.certification,
    required this.contact,
  });

  /// The identifier assigned to this listing.
  final String id;

  /// The identifier of the teacher who owns this listing.
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

  /// The contact methods explicitly shared by the teacher.
  final TeacherContactInfo contact;
}
