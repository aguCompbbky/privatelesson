import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_gradient_background.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/auth/presentation/widgets/sign_out_button.dart';

/// Temporary opening page; replaced once real features exist.
class PlaceholderPage extends StatelessWidget {
  /// Creates the placeholder page.
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final state = context.watch<AuthCubit>().state;
    return Scaffold(
      appBar: AppBar(
        title: AppText.title(TextUtils.homeTitle),
        actions: const [LanguageSwitcherButton(), SignOutButton()],
      ),
      body: AppGradientBackground(
        child: Center(
          child: Padding(
            padding: AppDimensions.screenPadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state is AuthAuthenticated) ...[
                  AppText.body(state.profile.displayName),
                  const SizedBox(height: AppDimensions.sm),
                  AppText.body(
                    switch (state.profile.role) {
                      UserRole.student => TextUtils.studentRole,
                      UserRole.teacher => TextUtils.teacherRole,
                    },
                  ),
                  const SizedBox(height: AppDimensions.md),
                ],
                AppText.body(TextUtils.homeMessage),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
