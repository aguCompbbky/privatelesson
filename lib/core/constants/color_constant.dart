import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';

/// The application's exclusively monochrome palette and shared effects.
abstract final class AppColors {
  /// Pure black for shadows and the deepest surfaces.
  static const Color black = Color(0xFF000000);

  /// Deep obsidian for the screen base and luminous button text.
  static const Color obsidian = Color(0xFF0B0B0B);

  /// Dark anthracite for quiet background transitions.
  static const Color anthracite = Color(0xFF141414);

  /// Charcoal for input fields and subdued surfaces.
  static const Color charcoal = Color(0xFF1C1C1C);

  /// Graphite for elevated surfaces.
  static const Color graphite = Color(0xFF2B2B2B);

  /// Slate for subtle outlines.
  static const Color slate = Color(0xFF555555);

  /// Pewter for disabled content.
  static const Color pewter = Color(0xFF939393);

  /// Silver for secondary content and focused borders.
  static const Color silver = Color(0xFFC7C7C7);

  /// Platinum for high-contrast text and validation feedback.
  static const Color platinum = Color(0xFFE8E8E8);

  /// Pure white for the brightest highlights.
  static const Color white = Color(0xFFFFFFFF);

  /// Transparent black for surfaces without a visible fill or overlay.
  static const Color transparent = Color(0x00000000);

  /// Translucent black for soft shadows.
  static const Color shadow = Color(0x40000000);

  /// Subtle white overlay for keyboard focus.
  static const Color focusOverlay = Color(0x1FFFFFFF);

  /// Translucent silver for selected text.
  static const Color selection = Color(0x66C7C7C7);

  /// Subtle diagonal depth shared by all page bodies.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [obsidian, anthracite, charcoal],
  );

  /// Soft graphite-to-charcoal shading for elevated panels.
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [graphite, charcoal],
  );

  /// Luminous primary action fill with an obsidian foreground.
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, platinum, silver],
  );

  /// Restrained secondary action fill with a platinum foreground.
  static const LinearGradient secondaryButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [graphite, anthracite],
  );

  /// Muted fill shared by disabled and loading actions.
  static const LinearGradient disabledButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [charcoal, anthracite],
  );

  /// Soft depth beneath cards.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: shadow,
      blurRadius: AppDimensions.cardShadowBlur,
      offset: Offset(0, AppDimensions.cardShadowOffset),
    ),
  ];

  /// Subtle depth beneath enabled actions.
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: shadow,
      blurRadius: AppDimensions.buttonShadowBlur,
      offset: Offset(0, AppDimensions.buttonShadowOffset),
    ),
  ];
}
