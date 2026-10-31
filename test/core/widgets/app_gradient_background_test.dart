import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/color_constant.dart';
import 'package:privatelesson/core/theme/theme.dart';
import 'package:privatelesson/core/widgets/app_gradient_background.dart';

void main() {
  testWidgets('background covers the body even with small page content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.monochrome,
        home: const Scaffold(
          body: AppGradientBackground(child: Center(child: Text('Content'))),
        ),
      ),
    );

    final surface = find.descendant(
      of: find.byType(AppGradientBackground),
      matching: find.byType(DecoratedBox),
    );
    final decoration = tester.widget<DecoratedBox>(surface).decoration;
    expect(
      (decoration as BoxDecoration).gradient,
      AppColors.backgroundGradient,
    );
    expect(tester.getSize(surface), tester.getSize(find.byType(Scaffold)));
    expect(find.text('Content'), findsOneWidget);
  });
}
