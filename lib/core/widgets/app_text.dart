import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/color_constant.dart';

enum _AppTextVariant { headline, title, subhead, body, label, caption }

/// Shared text hierarchy backed by the central application theme.
class AppText extends StatelessWidget {
  /// Creates a prominent page or brand headline.
  const AppText.headline(
    this.text, {
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.style,
    super.key,
  }) : _variant = _AppTextVariant.headline;

  /// Creates a page bar or card title.
  const AppText.title(
    this.text, {
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.style,
    super.key,
  }) : _variant = _AppTextVariant.title;

  /// Creates a section heading.
  const AppText.subhead(
    this.text, {
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.style,
    super.key,
  }) : _variant = _AppTextVariant.subhead;

  /// Creates readable paragraph or field content.
  const AppText.body(
    this.text, {
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.style,
    super.key,
  }) : _variant = _AppTextVariant.body;

  /// Creates a field or control label.
  const AppText.label(
    this.text, {
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.style,
    super.key,
  }) : _variant = _AppTextVariant.label;

  /// Creates supporting metadata or a caption.
  const AppText.caption(
    this.text, {
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.style,
    super.key,
  }) : _variant = _AppTextVariant.caption;

  /// Localized interface text or user-provided content.
  final String text;

  /// Optional color override, taking precedence over [style].
  final Color? color;

  /// Horizontal alignment, inherited when omitted.
  final TextAlign? textAlign;

  /// How content that exceeds its bounds is displayed.
  final TextOverflow? overflow;

  /// Optional line limit; text wraps freely by default.
  final int? maxLines;

  /// Overrides merged over the variant's themed style and default color.
  final TextStyle? style;

  final _AppTextVariant _variant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (baseStyle, defaultColor) = switch (_variant) {
      _AppTextVariant.headline => (
        textTheme.headlineSmall!,
        AppColors.platinum,
      ),
      _AppTextVariant.title => (textTheme.titleLarge!, AppColors.platinum),
      _AppTextVariant.subhead => (textTheme.titleMedium!, AppColors.silver),
      _AppTextVariant.body => (textTheme.bodyMedium!, AppColors.platinum),
      _AppTextVariant.label => (textTheme.labelMedium!, AppColors.silver),
      _AppTextVariant.caption => (textTheme.bodySmall!, AppColors.pewter),
    };
    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: baseStyle
          .copyWith(color: defaultColor)
          .merge(style)
          .copyWith(
            color: color,
          ),
    );
  }
}
