import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_form_text_field.dart';

/// Collects explicit sharing choices independently of sign-in details.
class ListingContactFields extends StatelessWidget {
  /// Creates public-contact fields with a visible sharing explanation.
  const ListingContactFields({required this.state, super.key});

  /// The current form values and editing lock.
  final CreateLessonListingState state;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final cubit = context.read<CreateLessonListingCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(TextUtils.createListingContactNotice),
        const SizedBox(height: AppDimensions.sm),
        SwitchListTile(
          title: AppText.body(TextUtils.createListingShareWhatsApp),
          contentPadding: EdgeInsets.zero,
          value: state.shareWhatsApp,
          onChanged: state.isSubmitting
              ? null
              : (value) => cubit.setShareWhatsApp(value: value),
        ),
        if (state.shareWhatsApp) ...[
          const SizedBox(height: AppDimensions.sm),
          ListingFormTextField(
            value: state.whatsAppNumber,
            label: TextUtils.createListingWhatsAppNumber,
            hint: TextUtils.createListingWhatsAppHint,
            keyboardType: TextInputType.phone,
            enabled: !state.isSubmitting,
            onChanged: cubit.updateWhatsAppNumber,
          ),
          const SizedBox(height: AppDimensions.sm),
        ],
        SwitchListTile(
          title: AppText.body(TextUtils.createListingShareEmail),
          contentPadding: EdgeInsets.zero,
          value: state.shareEmail,
          onChanged: state.isSubmitting
              ? null
              : (value) => cubit.setShareEmail(value: value),
        ),
        if (state.shareEmail) ...[
          const SizedBox(height: AppDimensions.sm),
          ListingFormTextField(
            value: state.emailAddress,
            label: TextUtils.createListingEmailAddress,
            hint: TextUtils.createListingEmailHint,
            keyboardType: TextInputType.emailAddress,
            enabled: !state.isSubmitting,
            onChanged: cubit.updateEmailAddress,
          ),
        ],
      ],
    );
  }
}
