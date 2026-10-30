import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source_exception.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/lesson_listing_repository.dart';

/// Converts listing payloads and controlled storage errors into domain types.
final class LessonListingRepositoryImpl implements LessonListingRepository {
  /// Creates a repository for any adapter implementing the source contract.
  const LessonListingRepositoryImpl(this._dataSource);

  final LessonListingDataSource _dataSource;

  /// Converts all matching payloads and maps source or format failures.
  @override
  Future<List<LessonListing>> getListings(LessonListingFilter filter) =>
      _mapFailures(() async {
        final listings = await _dataSource.fetchListings(filter);
        return List<LessonListing>.unmodifiable(
          listings.map((listing) => listing.toEntity()),
        );
      });

  /// Fetches and converts the requested listing, preserving not-found errors.
  @override
  Future<LessonListing> getListingById(String id) => _mapFailures(() async {
    final listing = await _dataSource.fetchListingById(id);
    return listing.toEntity();
  });

  /// Stores validated information and converts the resulting payload.
  @override
  Future<LessonListing> createListing(NewLessonListing listing) =>
      _mapFailures(() async {
        final stored = await _dataSource.insertListing(listing);
        return stored.toEntity();
      });

  /// Maps malformed payloads to storage failures; unrelated errors propagate.
  Future<T> _mapFailures<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on LessonListingDataSourceException catch (exception) {
      throw LessonListingFailure(
        switch (exception.type) {
          LessonListingDataSourceError.connection =>
            LessonListingFailureType.connection,
          LessonListingDataSourceError.notFound =>
            LessonListingFailureType.notFound,
          LessonListingDataSourceError.storage =>
            LessonListingFailureType.storage,
        },
      );
    } on FormatException {
      throw const LessonListingFailure(LessonListingFailureType.storage);
    }
  }
}
