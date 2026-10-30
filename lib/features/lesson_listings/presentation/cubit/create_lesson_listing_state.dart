import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';

/// Form values and publication feedback owned by the creation cubit.
final class CreateLessonListingState {
  /// Creates an empty form with all contact sharing disabled by default.
  const CreateLessonListingState({
    this.subject = '',
    this.description = '',
    this.deliveryMode = LessonDeliveryMode.online,
    this.hasCertificate = false,
    this.certificateDescription = '',
    this.shareWhatsApp = false,
    this.whatsAppNumber = '',
    this.shareEmail = false,
    this.emailAddress = '',
    this.isSubmitting = false,
    this.failureType,
    this.createdListing,
  });

  /// The entered lesson subject.
  final String subject;

  /// The entered lesson description.
  final String description;

  /// The selected delivery mode.
  final LessonDeliveryMode deliveryMode;

  /// Whether the teacher declares a certificate.
  final bool hasCertificate;

  /// The teacher-provided certificate description.
  final String certificateDescription;

  /// Whether the teacher explicitly selected WhatsApp sharing.
  final bool shareWhatsApp;

  /// The entered phone number, including country code.
  final String whatsAppNumber;

  /// Whether the teacher explicitly selected email sharing.
  final bool shareEmail;

  /// The contact email, never inferred from the authentication session.
  final String emailAddress;

  /// Whether publication is pending.
  final bool isSubmitting;

  /// The controlled validation or publication failure.
  final LessonListingFailureType? failureType;

  /// The published listing after successful submission.
  final LessonListing? createdListing;

  /// Copies form values, clearing previous failure and result feedback.
  CreateLessonListingState copyWith({
    String? subject,
    String? description,
    LessonDeliveryMode? deliveryMode,
    bool? hasCertificate,
    String? certificateDescription,
    bool? shareWhatsApp,
    String? whatsAppNumber,
    bool? shareEmail,
    String? emailAddress,
    bool? isSubmitting,
    LessonListingFailureType? failureType,
    LessonListing? createdListing,
  }) => CreateLessonListingState(
    subject: subject ?? this.subject,
    description: description ?? this.description,
    deliveryMode: deliveryMode ?? this.deliveryMode,
    hasCertificate: hasCertificate ?? this.hasCertificate,
    certificateDescription:
        certificateDescription ?? this.certificateDescription,
    shareWhatsApp: shareWhatsApp ?? this.shareWhatsApp,
    whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
    shareEmail: shareEmail ?? this.shareEmail,
    emailAddress: emailAddress ?? this.emailAddress,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    failureType: failureType,
    createdListing: createdListing,
  );
}
