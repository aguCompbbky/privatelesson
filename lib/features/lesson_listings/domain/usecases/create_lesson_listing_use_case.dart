import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/certification_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/create_lesson_listing_input.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/lesson_listing_repository.dart';

/// Authorizes teachers and validates explicitly entered listing information.
final class CreateLessonListingUseCase {
  /// Creates the use case with a provider-independent repository.
  const CreateLessonListingUseCase(this._repository);

  static final RegExp _phoneSeparators = RegExp(r'[\s\-()]');
  static final RegExp _phoneFormat = RegExp(r'^\+[1-9]\d{7,14}$');
  static final RegExp _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final LessonListingRepository _repository;

  /// Rejects unauthorized or invalid input before calling the repository.
  ///
  /// Only contact values supplied in [input] are published. Authentication
  /// details are never used to infer a contact method.
  Future<LessonListing> call({
    required UserRole actorRole,
    required CreateLessonListingInput input,
  }) async {
    if (actorRole != UserRole.teacher) {
      throw const LessonListingFailure(
        LessonListingFailureType.unauthorizedRole,
      );
    }

    final teacherId = input.teacherId.trim();
    final teacherName = input.teacherName.trim();
    final subject = input.subject.trim();
    final description = input.description.trim();
    if (teacherId.isEmpty || teacherName.isEmpty) {
      throw const LessonListingFailure(
        LessonListingFailureType.invalidTeacherInfo,
      );
    }
    if (subject.isEmpty) {
      throw const LessonListingFailure(LessonListingFailureType.invalidSubject);
    }
    if (description.isEmpty) {
      throw const LessonListingFailure(
        LessonListingFailureType.invalidDescription,
      );
    }

    final certificateDescription = input.hasCertificate
        ? _optionalText(input.certificateDescription)
        : null;
    if (input.hasCertificate && certificateDescription == null) {
      throw const LessonListingFailure(
        LessonListingFailureType.missingCertificateDescription,
      );
    }

    final phone = _optionalText(input.whatsAppNumber);
    final whatsAppNumber = phone?.replaceAll(_phoneSeparators, '');
    if (input.whatsAppNumber != null &&
        (whatsAppNumber == null || !_phoneFormat.hasMatch(whatsAppNumber))) {
      throw const LessonListingFailure(
        LessonListingFailureType.invalidWhatsAppNumber,
      );
    }
    final emailAddress = _optionalText(input.emailAddress);
    if (input.emailAddress != null &&
        (emailAddress == null || !_emailFormat.hasMatch(emailAddress))) {
      throw const LessonListingFailure(
        LessonListingFailureType.invalidEmailAddress,
      );
    }
    if (whatsAppNumber == null && emailAddress == null) {
      throw const LessonListingFailure(
        LessonListingFailureType.missingContactMethod,
      );
    }

    return _repository.createListing(
      NewLessonListing(
        teacherId: teacherId,
        teacherName: teacherName,
        subject: subject,
        description: description,
        deliveryMode: input.deliveryMode,
        certification: CertificationInfo(
          hasCertificate: input.hasCertificate,
          certificateDescription: certificateDescription,
        ),
        contact: TeacherContactInfo(
          whatsAppNumber: whatsAppNumber,
          emailAddress: emailAddress,
        ),
      ),
    );
  }

  static String? _optionalText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
