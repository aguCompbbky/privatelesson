import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';

/// The teacher's selected external communication channel.
enum ContactChannel {
  /// The published WhatsApp number.
  whatsApp,

  /// The published contact email.
  email,
}

/// Feedback for an external contact operation and its exact published value.
final class ContactActionState {
  /// Creates pending, failed or successful contact feedback.
  const ContactActionState({
    required this.channel,
    required this.value,
    this.isPending = false,
    this.failureType,
    this.isCopied = false,
  });

  /// The channel to which this feedback belongs.
  final ContactChannel channel;

  /// The published value available for manual contact or copying.
  final String value;

  /// Whether an external contact operation is pending.
  final bool isPending;

  /// The domain failure requiring user feedback, if any.
  final ExternalContactFailureType? failureType;

  /// Whether the value was successfully copied to the clipboard.
  final bool isCopied;
}

/// Listing detail, loading failure and external contact feedback.
final class LessonListingDetailState {
  /// Creates a new detail snapshot.
  const LessonListingDetailState({
    this.listing,
    this.isLoading = false,
    this.failureType,
    this.contactState,
  });

  /// The last loaded listing, when available.
  final LessonListing? listing;

  /// Whether a detail request is pending.
  final bool isLoading;

  /// The controlled detail loading failure, if any.
  final LessonListingFailureType? failureType;

  /// Feedback for the most recent external contact action.
  final ContactActionState? contactState;
}
