import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/constants/color_constant.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_control_label.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/core/widgets/app_text_field.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_cubit.dart';

/// Edits criteria while owning only the search controller's lifecycle.
class ListingsFilters extends StatefulWidget {
  /// Creates filter controls synchronized with the cubit's criteria.
  const ListingsFilters({required this.filter, super.key});

  /// The current criteria, including the visible search query.
  final LessonListingFilter filter;

  @override
  State<ListingsFilters> createState() => _ListingsFiltersState();
}

class _ListingsFiltersState extends State<ListingsFilters> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filter.searchQuery);
  }

  @override
  void didUpdateWidget(ListingsFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.filter.searchQuery) {
      _searchController.text = widget.filter.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final cubit = context.read<LessonListingsCubit>();
    final filter = widget.filter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, child) => AppTextField(
            label: TextUtils.listingsSearch,
            controller: _searchController,
            textInputAction: TextInputAction.search,
            prefixIcon: const Icon(
              Icons.search,
              size: AppDimensions.iconSizeMd,
              color: AppColors.silver,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      size: AppDimensions.iconSizeSm,
                      color: AppColors.silver,
                    ),
                    tooltip: TextUtils.clearListingFilters,
                    onPressed: () {
                      _searchController.clear();
                      unawaited(cubit.updateSearchQuery(''));
                    },
                  )
                : null,
            onChanged: cubit.updateSearchQuery,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        AppText.subhead(TextUtils.deliveryModeLabel),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.xs,
          children: [
            ChoiceChip(
              label: AppControlLabel(TextUtils.allDeliveryModes),
              selected: filter.deliveryMode == null,
              onSelected: (_) => cubit.selectDeliveryMode(null),
            ),
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
                selected: filter.deliveryMode == mode,
                onSelected: (_) => cubit.selectDeliveryMode(mode),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        FilterChip(
          label: AppControlLabel(TextUtils.certificateOnly),
          selected: filter.hasCertificateOnly,
          onSelected: (value) => cubit.setCertificateOnly(value: value),
        ),
        if (filter.hasActiveFilters) ...[
          const SizedBox(height: AppDimensions.sm),
          AppText.caption(TextUtils.activeListingFilters),
          const SizedBox(height: AppDimensions.sm),
          AppButton(
            variant: AppButtonVariant.secondary,
            label: TextUtils.clearListingFilters,
            onPressed: cubit.clearFilters,
          ),
        ],
      ],
    );
  }
}
