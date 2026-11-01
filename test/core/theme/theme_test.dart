import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/constants/color_constant.dart';
import 'package:privatelesson/core/theme/theme.dart';
import 'package:privatelesson/core/widgets/app_control_label.dart';

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

  test('inputs and app bars use the central reading hierarchy', () {
    final theme = AppTheme.monochrome;
    expect(theme.appBarTheme.titleTextStyle, theme.textTheme.titleLarge);
    expect(theme.textTheme.bodyLarge?.fontSize, AppDimensions.fontSizeBody);
    expect(theme.textTheme.bodyLarge?.height, AppDimensions.lineHeightBody);
    expect(theme.inputDecorationTheme.labelStyle, theme.textTheme.labelMedium);
    expect(
      theme.inputDecorationTheme.hintStyle?.fontSize,
      AppDimensions.fontSizeBody,
    );
  });

  for (final isChoice in [true, false]) {
    for (final isSelected in [false, true]) {
      for (final isEnabled in [true, false]) {
        testWidgets(
          '${isChoice ? 'ChoiceChip' : 'FilterChip'} '
          'selected=$isSelected enabled=$isEnabled keeps restrained colors',
          (tester) async {
            final theme = AppTheme.monochrome;
            final chip = isChoice
                ? ChoiceChip(
                    label: const AppControlLabel('In Person'),
                    selected: isSelected,
                    onSelected: isEnabled ? (_) {} : null,
                  )
                : FilterChip(
                    label: const AppControlLabel('In Person'),
                    selected: isSelected,
                    onSelected: isEnabled ? (_) {} : null,
                  );
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: Scaffold(body: Center(child: chip)),
              ),
            );
            await tester.pumpAndSettle();

            final background = isSelected && isEnabled
                ? AppColors.slate
                : AppColors.charcoal;
            final foreground = !isEnabled
                ? AppColors.pewter
                : isSelected
                ? AppColors.white
                : AppColors.silver;
            final ink = tester.widget<Ink>(
              find.descendant(
                of: find.byType(RawChip),
                matching: find.byType(Ink),
              ),
            );
            final decoration = ink.decoration! as ShapeDecoration;
            expect(decoration.color, background);
            expect(decoration.shape, isA<StadiumBorder>());
            expect(
              (decoration.shape as StadiumBorder).side.color,
              isSelected && isEnabled ? AppColors.silver : AppColors.slate,
            );
            expect(
              tester.widget<Text>(find.text('In Person')).style?.color,
              foreground,
            );
            expect(theme.chipTheme.checkmarkColor, AppColors.white);
            expect(theme.chipTheme.elevation, AppDimensions.flatElevation);
            expect(theme.chipTheme.pressElevation, AppDimensions.flatElevation);
            expect(theme.chipTheme.surfaceTintColor, AppColors.transparent);
          },
        );
      }
    }
  }

  testWidgets('control labels retain segmented selection colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.monochrome,
        home: Scaffold(
          body: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: AppControlLabel('Selected')),
              ButtonSegment(value: false, label: AppControlLabel('Unselected')),
            ],
            selected: const {true},
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Selected')).style?.color,
      AppColors.obsidian,
    );
    expect(
      tester.widget<Text>(find.text('Unselected')).style?.color,
      AppColors.platinum,
    );
  });
}
