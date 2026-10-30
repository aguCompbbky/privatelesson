import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/lesson_listing_repository.dart';

/// Loads a listing after validating its requested identifier.
final class GetLessonListingDetailUseCase {
  /// Creates the use case with a provider-independent repository.
  const GetLessonListingDetailUseCase(this._repository);

  final LessonListingRepository _repository;

  /// Trims the identifier and treats blank identifiers as absent listings.
  Future<LessonListing> call(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw const LessonListingFailure(LessonListingFailureType.notFound);
    }
    return _repository.getListingById(normalizedId);
  }
}
