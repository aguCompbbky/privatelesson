import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/constants/color_constant.dart';

/// Shared softly elevated surface for authentication forms.
class AuthFormCard extends StatelessWidget {
  /// Creates a card around its form content.
  const AuthFormCard({required this.child, super.key});

  /// Form content managed by the authentication cubit.
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: AppColors.surfaceGradient,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      border: Border.all(
        color: AppColors.slate,
        width: AppDimensions.hairlineWidth,
      ),
      boxShadow: AppColors.cardShadow,
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: child,
    ),
  );
}
