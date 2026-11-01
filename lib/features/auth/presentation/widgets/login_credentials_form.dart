import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text_field.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:privatelesson/features/auth/presentation/widgets/login_failure_message.dart';

/// Owns credential controllers while the cubit manages submission and failures.
class LoginCredentialsForm extends StatefulWidget {
  /// Creates the email and Google authentication form.
  const LoginCredentialsForm({super.key});

  @override
  State<LoginCredentialsForm> createState() => _LoginCredentialsFormState();
}

class _LoginCredentialsFormState extends State<LoginCredentialsForm> {
  // Test credentials used during verification; empty in production.
  final _email = TextEditingController(text: 'mustafa@gmail.com');
  final _password = TextEditingController(text: '123456');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final cubit = context.read<AuthCubit>();
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return AuthFormCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state is AuthFailureState) ...[
                LoginFailureMessage(type: state.type),
                const SizedBox(height: AppDimensions.md),
              ],
              AppTextField(
                label: TextUtils.emailLabel,
                hint: TextUtils.emailHint,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                label: TextUtils.passwordLabel,
                hint: TextUtils.passwordHint,
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.done,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimensions.lg),
              Semantics(
                liveRegion: isLoading,
                label: isLoading ? TextUtils.signingIn : null,
                child: AppButton(
                  label: TextUtils.signInWithEmail,
                  isLoading: isLoading,
                  onPressed: () => cubit.signInWithEmail(
                    email: _email.text,
                    password: _password.text,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              AppButton(
                label: TextUtils.signInWithGoogle,
                variant: AppButtonVariant.secondary,
                onPressed: isLoading ? null : cubit.signInWithGoogle,
              ),
              const SizedBox(height: AppDimensions.sm),
              AppButton(
                label: TextUtils.goToRegister,
                variant: AppButtonVariant.secondary,
                onPressed: isLoading
                    ? null
                    : () {
                        cubit.clearFailure();
                        context.go(AppRoutes.registerPath);
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
