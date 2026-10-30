import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';

/// Search criteria and an immutable snapshot of the listing results.
final class LessonListingsState {
  /// Creates a new state, protecting results from external mutations.
  LessonListingsState({
    this.filter = const LessonListingFilter(),
    List<LessonListing> listings = const [],
    this.isLoading = false,
    this.failureType,
  }) : listings = List<LessonListing>.unmodifiable(listings);

  /// The currently selected search and filter criteria.
  final LessonListingFilter filter;

  /// The last loaded results.
  final List<LessonListing> listings;

  /// Whether the current request is pending.
  final bool isLoading;

  /// The controlled failure from the current request, if any.
  final LessonListingFailureType? failureType;
}
