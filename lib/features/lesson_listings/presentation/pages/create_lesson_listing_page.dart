import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/create_lesson_listing_form.dart';

/// Allows an authorized teacher to publish a lesson with explicit contacts.
class CreateLessonListingPage extends StatelessWidget {
  /// Creates the page below its route-provided creation cubit.
  const CreateLessonListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return BlocListener<CreateLessonListingCubit, CreateLessonListingState>(
      listenWhen: (previous, current) =>
          previous.createdListing == null && current.createdListing != null,
      listener: (context, state) => context.go(AppRoutes.homePath),
      child: BlocBuilder<CreateLessonListingCubit, CreateLessonListingState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: TextUtils.backToListings,
              onPressed: state.isSubmitting
                  ? null
                  : () => context.go(AppRoutes.homePath),
            ),
            title: Text(TextUtils.createListingTitle),
            actions: [
              const LanguageSwitcherButton(),
              SignOutButton(enabled: !state.isSubmitting),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: CreateLessonListingForm(state: state),
            ),
          ),
        ),
      ),
    );
  }
}
