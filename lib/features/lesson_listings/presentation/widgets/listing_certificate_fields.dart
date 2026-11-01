import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_form_text_field.dart';

/// Collects the teacher's certificate declaration and its description.
class ListingCertificateFields extends StatelessWidget {
  /// Creates certificate controls without implying platform endorsement.
  const ListingCertificateFields({required this.state, super.key});

  /// The current form values and editing lock.
  final CreateLessonListingState state;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final cubit = context.read<CreateLessonListingCubit>();
    return Column(
      children: [
        SwitchListTile(
          title: AppText.body(TextUtils.createListingHasCertificate),
          contentPadding: EdgeInsets.zero,
          value: state.hasCertificate,
          onChanged: state.isSubmitting
              ? null
              : (value) => cubit.setHasCertificate(value: value),
        ),
        if (state.hasCertificate) ...[
          const SizedBox(height: AppDimensions.sm),
          ListingFormTextField(
            value: state.certificateDescription,
            label: TextUtils.createListingCertificateDescription,
            enabled: !state.isSubmitting,
            onChanged: cubit.updateCertificateDescription,
          ),
        ],
      ],
    );
  }
}
