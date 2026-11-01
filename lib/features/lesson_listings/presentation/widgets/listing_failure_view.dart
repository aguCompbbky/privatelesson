import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';

/// Displays a localized domain failure and a retry action.
class ListingFailureView extends StatelessWidget {
  /// Creates failure feedback without depending on a data provider.
  const ListingFailureView({
    required this.type,
    required this.onRetry,
    super.key,
  });

  /// The controlled reason for the failed request.
  final LessonListingFailureType type;

  /// Retries the request through the owning cubit.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Padding(
      padding: AppDimensions.screenPadding(context),
      child: Column(
        children: [
          Semantics(
            liveRegion: true,
            child: AppText.body(
              switch (type) {
                LessonListingFailureType.notFound => TextUtils.listingNotFound,
                LessonListingFailureType.connection =>
                  TextUtils.listingConnectionError,
                LessonListingFailureType.storage =>
                  TextUtils.listingStorageError,
                _ => TextUtils.listingLoadError,
              },
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          AppButton(label: TextUtils.retryListings, onPressed: onRetry),
        ],
      ),
    );
  }
}
