import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/constants/color_constant.dart';
import 'package:privatelesson/core/theme/theme.dart';
import 'package:privatelesson/core/widgets/app_button.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

Finder _gradientSurface() => find.descendant(
  of: find.byType(AppButton),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).gradient != null,
  ),
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_gradientSurface()).decoration as BoxDecoration;

void main() {
  testWidgets('AppButton calls onPressed when tapped', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      _wrap(AppButton(label: 'Go', onPressed: () => pressed++)),
    );

    await tester.tap(find.text('Go'));

    expect(pressed, 1);
  });

  for (final variant in AppButtonVariant.values) {
    testWidgets('$variant renders its gradient, foreground and pill shape', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Go',
            variant: variant,
            leading: const Icon(Icons.arrow_forward),
            onPressed: () {},
          ),
        ),
      );

      final isPrimary = variant == AppButtonVariant.primary;
      final decoration = _decoration(tester);
      expect(
        decoration.gradient,
        isPrimary
            ? AppColors.primaryButtonGradient
            : AppColors.secondaryButtonGradient,
      );
      expect(
        decoration.borderRadius,
        BorderRadius.circular(AppDimensions.radiusPill),
      );
      expect(decoration.boxShadow, AppColors.buttonShadow);
      expect(
        tester.widget<Text>(find.text('Go')).style?.color,
        isPrimary ? AppColors.obsidian : AppColors.platinum,
      );
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets(
      '$variant ignores taps and shows muted progress while loading',
      (
        tester,
      ) async {
        var pressed = 0;
        await tester.pumpWidget(
          _wrap(
            AppButton(
              label: 'Go',
              variant: variant,
              leading: const Icon(Icons.arrow_forward),
              isLoading: true,
              onPressed: () => pressed++,
            ),
          ),
        );

        await tester.tap(find.byType(AppButton));

        expect(pressed, 0);
        expect(find.text('Go'), findsNothing);
        expect(find.byIcon(Icons.arrow_forward), findsNothing);
        expect(_decoration(tester).gradient, AppColors.disabledButtonGradient);
        expect(_decoration(tester).boxShadow, isNull);
        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.color, AppColors.pewter);
        expect(indicator.strokeWidth, AppDimensions.indicatorStrokeWidth);
        expect(
          tester.getSize(find.byType(CircularProgressIndicator)),
          const Size.square(AppDimensions.indicatorSize),
        );
        expect(
          tester
              .widget<CupertinoButton>(find.byType(CupertinoButton))
              .onPressed,
          isNull,
        );
      },
    );
  }

  testWidgets('null callback disables the action without showing progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const AppButton(label: 'Go', onPressed: null)),
    );

    expect(_decoration(tester).gradient, AppColors.disabledButtonGradient);
    expect(_decoration(tester).boxShadow, isNull);
    expect(tester.widget<Text>(find.text('Go')).style?.color, AppColors.pewter);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester.widget<CupertinoButton>(find.byType(CupertinoButton)).onPressed,
      isNull,
    );
  });

  testWidgets('press fades the whole surface and release restores opacity', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      _wrap(AppButton(label: 'Go', onPressed: () => pressed++)),
    );
    final button = tester.widget<CupertinoButton>(find.byType(CupertinoButton));
    expect(button.pressedOpacity, AppDimensions.pressedOpacity);
    expect(button.focusColor, AppColors.silver);
    final fade = find
        .ancestor(
          of: _gradientSurface(),
          matching: find.byType(FadeTransition),
        )
        .first;

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Go')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FadeTransition>(fade).opacity.value,
      AppDimensions.pressedOpacity,
    );
    expect(pressed, 0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
    expect(pressed, 1);
  });

  testWidgets('stretch layout paints and taps across the full button width', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [AppButton(label: 'Go', onPressed: () => pressed++)],
          ),
        ),
      ),
    );

    const expectedSize = Size(320, AppDimensions.buttonHeight);
    expect(tester.getSize(find.byType(AppButton)), expectedSize);
    expect(tester.getSize(_gradientSurface()), expectedSize);
    await tester.tapAt(
      tester.getTopLeft(_gradientSurface()) + const Offset(8, 24),
    );
    expect(pressed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large multiline labels grow without overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SizedBox(
            width: 240,
            child: AppButton(
              label: 'Continue with the selected profile',
              leading: const Icon(Icons.arrow_forward),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(AppButton)).height,
      greaterThan(AppDimensions.buttonHeight),
    );
    expect(tester.takeException(), isNull);
  });
}
