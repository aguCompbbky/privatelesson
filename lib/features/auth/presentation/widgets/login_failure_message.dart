import 'package:flutter/material.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';

/// Displays a translated message for each authentication failure category.
class LoginFailureMessage extends StatelessWidget {
  /// Creates a message for the failure supplied by the authentication cubit.
  const LoginFailureMessage({required this.type, super.key});

  /// The provider-independent failure classification to explain.
  final AuthFailureType type;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final message = switch (type) {
      AuthFailureType.invalidDisplayName => TextUtils.authInvalidDisplayName,
      AuthFailureType.invalidEmail => TextUtils.authInvalidEmail,
      AuthFailureType.weakPassword => TextUtils.authWeakPassword,
      AuthFailureType.passwordMismatch => TextUtils.authPasswordMismatch,
      AuthFailureType.invalidCredentials => TextUtils.authInvalidCredentials,
      AuthFailureType.emailAlreadyInUse => TextUtils.authEmailAlreadyInUse,
      AuthFailureType.cancelled => TextUtils.signInCancelled,
      AuthFailureType.connection => TextUtils.signInConnectionError,
      AuthFailureType.authentication => TextUtils.signInAuthenticationError,
      AuthFailureType.profileLoading => TextUtils.signInProfileLoadingError,
    };

    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
