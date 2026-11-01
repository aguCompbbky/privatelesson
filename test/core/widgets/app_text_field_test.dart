import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/theme/theme.dart';
import 'package:privatelesson/core/widgets/app_text_field.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.monochrome,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders label, hint and error text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppTextField(
          label: 'Email',
          hint: 'user@example.com',
          errorText: 'Invalid email',
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Invalid email'), findsOneWidget);
  });

  testWidgets('renders prefix and suffix icons', (tester) async {
    var suffixTapped = 0;
    await tester.pumpWidget(
      _wrap(
        AppTextField(
          label: 'Search',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => suffixTapped++,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    expect(suffixTapped, 1);
  });

  testWidgets('controller reflects edited text and triggers onChanged', (
    tester,
  ) async {
    final controller = TextEditingController();
    var changedValue = '';

    await tester.pumpWidget(
      _wrap(
        AppTextField(
          label: 'Query',
          controller: controller,
          onChanged: (val) => changedValue = val,
        ),
      ),
    );

    await tester.enterText(find.byType(AppTextField), 'Flutter');
    expect(controller.text, 'Flutter');
    expect(changedValue, 'Flutter');
  });
}

