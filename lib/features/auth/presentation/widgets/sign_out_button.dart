import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';

/// Shared sign-out action for session-aware pages.
class SignOutButton extends StatelessWidget {
  /// Creates an action backed by the current authentication cubit.
  const SignOutButton({this.enabled = true, super.key});

  /// Whether the surrounding page allows signing out during its operation.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final state = context.watch<AuthCubit>().state;
    final isBusy =
        state is AuthLoading ||
        (state is AuthProfileIncomplete && state.isSubmitting);
    return IconButton(
      tooltip: TextUtils.signOut,
      icon: const Icon(Icons.logout),
      onPressed: isBusy || !enabled ? null : context.read<AuthCubit>().signOut,
    );
  }
}
