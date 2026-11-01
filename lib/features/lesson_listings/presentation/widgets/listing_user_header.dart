import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';

/// Shows the authenticated user's saved display name and role.
class ListingUserHeader extends StatelessWidget {
  /// Creates a header observing authentication changes.
  const ListingUserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final state = context.watch<AuthCubit>().state;
    if (state is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: AppDimensions.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.headline(state.profile.displayName),
          const SizedBox(height: AppDimensions.xs),
          AppText.label(
            switch (state.profile.role) {
              UserRole.student => TextUtils.studentRole,
              UserRole.teacher => TextUtils.teacherRole,
            },
          ),
          if (state.profile.role == UserRole.teacher) ...[
            const SizedBox(height: AppDimensions.sm),
            AppButton(
              label: TextUtils.createListingTitle,
              onPressed: () => context.go(AppRoutes.createListingPath),
            ),
          ],
        ],
      ),
    );
  }
}
