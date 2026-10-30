import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/lesson_listing_facts.dart';

/// Opens a lesson's detail when its summary card is activated.
class LessonListingCard extends StatelessWidget {
  /// Creates a tappable summary of a published lesson.
  const LessonListingCard({required this.listing, super.key});

  /// The listing whose details can be opened.
  final LessonListing listing;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: () => context.goNamed(
        AppRoutes.listingDetailName,
        pathParameters: {AppRoutes.listingIdParam: listing.id},
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listing.subject,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.sm),
            LessonListingFacts(listing: listing),
          ],
        ),
      ),
    ),
  );
}
