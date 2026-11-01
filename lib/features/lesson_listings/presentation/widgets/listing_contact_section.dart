import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_contact_feedback.dart';

/// Offers only the contact methods the teacher explicitly shared.
class ListingContactSection extends StatelessWidget {
  /// Creates external contact controls and their fallback feedback.
  const ListingContactSection({
    required this.contact,
    required this.contactState,
    super.key,
  });

  /// The teacher's published contact methods.
  final TeacherContactInfo contact;

  /// Feedback and pending status for the latest contact action.
  final ContactActionState? contactState;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final cubit = context.read<LessonListingDetailCubit>();
    final feedback = contactState;
    final pending = feedback?.isPending ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subhead(TextUtils.contactTeacher),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: [
            if (contact.hasWhatsApp)
              AppButton(
                label: TextUtils.contactWhatsApp,
                onPressed: pending ? null : cubit.openWhatsApp,
              ),
            if (contact.hasEmail)
              AppButton(
                label: TextUtils.contactEmail,
                onPressed: pending ? null : cubit.openEmail,
              ),
          ],
        ),
        if (feedback != null) ListingContactFeedback(feedback: feedback),
      ],
    );
  }
}
