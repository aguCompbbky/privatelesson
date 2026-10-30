import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/copy_contact_value_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/get_lesson_listing_detail_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/open_email_contact_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/open_whatsapp_contact_use_case.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_state.dart';

/// Coordinates detail loading and external contact through domain use cases.
final class LessonListingDetailCubit extends Cubit<LessonListingDetailState> {
  /// Creates a cubit for one listing with replaceable domain use cases.
  LessonListingDetailCubit({
    required this.listingId,
    required GetLessonListingDetailUseCase getLessonListingDetailUseCase,
    required OpenWhatsAppContactUseCase openWhatsAppContactUseCase,
    required OpenEmailContactUseCase openEmailContactUseCase,
    required CopyContactValueUseCase copyContactValueUseCase,
  }) : _getDetail = getLessonListingDetailUseCase,
       _openWhatsApp = openWhatsAppContactUseCase,
       _openEmail = openEmailContactUseCase,
       _copyContact = copyContactValueUseCase,
       super(const LessonListingDetailState()) {
    _settledState = state;
  }

  /// The identifier of the requested listing.
  final String listingId;

  final GetLessonListingDetailUseCase _getDetail;
  final OpenWhatsAppContactUseCase _openWhatsApp;
  final OpenEmailContactUseCase _openEmail;
  final CopyContactValueUseCase _copyContact;
  late LessonListingDetailState _settledState;
  int _requestId = 0;
  int _contactRequestId = 0;

  /// Loads detail, ignoring stale results and preserving typed failures.
  Future<void> loadDetail() async {
    if (isClosed) {
      return;
    }
    final requestId = ++_requestId;
    _contactRequestId += 1;
    final previous = _settledState;
    emit(LessonListingDetailState(listing: previous.listing, isLoading: true));
    try {
      final listing = await _getDetail(listingId);
      if (_isCurrent(requestId)) {
        _settle(LessonListingDetailState(listing: listing));
      }
    } on LessonListingFailure catch (failure) {
      if (_isCurrent(requestId)) {
        _settle(
          LessonListingDetailState(
            listing: previous.listing,
            failureType: failure.type,
          ),
        );
      }
    } on Object {
      if (_isCurrent(requestId)) {
        _settle(
          LessonListingDetailState(
            listing: previous.listing,
            failureType: previous.failureType,
            contactState: previous.contactState,
          ),
        );
      }
      rethrow;
    }
  }

  /// Retries loading the same listing.
  Future<void> retry() => loadDetail();

  /// Opens the published WhatsApp number when present.
  Future<void> openWhatsApp() =>
      _contact(ContactChannel.whatsApp, _openWhatsApp.call);

  /// Opens the published email address when present.
  Future<void> openEmail() => _contact(ContactChannel.email, _openEmail.call);

  /// Copies the published WhatsApp number and exposes success feedback.
  Future<void> copyWhatsApp() =>
      _contact(ContactChannel.whatsApp, _copyContact.call, copying: true);

  /// Copies the published email address and exposes success feedback.
  Future<void> copyEmail() =>
      _contact(ContactChannel.email, _copyContact.call, copying: true);

  Future<void> _contact(
    ContactChannel channel,
    Future<void> Function(String) operation, {
    bool copying = false,
  }) async {
    if (isClosed ||
        state.isLoading ||
        state.failureType != null ||
        (state.contactState?.isPending ?? false)) {
      return;
    }
    final listing = state.listing;
    final value = switch (channel) {
      ContactChannel.whatsApp => listing?.contact.whatsAppNumber,
      ContactChannel.email => listing?.contact.emailAddress,
    };
    if (value == null) {
      return;
    }
    final requestId = ++_contactRequestId;
    final previous = state;
    emit(
      LessonListingDetailState(
        listing: listing,
        contactState: ContactActionState(
          channel: channel,
          value: value,
          isPending: true,
        ),
      ),
    );
    try {
      await operation(value);
      if (_isCurrentContact(requestId)) {
        _settle(
          LessonListingDetailState(
            listing: listing,
            contactState: ContactActionState(
              channel: channel,
              value: value,
              isCopied: copying,
            ),
          ),
        );
      }
    } on ExternalContactFailure catch (failure) {
      if (_isCurrentContact(requestId)) {
        _settle(
          LessonListingDetailState(
            listing: listing,
            contactState: ContactActionState(
              channel: channel,
              value: value,
              failureType: failure.type,
            ),
          ),
        );
      }
    } on Object {
      if (_isCurrentContact(requestId)) {
        _settle(
          LessonListingDetailState(
            listing: listing,
            contactState: previous.contactState,
          ),
        );
      }
      rethrow;
    }
  }

  bool _isCurrent(int requestId) => !isClosed && requestId == _requestId;

  bool _isCurrentContact(int requestId) =>
      !isClosed && requestId == _contactRequestId;

  void _settle(LessonListingDetailState next) {
    _settledState = next;
    emit(next);
  }
}
