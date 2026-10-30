import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/create_lesson_listing_input.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/create_lesson_listing_use_case.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_state.dart';

/// Owns form editing and delegates authorization and validation to the domain.
final class CreateLessonListingCubit extends Cubit<CreateLessonListingState> {
  /// Creates a form depending only on the publication use case.
  CreateLessonListingCubit({
    required CreateLessonListingUseCase createLessonListingUseCase,
  }) : _createListing = createLessonListingUseCase,
       super(const CreateLessonListingState());

  final CreateLessonListingUseCase _createListing;

  /// Updates subject, clearing any previous failure.
  void updateSubject(String value) => _edit(state.copyWith(subject: value));

  /// Updates description, clearing any previous failure.
  void updateDescription(String value) =>
      _edit(state.copyWith(description: value));

  /// Updates deliveryMode, clearing any previous failure.
  void selectDeliveryMode(LessonDeliveryMode value) =>
      _edit(state.copyWith(deliveryMode: value));

  /// Updates hasCertificate, clearing any previous failure.
  void setHasCertificate({required bool value}) =>
      _edit(state.copyWith(hasCertificate: value));

  /// Updates certificateDescription, clearing any previous failure.
  void updateCertificateDescription(String value) =>
      _edit(state.copyWith(certificateDescription: value));

  /// Updates shareWhatsApp, clearing any previous failure.
  void setShareWhatsApp({required bool value}) =>
      _edit(state.copyWith(shareWhatsApp: value));

  /// Updates whatsAppNumber, clearing any previous failure.
  void updateWhatsAppNumber(String value) =>
      _edit(state.copyWith(whatsAppNumber: value));

  /// Updates shareEmail, clearing any previous failure.
  void setShareEmail({required bool value}) =>
      _edit(state.copyWith(shareEmail: value));

  /// Updates emailAddress, clearing any previous failure.
  void updateEmailAddress(String value) =>
      _edit(state.copyWith(emailAddress: value));

  void _edit(CreateLessonListingState next) {
    if (!isClosed && !state.isSubmitting) {
      emit(next);
    }
  }

  /// Publishes only explicitly selected contact channels for this actor.
  Future<void> submit(UserProfile actor) async {
    if (isClosed || state.isSubmitting) {
      return;
    }
    final form = state;
    emit(form.copyWith(isSubmitting: true));
    try {
      final listing = await _createListing(
        actorRole: actor.role,
        input: CreateLessonListingInput(
          teacherId: actor.userId,
          teacherName: actor.displayName,
          subject: form.subject,
          description: form.description,
          deliveryMode: form.deliveryMode,
          hasCertificate: form.hasCertificate,
          certificateDescription: form.certificateDescription,
          whatsAppNumber: form.shareWhatsApp ? form.whatsAppNumber : null,
          emailAddress: form.shareEmail ? form.emailAddress : null,
        ),
      );
      if (!isClosed) {
        emit(form.copyWith(isSubmitting: false, createdListing: listing));
      }
    } on LessonListingFailure catch (failure) {
      if (!isClosed) {
        emit(form.copyWith(isSubmitting: false, failureType: failure.type));
      }
    } on Object {
      if (!isClosed) {
        emit(form.copyWith(isSubmitting: false));
      }
      rethrow;
    }
  }
}
