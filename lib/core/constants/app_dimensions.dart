/// Shared spacing, sizing and radius values.
abstract final class AppDimensions {
  /// Width and height of the authentication brand mark.
  static const double logoSize = 88;

  /// Soft squircle corners of the brand mark.
  static const double logoRadius = 24;

  /// Size of the fallback brand emblem.
  static const double logoEmblemSize = 40;

  /// Maximum readable width of authentication forms.
  static const double authFormMaxWidth = 440;

  /// Extra small spacing.
  static const double xs = 4;

  /// Small spacing.
  static const double sm = 8;

  /// Medium spacing.
  static const double md = 16;

  /// Large spacing.
  static const double lg = 24;

  /// Extra large spacing.
  static const double xl = 32;

  /// Default corner radius of inputs and buttons.
  static const double radiusMd = 12;

  /// Corner radius of elevated panels and cards.
  static const double radiusLg = 24;

  /// Radius that keeps action buttons and chips pill-shaped.
  static const double radiusPill = 999;

  /// Opacity of a pressed action button.
  static const double pressedOpacity = 0.65;

  /// Flat elevation for surfaces without Material shadows.
  static const double flatElevation = 0;

  /// Width of subtle card and button outlines.
  static const double hairlineWidth = 0.5;

  /// Slightly tightened tracking for page and card titles.
  static const double titleLetterSpacing = -0.3;

  /// Tracking for short action labels.
  static const double labelLetterSpacing = 0.2;

  /// Font size of shared action labels.
  static const double buttonFontSize = 16;

  /// Blur radius of a card's soft shadow.
  static const double cardShadowBlur = 24;

  /// Vertical offset of a card's soft shadow.
  static const double cardShadowOffset = 8;

  /// Blur radius of an enabled action's shadow.
  static const double buttonShadowBlur = 12;

  /// Vertical offset of an enabled action's shadow.
  static const double buttonShadowOffset = 4;

  /// Default height of buttons.
  static const double buttonHeight = 48;

  /// Width of input borders.
  static const double borderWidth = 1;

  /// Width of the border of a focused input.
  static const double focusedBorderWidth = 2;

  /// Size of the inline loading indicator.
  static const double indicatorSize = 20;

  /// Stroke width of the inline loading indicator.
  static const double indicatorStrokeWidth = 2;
}
