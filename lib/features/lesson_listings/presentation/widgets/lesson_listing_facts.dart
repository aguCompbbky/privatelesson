import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/constants/color_constant.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';

/// Presents a teacher's delivery mode and certificate declaration.
class LessonListingFacts extends StatelessWidget {
  /// Creates facts shared by listing cards and the detail view.
  const LessonListingFacts({required this.listing, super.key});

  /// The teacher-provided listing information.
  final LessonListing listing;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_outline,
              size: AppDimensions.iconSizeSm,
              color: AppColors.silver,
            ),
            const SizedBox(width: AppDimensions.xs),
            Expanded(
              child: AppText.body(
                listing.teacherName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.md,
          runSpacing: AppDimensions.xs,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  switch (listing.deliveryMode) {
                    LessonDeliveryMode.inPerson => Icons.place_outlined,
                    LessonDeliveryMode.online => Icons.computer_outlined,
                    LessonDeliveryMode.recordedVideo =>
                      Icons.video_library_outlined,
                  },
                  size: AppDimensions.iconSizeXs,
                  color: AppColors.pewter,
                ),
                const SizedBox(width: AppDimensions.xs),
                AppText.caption(
                  switch (listing.deliveryMode) {
                    LessonDeliveryMode.inPerson => TextUtils.inPersonLesson,
                    LessonDeliveryMode.online => TextUtils.onlineLesson,
                    LessonDeliveryMode.recordedVideo =>
                      TextUtils.recordedVideoLesson,
                  },
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  listing.certification.hasCertificate
                      ? Icons.verified_outlined
                      : Icons.remove_circle_outline,
                  size: AppDimensions.iconSizeXs,
                  color: AppColors.pewter,
                ),
                const SizedBox(width: AppDimensions.xs),
                AppText.caption(
                  listing.certification.hasCertificate
                      ? TextUtils.certificateAvailable
                      : TextUtils.certificateNotProvided,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
