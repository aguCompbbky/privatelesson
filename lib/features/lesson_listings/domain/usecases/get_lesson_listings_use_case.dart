import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/lesson_listing_repository.dart';

/// Loads lesson listings using the selected search and filter criteria.
final class GetLessonListingsUseCase {
  /// Creates the use case with a provider-independent repository.
  const GetLessonListingsUseCase(this._repository);

  final LessonListingRepository _repository;

  /// Loads all listings by default and propagates repository failures.
  Future<List<LessonListing>> call([
    LessonListingFilter filter = const LessonListingFilter(),
  ]) => _repository.getListings(filter);
}
