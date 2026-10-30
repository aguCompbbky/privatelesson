import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';

/// Central color definitions.
abstract final class AppColors {
  /// Seed color used to generate the color scheme.
  static const Color seed = Color(0xFF1565C0);
}

/// Central application theme.
abstract final class AppTheme {
  /// Light theme of the application.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.seed);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: AppDimensions.focusedBorderWidth,
          ),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      ),
    );
  }
}
