import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/constants/color_constant.dart';
import 'package:privatelesson/core/widgets/app_text.dart';

/// Visual emphasis of a shared action button.
enum AppButtonVariant {
  /// Luminous fill for the main action.
  primary,

  /// Dark fill for supporting actions.
  secondary,
}

/// Reusable oval action with a gradient and opacity-based press feedback.
class AppButton extends StatelessWidget {
  /// Creates an action button with primary emphasis by default.
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.leading,
    super.key,
  });

  /// Text shown on the button.
  final String label;

  /// Called when the button is pressed; the button is disabled when null.
  final VoidCallback? onPressed;

  /// Whether a loading indicator replaces the label and presses are ignored.
  final bool isLoading;

  /// The button's visual emphasis when enabled.
  final AppButtonVariant variant;

  /// Optional content displayed before the label when not loading.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;
    final isPrimary = variant == AppButtonVariant.primary;
    final foreground = !isEnabled
        ? AppColors.pewter
        : isPrimary
        ? AppColors.obsidian
        : AppColors.platinum;
    final gradient = !isEnabled
        ? AppColors.disabledButtonGradient
        : isPrimary
        ? AppColors.primaryButtonGradient
        : AppColors.secondaryButtonGradient;
    final borderRadius = BorderRadius.circular(AppDimensions.radiusPill);
    final leadingWidget = leading;

    return Semantics(
      enabled: isEnabled,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.buttonHeight,
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          pressedOpacity: AppDimensions.pressedOpacity,
          borderRadius: borderRadius,
          foregroundColor: foreground,
          disabledColor: AppColors.transparent,
          focusColor: AppColors.silver,
          onPressed: isLoading ? null : onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: borderRadius,
              border: Border.all(
                color: isEnabled && isPrimary
                    ? AppColors.silver
                    : AppColors.slate,
                width: AppDimensions.hairlineWidth,
              ),
              boxShadow: isEnabled ? AppColors.buttonShadow : null,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimensions.buttonHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: AppDimensions.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: AppDimensions.indicatorSize,
                        height: AppDimensions.indicatorSize,
                        child: CircularProgressIndicator(
                          color: foreground,
                          strokeWidth: AppDimensions.indicatorStrokeWidth,
                        ),
                      )
                    else ...[
                      if (leadingWidget != null) ...[
                        leadingWidget,
                        const SizedBox(width: AppDimensions.sm),
                      ],
                      Flexible(
                        child: AppText.label(
                          label,
                          textAlign: TextAlign.center,
                          color: foreground,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
