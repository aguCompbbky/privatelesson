import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/create_listing_failure_message.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_certificate_fields.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_contact_fields.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_delivery_mode_field.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_lesson_fields.dart';

/// Arranges independently editable sections and the publication action.
class CreateLessonListingForm extends StatelessWidget {
  /// Creates a form whose values are entirely owned by its cubit.
  const CreateLessonListingForm({required this.state, super.key});

  /// The current form snapshot.
  final CreateLessonListingState state;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final auth = context.watch<AuthCubit>().state;
    final failure = state.failureType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListingLessonFields(state: state),
        const SizedBox(height: AppDimensions.md),
        ListingDeliveryModeField(state: state),
        const SizedBox(height: AppDimensions.md),
        ListingCertificateFields(state: state),
        const SizedBox(height: AppDimensions.md),
        ListingContactFields(state: state),
        const SizedBox(height: AppDimensions.md),
        if (failure != null) ...[
          CreateListingFailureMessage(type: failure),
          const SizedBox(height: AppDimensions.md),
        ],
        Semantics(
          liveRegion: state.isSubmitting,
          label: state.isSubmitting ? TextUtils.createListingSubmitting : null,
          child: AppButton(
            label: TextUtils.createListingSubmit,
            isLoading: state.isSubmitting,
            onPressed: auth is AuthAuthenticated
                ? () => context.read<CreateLessonListingCubit>().submit(
                    auth.profile,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
