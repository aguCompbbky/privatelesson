import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/lesson_listing_card.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_failure_view.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/listing_loading_view.dart';

/// Builds a scrollable result sliver for every listing request state.
class ListingsResults extends StatelessWidget {
  /// Creates results for the latest cubit snapshot.
  const ListingsResults({required this.state, super.key});

  /// The current request and result snapshot.
  final LessonListingsState state;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final failure = state.failureType;
    if (state.isLoading) {
      return SliverToBoxAdapter(
        child: ListingLoadingView(label: TextUtils.listingsLoading),
      );
    }
    if (failure != null) {
      return SliverToBoxAdapter(
        child: ListingFailureView(
          type: failure,
          onRetry: context.read<LessonListingsCubit>().retry,
        ),
      );
    }
    if (state.listings.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: AppDimensions.screenPadding(context),
          child: AppText.body(TextUtils.noListings),
        ),
      );
    }
    return SliverPadding(
      padding: AppDimensions.screenPadding(context),
      sliver: SliverList.builder(
        itemCount: state.listings.length,
        itemBuilder: (context, index) =>
            LessonListingCard(listing: state.listings[index]),
      ),
    );
  }
}
