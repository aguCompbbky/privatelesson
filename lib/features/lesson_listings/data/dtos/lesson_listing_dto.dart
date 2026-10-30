import 'package:privatelesson/features/lesson_listings/domain/entities/certification_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';

/// A flat storage payload with validation at every conversion boundary.
final class LessonListingDto {
  /// Creates a payload; conversions reject malformed values.
  const LessonListingDto({
    required this.id,
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

  /// Reads storage fields and rejects invalid types, enums or combinations.
  ///
  /// Optional fields may be absent or null. Extra keys are discarded and
  /// authentication email fields are never substituted for contact fields.
  factory LessonListingDto.fromMap(Map<String, Object?> map) {
    final hasCertificate = map['hasCertificate'];
    if (hasCertificate is! bool) {
      throw const FormatException(_invalidPayload);
    }
    final dto = LessonListingDto(
      id: _requiredString(map, 'id'),
      teacherId: _requiredString(map, 'teacherId'),
      teacherName: _requiredString(map, 'teacherName'),
      subject: _requiredString(map, 'subject'),
      description: _requiredString(map, 'description'),
      deliveryMode: _requiredString(map, 'deliveryMode'),
      hasCertificate: hasCertificate,
      certificateDescription: _optionalString(map, 'certificateDescription'),
      whatsAppNumber: _optionalString(map, 'whatsAppNumber'),
      emailAddress: _optionalString(map, 'emailAddress'),
    );
    dto._validate();
    return dto;
  }

  /// Converts a domain listing into a validated storage payload.
  factory LessonListingDto.fromEntity(LessonListing listing) {
    final dto = LessonListingDto(
      id: listing.id,
      teacherId: listing.teacherId,
      teacherName: listing.teacherName,
      subject: listing.subject,
      description: listing.description,
      deliveryMode: listing.deliveryMode.name,
      hasCertificate: listing.certification.hasCertificate,
      certificateDescription: listing.certification.certificateDescription,
      whatsAppNumber: listing.contact.whatsAppNumber,
      emailAddress: listing.contact.emailAddress,
    );
    dto._validate();
    return dto;
  }

  /// Assigns a storage identifier to validated new listing information.
  factory LessonListingDto.fromNewListing(
    NewLessonListing listing, {
    required String id,
  }) => LessonListingDto.fromEntity(
    LessonListing(
      id: id,
      teacherId: listing.teacherId,
      teacherName: listing.teacherName,
      subject: listing.subject,
      description: listing.description,
      deliveryMode: listing.deliveryMode,
      certification: listing.certification,
      contact: listing.contact,
    ),
  );

  static const String _invalidPayload = 'Invalid lesson listing payload.';
  static final RegExp _phoneFormat = RegExp(r'^\+[1-9]\d{7,14}$');
  static final RegExp _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// The stored listing identifier.
  final String id;

  /// The identifier of the teacher who owns the listing.
  final String teacherId;

  /// The teacher's public display name.
  final String teacherName;

  /// The lesson subject.
  final String subject;

  /// The teacher's lesson description.
  final String description;

  /// The stored delivery mode name.
  final String deliveryMode;

  /// Whether the teacher declares a certificate.
  final bool hasCertificate;

  /// The certificate description, present only for a declared certificate.
  final String? certificateDescription;

  /// The normalized, explicitly shared WhatsApp number.
  final String? whatsAppNumber;

  /// The explicitly shared contact email.
  final String? emailAddress;

  /// Writes a new map after rejecting malformed payload values.
  Map<String, Object?> toMap() {
    _validate();
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subject': subject,
      'description': description,
      'deliveryMode': deliveryMode,
      'hasCertificate': hasCertificate,
      'certificateDescription': certificateDescription,
      'whatsAppNumber': whatsAppNumber,
      'emailAddress': emailAddress,
    };
  }

  /// Converts a valid payload to domain values, or throws [FormatException].
  LessonListing toEntity() {
    _validate();
    return LessonListing(
      id: id,
      teacherId: teacherId,
      teacherName: teacherName,
      subject: subject,
      description: description,
      deliveryMode: _parsedDeliveryMode,
      certification: CertificationInfo(
        hasCertificate: hasCertificate,
        certificateDescription: certificateDescription,
      ),
      contact: TeacherContactInfo(
        whatsAppNumber: whatsAppNumber,
        emailAddress: emailAddress,
      ),
    );
  }

  LessonDeliveryMode get _parsedDeliveryMode => switch (deliveryMode) {
    'inPerson' => LessonDeliveryMode.inPerson,
    'online' => LessonDeliveryMode.online,
    'recordedVideo' => LessonDeliveryMode.recordedVideo,
    _ => throw const FormatException(_invalidPayload),
  };

  void _validate() {
    if ([id, teacherId, teacherName, subject, description].any(
      (value) => value.trim().isEmpty,
    )) {
      throw const FormatException(_invalidPayload);
    }
    if (!LessonDeliveryMode.values.any((mode) => mode.name == deliveryMode)) {
      throw const FormatException(_invalidPayload);
    }
    final certificate = certificateDescription;
    if (hasCertificate
        ? certificate == null || certificate.trim().isEmpty
        : certificate != null) {
      throw const FormatException(_invalidPayload);
    }
    final phone = whatsAppNumber;
    final email = emailAddress;
    if (phone == null && email == null) {
      throw const FormatException(_invalidPayload);
    }
    if (phone != null && !_phoneFormat.hasMatch(phone)) {
      throw const FormatException(_invalidPayload);
    }
    if (email != null && !_emailFormat.hasMatch(email)) {
      throw const FormatException(_invalidPayload);
    }
  }

  static String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String) {
      throw const FormatException(_invalidPayload);
    }
    return value;
  }

  static String? _optionalString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value != null && value is! String) {
      throw const FormatException(_invalidPayload);
    }
    return value as String?;
  }
}
