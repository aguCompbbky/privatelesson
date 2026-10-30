import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';

/// Search and filter criteria for lesson listings.
final class LessonListingFilter {
  /// Creates criteria that include every listing by default.
  const LessonListingFilter({
    this.searchQuery = '',
    this.deliveryMode,
    this.hasCertificateOnly = false,
  });

  /// Text to match against the lesson subject or teacher name.
  final String searchQuery;

  /// The required delivery mode, or null for all modes.
  final LessonDeliveryMode? deliveryMode;

  /// Whether to include only teachers who declare a certificate.
  final bool hasCertificateOnly;

  /// Whether any criterion narrows the listing results.
  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      deliveryMode != null ||
      hasCertificateOnly;
}
