/// Controlled errors reported by a listing data source.
enum LessonListingDataSourceError {
  /// The provider cannot be reached.
  connection,

  /// The requested listing does not exist.
  notFound,

  /// The provider could not complete a storage operation.
  storage,
}

/// A data-layer exception to be translated at the repository boundary.
final class LessonListingDataSourceException implements Exception {
  /// Creates a source exception with its controlled reason.
  const LessonListingDataSourceException(this.type);

  /// The reason the data source operation failed.
  final LessonListingDataSourceError type;
}
