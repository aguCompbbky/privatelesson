import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/theme/theme.dart';
import 'package:privatelesson/core/widgets/app_button.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('AppButton calls onPressed when tapped', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      _wrap(AppButton(label: 'Go', onPressed: () => pressed++)),
    );

    await tester.tap(find.text('Go'));

    expect(pressed, 1);
  });

  testWidgets('AppButton ignores taps while loading', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      _wrap(
        AppButton(label: 'Go', isLoading: true, onPressed: () => pressed++),
      ),
    );

    await tester.tap(find.byType(AppButton));

    expect(pressed, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
