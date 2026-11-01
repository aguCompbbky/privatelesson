import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_control_label.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_state.dart';

/// Selects one delivery mode, wrapping choices on narrow screens.
class ListingDeliveryModeField extends StatelessWidget {
  /// Creates the mode selector from the cubit's current selection.
  const ListingDeliveryModeField({required this.state, super.key});

  /// The current selection and editing lock.
  final CreateLessonListingState state;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final cubit = context.read<CreateLessonListingCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subhead(TextUtils.deliveryModeLabel),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.xs,
          children: [
            for (final mode in LessonDeliveryMode.values)
              ChoiceChip(
                label: AppControlLabel(
                  switch (mode) {
                    LessonDeliveryMode.inPerson => TextUtils.inPersonLesson,
                    LessonDeliveryMode.online => TextUtils.onlineLesson,
                    LessonDeliveryMode.recordedVideo =>
                      TextUtils.recordedVideoLesson,
                  },
                ),
                selected: state.deliveryMode == mode,
                onSelected: state.isSubmitting
                    ? null
                    : (_) => cubit.selectDeliveryMode(mode),
              ),
          ],
        ),
      ],
    );
  }
}
