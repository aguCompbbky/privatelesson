import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/auth/presentation/widgets/login_failure_message.dart';

/// Starts Google sign-in and displays the current authentication status.
class LoginPage extends StatelessWidget {
  /// Creates the login page using the authentication cubit in the widget tree.
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(TextUtils.loginTitle, style: theme.textTheme.titleLarge),
        actions: const [LanguageSwitcherButton()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state is AuthFailureState)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.md,
                        ),
                        child: LoginFailureMessage(type: state.type),
                      ),
                    Semantics(
                      liveRegion: isLoading,
                      label: isLoading ? TextUtils.signingIn : null,
                      child: AppButton(
                        label: TextUtils.signInWithGoogle,
                        isLoading: isLoading,
                        onPressed: context.read<AuthCubit>().signInWithGoogle,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
