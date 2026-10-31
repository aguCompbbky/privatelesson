import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/app_gradient_background.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/lesson_listing_detail_content.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_failure_view.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_loading_view.dart';

/// Displays a lesson and the contact methods explicitly shared by its teacher.
class LessonListingDetailPage extends StatelessWidget {
  /// Creates detail below its listing-specific cubit provider.
  const LessonListingDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: TextUtils.backToListings,
          onPressed: () => context.go(AppRoutes.homePath),
        ),
        title: Text(TextUtils.listingDetailTitle),
        actions: const [LanguageSwitcherButton(), SignOutButton()],
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child:
              BlocBuilder<LessonListingDetailCubit, LessonListingDetailState>(
                builder: (context, state) {
                  final failure = state.failureType;
                  final listing = state.listing;
                  if (state.isLoading) {
                    return ListingLoadingView(
                      label: TextUtils.listingDetailLoading,
                    );
                  }
                  if (failure != null) {
                    return SingleChildScrollView(
                      child: ListingFailureView(
                        type: failure,
                        onRetry: context.read<LessonListingDetailCubit>().retry,
                      ),
                    );
                  }
                  if (listing == null) {
                    return const SizedBox.shrink();
                  }
                  return LessonListingDetailContent(
                    listing: listing,
                    contactState: state.contactState,
                  );
                },
              ),
        ),
      ),
    );
  }
}
