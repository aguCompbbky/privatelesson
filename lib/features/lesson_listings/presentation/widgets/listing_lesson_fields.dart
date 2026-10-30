import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_form_text_field.dart';

/// Edits the subject and multiline lesson description.
class ListingLessonFields extends StatelessWidget {
  /// Creates lesson text controls from the cubit's current snapshot.
  const ListingLessonFields({required this.state, super.key});

  /// The current form values and editing lock.
  final CreateLessonListingState state;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final cubit = context.read<CreateLessonListingCubit>();
    return Column(
      children: [
        ListingFormTextField(
          value: state.subject,
          label: TextUtils.createListingSubject,
          enabled: !state.isSubmitting,
          onChanged: cubit.updateSubject,
        ),
        const SizedBox(height: AppDimensions.md),
        ListingFormTextField(
          value: state.description,
          label: TextUtils.lessonDescription,
          enabled: !state.isSubmitting,
          keyboardType: TextInputType.multiline,
          maxLines: AppConstants.lessonDescriptionLines,
          onChanged: cubit.updateDescription,
        ),
      ],
    );
  }
}
