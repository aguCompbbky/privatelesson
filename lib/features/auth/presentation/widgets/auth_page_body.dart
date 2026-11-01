import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/widgets/app_gradient_background.dart';

/// Responsive, scrollable authentication content over the shared background.
class AuthPageBody extends StatelessWidget {
  /// Creates an authentication body that also accommodates the keyboard.
  const AuthPageBody({required this.child, super.key});

  /// Content constrained to the shared authentication form width.
  final Widget child;

  @override
  Widget build(BuildContext context) => AppGradientBackground(
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: AppDimensions.screenPadding(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.authFormMaxWidth,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}
