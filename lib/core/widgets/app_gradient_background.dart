import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/color_constant.dart';

/// Fills the available page body with the shared monochrome gradient.
class AppGradientBackground extends StatelessWidget {
  /// Creates a full-size background behind [child].
  const AppGradientBackground({required this.child, super.key});

  /// Page content displayed above the gradient.
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: child,
    ),
  );
}
