import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_user_header.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listings_filters.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listings_results.dart';

/// Lists lessons with searchable criteria and typed request feedback.
class LessonListingsPage extends StatelessWidget {
  /// Creates the listing page below its cubit provider.
  const LessonListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(TextUtils.listingsTitle),
        actions: const [LanguageSwitcherButton(), SignOutButton()],
      ),
      body: SafeArea(
        child: BlocBuilder<LessonListingsCubit, LessonListingsState>(
          builder: (context, state) => CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: ListingUserHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: ListingsFilters(filter: state.filter),
                ),
              ),
              ListingsResults(state: state),
            ],
          ),
        ),
      ),
    );
  }
}
