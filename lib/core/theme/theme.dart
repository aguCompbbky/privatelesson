import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/constants/color_constant.dart';

/// Central application theme.
abstract final class AppTheme {
  /// Compatibility alias for callers using the original theme name.
  static ThemeData get light => monochrome;

  /// Dark monochrome surfaces, crisp typography and restrained interactions.
  static ThemeData get monochrome {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.white,
      onPrimary: AppColors.obsidian,
      primaryContainer: AppColors.graphite,
      onPrimaryContainer: AppColors.platinum,
      primaryFixed: AppColors.platinum,
      primaryFixedDim: AppColors.silver,
      onPrimaryFixed: AppColors.obsidian,
      onPrimaryFixedVariant: AppColors.charcoal,
      secondary: AppColors.silver,
      onSecondary: AppColors.obsidian,
      secondaryContainer: AppColors.graphite,
      onSecondaryContainer: AppColors.platinum,
      secondaryFixed: AppColors.platinum,
      secondaryFixedDim: AppColors.silver,
      onSecondaryFixed: AppColors.obsidian,
      onSecondaryFixedVariant: AppColors.charcoal,
      tertiary: AppColors.platinum,
      onTertiary: AppColors.obsidian,
      tertiaryContainer: AppColors.graphite,
      onTertiaryContainer: AppColors.platinum,
      tertiaryFixed: AppColors.platinum,
      tertiaryFixedDim: AppColors.silver,
      onTertiaryFixed: AppColors.obsidian,
      onTertiaryFixedVariant: AppColors.charcoal,
      error: AppColors.platinum,
      onError: AppColors.obsidian,
      errorContainer: AppColors.graphite,
      onErrorContainer: AppColors.white,
      surface: AppColors.charcoal,
      onSurface: AppColors.platinum,
      surfaceDim: AppColors.obsidian,
      surfaceBright: AppColors.graphite,
      surfaceContainerLowest: AppColors.black,
      surfaceContainerLow: AppColors.anthracite,
      surfaceContainer: AppColors.charcoal,
      surfaceContainerHigh: AppColors.graphite,
      surfaceContainerHighest: AppColors.slate,
      onSurfaceVariant: AppColors.silver,
      outline: AppColors.slate,
      outlineVariant: AppColors.graphite,
      shadow: AppColors.shadow,
      scrim: AppColors.black,
      inverseSurface: AppColors.platinum,
      onInverseSurface: AppColors.obsidian,
      inversePrimary: AppColors.charcoal,
      surfaceTint: AppColors.transparent,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      borderSide: const BorderSide(color: AppColors.slate),
    );
    final panelShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      side: const BorderSide(
        color: AppColors.slate,
        width: AppDimensions.hairlineWidth,
      ),
    );
    final typography = Typography.material2021(
      platform: defaultTargetPlatform,
      colorScheme: colorScheme,
    );
    final baseTextTheme = typography.englishLike.merge(typography.white);
    final textTheme = baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: AppColors.platinum,
        fontWeight: FontWeight.w600,
        letterSpacing: AppDimensions.titleLetterSpacing,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: AppDimensions.buttonFontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: AppDimensions.labelLetterSpacing,
      ),
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,
      applyElevationOverlayColor: false,
      splashFactory: NoSplash.splashFactory,
      splashColor: AppColors.transparent,
      highlightColor: AppColors.transparent,
      hoverColor: AppColors.transparent,
      focusColor: AppColors.focusOverlay,
      scaffoldBackgroundColor: AppColors.obsidian,
      canvasColor: AppColors.charcoal,
      cardColor: AppColors.charcoal,
      shadowColor: AppColors.shadow,
      dividerColor: AppColors.slate,
      disabledColor: AppColors.pewter,
      hintColor: AppColors.silver,
      primaryColor: AppColors.platinum,
      primaryColorLight: AppColors.white,
      primaryColorDark: AppColors.obsidian,
      secondaryHeaderColor: AppColors.graphite,
      unselectedWidgetColor: AppColors.silver,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.transparent,
        foregroundColor: AppColors.platinum,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.transparent,
        elevation: AppDimensions.flatElevation,
        scrolledUnderElevation: AppDimensions.flatElevation,
        titleTextStyle: textTheme.titleLarge,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.charcoal,
        surfaceTintColor: AppColors.transparent,
        elevation: AppDimensions.flatElevation,
        shape: panelShape,
        margin: const EdgeInsets.all(AppDimensions.xs),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateColor.resolveWith(_selectionBackground),
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => textTheme.labelLarge!.copyWith(
            color: _selectionForeground(states),
          ),
        ),
        checkmarkColor: AppColors.obsidian,
        side: const BorderSide(
          color: AppColors.slate,
          width: AppDimensions.hairlineWidth,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.xs,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            _selectionBackground,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            _selectionForeground,
          ),
          overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
          side: const WidgetStatePropertyAll(
            BorderSide(
              color: AppColors.slate,
              width: AppDimensions.hairlineWidth,
            ),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.graphite,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.platinum,
        ),
        actionTextColor: AppColors.white,
        disabledActionTextColor: AppColors.pewter,
        closeIconColor: AppColors.silver,
        behavior: SnackBarBehavior.floating,
        elevation: AppDimensions.flatElevation,
        shape: panelShape,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.platinum,
        circularTrackColor: AppColors.graphite,
        linearTrackColor: AppColors.graphite,
        refreshBackgroundColor: AppColors.charcoal,
        strokeWidth: AppDimensions.indicatorStrokeWidth,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.silver,
        selectionColor: AppColors.selection,
        selectionHandleColor: AppColors.silver,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.charcoal,
        hoverColor: AppColors.transparent,
        focusColor: AppColors.graphite,
        contentPadding: const EdgeInsets.all(AppDimensions.md),
        labelStyle: const TextStyle(color: AppColors.silver),
        hintStyle: const TextStyle(color: AppColors.pewter),
        floatingLabelStyle: const TextStyle(color: AppColors.platinum),
        errorStyle: const TextStyle(color: AppColors.platinum),
        border: border,
        enabledBorder: border,
        disabledBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.graphite),
        ),
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(
            color: AppColors.silver,
            width: AppDimensions.focusedBorderWidth,
          ),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.platinum),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(
            color: AppColors.white,
            width: AppDimensions.focusedBorderWidth,
          ),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        colorScheme: colorScheme,
        buttonColor: AppColors.platinum,
        disabledColor: AppColors.charcoal,
        splashColor: AppColors.transparent,
        highlightColor: AppColors.transparent,
        hoverColor: AppColors.transparent,
        focusColor: AppColors.focusOverlay,
        shape: StadiumBorder(),
      ),
    );
  }

  static Color _selectionBackground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AppColors.charcoal;
    }
    return states.contains(WidgetState.selected)
        ? AppColors.platinum
        : AppColors.graphite;
  }

  static Color _selectionForeground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AppColors.pewter;
    }
    return states.contains(WidgetState.selected)
        ? AppColors.obsidian
        : AppColors.platinum;
  }
}
