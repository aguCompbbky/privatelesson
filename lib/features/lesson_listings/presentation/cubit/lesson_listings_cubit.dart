import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/get_lesson_listings_use_case.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_state.dart';

/// Loads search results through the domain, accepting only the latest request.
final class LessonListingsCubit extends Cubit<LessonListingsState> {
  /// Creates a cubit with its provider-independent query use case.
  LessonListingsCubit({
    required GetLessonListingsUseCase getLessonListingsUseCase,
  }) : _getLessonListingsUseCase = getLessonListingsUseCase,
       super(LessonListingsState()) {
    _settledState = state;
  }

  final GetLessonListingsUseCase _getLessonListingsUseCase;
  late LessonListingsState _settledState;
  int _requestId = 0;

  /// Loads listings using the current criteria.
  Future<void> loadListings() => _load(state.filter);

  /// Updates the query while preserving the other criteria.
  Future<void> updateSearchQuery(String query) => _load(
    LessonListingFilter(
      searchQuery: query,
      deliveryMode: state.filter.deliveryMode,
      hasCertificateOnly: state.filter.hasCertificateOnly,
    ),
  );

  /// Selects a delivery mode, or all modes when null.
  Future<void> selectDeliveryMode(LessonDeliveryMode? deliveryMode) => _load(
    LessonListingFilter(
      searchQuery: state.filter.searchQuery,
      deliveryMode: deliveryMode,
      hasCertificateOnly: state.filter.hasCertificateOnly,
    ),
  );

  /// Includes only listings with declared certificates when enabled.
  Future<void> setCertificateOnly({required bool value}) => _load(
    LessonListingFilter(
      searchQuery: state.filter.searchQuery,
      deliveryMode: state.filter.deliveryMode,
      hasCertificateOnly: value,
    ),
  );

  /// Clears every criterion, including the search input.
  Future<void> clearFilters() => _load(const LessonListingFilter());

  /// Retries the current criteria after a controlled failure.
  Future<void> retry() => loadListings();

  Future<void> _load(LessonListingFilter filter) async {
    if (isClosed) {
      return;
    }
    final requestId = ++_requestId;
    // Roll back to a settled snapshot even when superseding a pending request.
    final previous = _settledState;
    emit(
      LessonListingsState(
        filter: filter,
        listings: previous.listings,
        isLoading: true,
      ),
    );
    try {
      final listings = await _getLessonListingsUseCase(filter);
      if (_isCurrent(requestId)) {
        _settle(LessonListingsState(filter: filter, listings: listings));
      }
    } on LessonListingFailure catch (failure) {
      if (_isCurrent(requestId)) {
        _settle(
          LessonListingsState(
            filter: filter,
            listings: previous.listings,
            failureType: failure.type,
          ),
        );
      }
    } on Object {
      if (_isCurrent(requestId)) {
        _settle(
          LessonListingsState(
            filter: previous.filter,
            listings: previous.listings,
            failureType: previous.failureType,
          ),
        );
      }
      rethrow;
    }
  }

  bool _isCurrent(int requestId) => !isClosed && requestId == _requestId;

  void _settle(LessonListingsState next) {
    _settledState = next;
    emit(next);
  }
}
