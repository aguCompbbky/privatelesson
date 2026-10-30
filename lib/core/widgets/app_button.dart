import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';

/// Reusable primary action button.
class AppButton extends StatelessWidget {
  /// Creates a primary action button.
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  /// Text shown on the button.
  final String label;

  /// Called when the button is pressed; the button is disabled when null.
  final VoidCallback? onPressed;

  /// Whether a loading indicator replaces the label and presses are ignored.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: AppDimensions.indicatorSize,
              height: AppDimensions.indicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: AppDimensions.indicatorStrokeWidth,
              ),
            )
          : Text(label),
    );
  }
}
