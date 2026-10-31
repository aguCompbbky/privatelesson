import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:privatelesson/features/auth/presentation/widgets/auth_page_body.dart';
import 'package:privatelesson/features/auth/presentation/widgets/login_credentials_form.dart';

/// Offers email and Google sign-in through the shared authentication cubit.
class LoginPage extends StatelessWidget {
  /// Creates the login page using the authentication cubit in the widget tree.
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(TextUtils.loginTitle),
        actions: const [LanguageSwitcherButton()],
      ),
      body: const AuthPageBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthBrandHeader(),
            SizedBox(height: AppDimensions.lg),
            LoginCredentialsForm(),
          ],
        ),
      ),
    );
  }
}
