import 'package:privatelesson/features/lesson_listings/data/dtos/lesson_listing_dto.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';

/// The replaceable storage contract for lesson listing payloads.
abstract interface class LessonListingDataSource {
  /// Fetches payloads satisfying every supplied criterion.
  Future<List<LessonListingDto>> fetchListings(LessonListingFilter filter);

  /// Fetches a payload by its identifier or reports a not-found exception.
  Future<LessonListingDto> fetchListingById(String id);

  /// Stores validated listing information and assigns its identifier.
  Future<LessonListingDto> insertListing(NewLessonListing listing);
}
