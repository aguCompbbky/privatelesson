import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';

void main() {
  testWidgets('page gutters adapt to width and remain between 16 and 24', (
    tester,
  ) async {
    for (final (width, horizontal) in [
      (280.0, 16.0),
      (320.0, 16.0),
      (390.0, 19.5),
      (480.0, 24.0),
      (1024.0, 24.0),
    ]) {
      late EdgeInsets padding;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(
            builder: (context) {
              padding = AppDimensions.screenPadding(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(padding.left, horizontal);
      expect(padding.right, horizontal);
      expect(padding.top, AppDimensions.md);
      expect(padding.bottom, AppDimensions.md);
    }
  });
}
