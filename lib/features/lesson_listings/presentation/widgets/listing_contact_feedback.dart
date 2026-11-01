import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_state.dart';

/// Exposes the affected contact value, a copy fallback and accessible feedback.
class ListingContactFeedback extends StatelessWidget {
  /// Creates feedback for one channel's most recent operation.
  const ListingContactFeedback({required this.feedback, super.key});

  /// The channel, published value and result of the operation.
  final ContactActionState feedback;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final cubit = context.read<LessonListingDetailCubit>();
    final failure = feedback.failureType;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (feedback.isPending)
            Semantics(
              liveRegion: true,
              child: AppText.body(TextUtils.contactOpening),
            ),
          if (failure != null) ...[
            Semantics(
              liveRegion: true,
              child: AppText.body(
                switch (failure) {
                  ExternalContactFailureType.cannotOpenExternalApp =>
                    TextUtils.contactCannotOpen,
                  ExternalContactFailureType.invalidContactValue =>
                    TextUtils.contactInvalidValue,
                  ExternalContactFailureType.clipboardFailed =>
                    TextUtils.contactClipboardFailed,
                },
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            AppText.body(feedback.value),
            const SizedBox(height: AppDimensions.sm),
            AppButton(
              variant: AppButtonVariant.secondary,
              label: TextUtils.copyContact,
              onPressed: switch (feedback.channel) {
                ContactChannel.whatsApp => cubit.copyWhatsApp,
                ContactChannel.email => cubit.copyEmail,
              },
            ),
          ],
          if (feedback.isCopied)
            Semantics(
              liveRegion: true,
              child: AppText.body(TextUtils.contactCopied),
            ),
        ],
      ),
    );
  }
}
