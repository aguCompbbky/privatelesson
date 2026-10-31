import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/color_constant.dart';
import 'package:privatelesson/core/theme/theme.dart';

void main() {
  test('every color scheme role stays monochrome, including error states', () {
    final theme = AppTheme.monochrome;
    expect(theme.brightness, Brightness.dark);
    expect(AppTheme.light.brightness, theme.brightness);
    expect(AppTheme.light.colorScheme, theme.colorScheme);
    expect(theme.scaffoldBackgroundColor, AppColors.obsidian);
    expect(theme.splashFactory, NoSplash.splashFactory);
    expect(theme.highlightColor, AppColors.transparent);
    expect(theme.hoverColor, AppColors.transparent);

    final properties = theme.colorScheme
        .toDiagnosticsNode()
        .getProperties()
        .whereType<ColorProperty>();
    expect(properties, isNotEmpty);
    for (final property in properties) {
      final color = property.value!;
      expect(color.r, color.g, reason: property.name);
      expect(color.g, color.b, reason: property.name);
    }

    final inputs = theme.inputDecorationTheme;
    expect(inputs.filled, isTrue);
    expect(inputs.fillColor, AppColors.charcoal);
    expect(inputs.focusedBorder?.borderSide.color, AppColors.silver);
    expect(inputs.errorBorder?.borderSide.color, AppColors.platinum);
    expect(inputs.focusedErrorBorder?.borderSide.color, AppColors.white);
    expect(inputs.errorStyle?.color, AppColors.platinum);
  });
}
