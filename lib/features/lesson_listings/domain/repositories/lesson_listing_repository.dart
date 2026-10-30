import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';

/// Provider-independent access to published lesson listings.
abstract interface class LessonListingRepository {
  /// Returns listings matching all supplied criteria.
  Future<List<LessonListing>> getListings(LessonListingFilter filter);

  /// Returns a listing or throws a domain failure if it is absent.
  Future<LessonListing> getListingById(String id);

  /// Persists validated information and returns the assigned listing.
  Future<LessonListing> createListing(NewLessonListing listing);
}
