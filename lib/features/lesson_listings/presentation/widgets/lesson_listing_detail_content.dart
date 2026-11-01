import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/lesson_listing_facts.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_contact_section.dart';

/// Presents the teacher's full description, declaration and contact choices.
class LessonListingDetailContent extends StatelessWidget {
  /// Creates a scrollable detail view with current contact feedback.
  const LessonListingDetailContent({
    required this.listing,
    required this.contactState,
    super.key,
  });

  /// The loaded lesson and its teacher-provided details.
  final LessonListing listing;

  /// The most recent contact action feedback.
  final ContactActionState? contactState;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final certificate = listing.certification;
    final description = certificate.certificateDescription;
    return SingleChildScrollView(
      padding: AppDimensions.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.headline(listing.subject),
          const SizedBox(height: AppDimensions.md),
          LessonListingFacts(listing: listing),
          if (certificate.hasCertificate && description != null) ...[
            const SizedBox(height: AppDimensions.sm),
            AppText.body(description),
          ],
          const SizedBox(height: AppDimensions.lg),
          AppText.subhead(TextUtils.lessonDescription),
          const SizedBox(height: AppDimensions.sm),
          AppText.body(listing.description),
          const SizedBox(height: AppDimensions.lg),
          ListingContactSection(
            contact: listing.contact,
            contactState: contactState,
          ),
        ],
      ),
    );
  }
}
