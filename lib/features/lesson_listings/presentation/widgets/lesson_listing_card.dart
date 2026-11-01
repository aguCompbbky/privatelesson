import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/constants/color_constant.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/lesson_listing_facts.dart';

/// Opens a lesson's detail when its summary card is activated.
class LessonListingCard extends StatelessWidget {
  /// Creates a tappable summary of a published lesson.
  const LessonListingCard({required this.listing, super.key});

  /// The listing whose details can be opened.
  final LessonListing listing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppDimensions.xs),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        boxShadow: AppColors.cardShadow,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(
            color: AppColors.slate,
            width: AppDimensions.hairlineWidth,
          ),
        ),
        margin: EdgeInsets.zero,
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(AppDimensions.radiusCard),
            ),
            gradient: AppColors.surfaceGradient,
          ),
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            onTap: () => context.goNamed(
              AppRoutes.listingDetailName,
              pathParameters: {AppRoutes.listingIdParam: listing.id},
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppText.title(listing.subject),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      const Icon(
                        Icons.chevron_right,
                        size: AppDimensions.iconSizeMd,
                        color: AppColors.pewter,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  LessonListingFacts(listing: listing),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
