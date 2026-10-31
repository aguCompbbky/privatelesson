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

/// Owns registration input controllers without owning application state.
class RegisterForm extends StatefulWidget {
  /// Creates the registration form backed by the shared authentication cubit.
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
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
                label: TextUtils.displayNameLabel,
                hint: TextUtils.displayNameHint,
                controller: _name,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                label: TextUtils.emailLabel,
                hint: TextUtils.emailHint,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                label: TextUtils.passwordLabel,
                hint: TextUtils.passwordHint,
                controller: _password,
                obscureText: true,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.md),
              AppTextField(
                label: TextUtils.confirmPasswordLabel,
                hint: TextUtils.confirmPasswordHint,
                controller: _confirmation,
                obscureText: true,
                enabled: !isLoading,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppDimensions.lg),
              Semantics(
                liveRegion: isLoading,
                label: isLoading ? TextUtils.registering : null,
                child: AppButton(
                  label: TextUtils.registerAction,
                  isLoading: isLoading,
                  onPressed: () => cubit.registerWithEmail(
                    displayName: _name.text,
                    email: _email.text,
                    password: _password.text,
                    confirmPassword: _confirmation.text,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              AppButton(
                label: TextUtils.backToLogin,
                variant: AppButtonVariant.secondary,
                onPressed: isLoading
                    ? null
                    : () {
                        cubit.clearFailure();
                        context.go(AppRoutes.loginPath);
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
