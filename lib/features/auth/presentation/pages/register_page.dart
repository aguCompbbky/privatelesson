import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/auth/presentation/widgets/auth_page_body.dart';
import 'package:privatelesson/features/auth/presentation/widgets/register_form.dart';

/// Registers an email identity before the shared role selection flow.
class RegisterPage extends StatelessWidget {
  /// Creates the registration page with the current authentication cubit.
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final isLoading = context.watch<AuthCubit>().state is AuthLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(TextUtils.registerTitle),
        leading: IconButton(
          tooltip: TextUtils.backToLogin,
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading
              ? null
              : () {
                  context.read<AuthCubit>().clearFailure();
                  context.go(AppRoutes.loginPath);
                },
        ),
        actions: const [LanguageSwitcherButton()],
      ),
      body: const AuthPageBody(child: RegisterForm()),
    );
  }
}
