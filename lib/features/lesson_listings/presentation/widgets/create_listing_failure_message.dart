import 'package:flutter/material.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';

/// Announces a distinct localized explanation for each creation failure.
class CreateListingFailureMessage extends StatelessWidget {
  /// Creates an accessible failure message.
  const CreateListingFailureMessage({required this.type, super.key});

  /// The domain failure returned by publication.
  final LessonListingFailureType type;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final message = switch (type) {
      LessonListingFailureType.unauthorizedRole =>
        TextUtils.createListingUnauthorizedRoleError,
      LessonListingFailureType.invalidTeacherInfo =>
        TextUtils.createListingInvalidTeacherInfoError,
      LessonListingFailureType.invalidSubject =>
        TextUtils.createListingInvalidSubjectError,
      LessonListingFailureType.invalidDescription =>
        TextUtils.createListingInvalidDescriptionError,
      LessonListingFailureType.missingCertificateDescription =>
        TextUtils.createListingMissingCertificateDescriptionError,
      LessonListingFailureType.missingContactMethod =>
        TextUtils.createListingMissingContactMethodError,
      LessonListingFailureType.invalidWhatsAppNumber =>
        TextUtils.createListingInvalidWhatsAppNumberError,
      LessonListingFailureType.invalidEmailAddress =>
        TextUtils.createListingInvalidEmailAddressError,
      LessonListingFailureType.notFound => TextUtils.createListingNotFoundError,
      LessonListingFailureType.connection =>
        TextUtils.createListingConnectionError,
      LessonListingFailureType.storage => TextUtils.createListingStorageError,
    };
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
