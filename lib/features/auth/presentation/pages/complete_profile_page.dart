import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_gradient_background.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/auth/presentation/widgets/complete_profile_form.dart';
import 'package:privatelesson/features/auth/presentation/widgets/sign_out_button.dart';

/// Collects the role and name required before opening the home page.
class CompleteProfilePage extends StatelessWidget {
  /// Creates the profile page using the current authentication cubit.
  const CompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: AppText.title(TextUtils.completeProfileTitle),
        actions: const [LanguageSwitcherButton(), SignOutButton()],
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppDimensions.screenPadding(context),
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) => state is AuthProfileIncomplete
                    ? CompleteProfileForm(
                        key: ValueKey(state.session.userId),
                        state: state,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
