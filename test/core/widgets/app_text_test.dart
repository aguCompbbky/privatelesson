import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/constants/color_constant.dart';
import 'package:privatelesson/core/theme/theme.dart';
import 'package:privatelesson/core/widgets/app_text.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.monochrome,
  home: Scaffold(body: child),
);

void main() {
  final variants =
      <
        ({
          String name,
          AppText Function(
            String, {
            Color? color,
            TextAlign? textAlign,
            TextOverflow? overflow,
            int? maxLines,
            TextStyle? style,
            Key? key,
          })
          builder,
          double size,
          double spacing,
          double height,
          FontWeight weight,
          Color color,
        })
      >[
        (
          name: 'headline',
          builder: AppText.headline,
          size: AppDimensions.fontSizeHeadline,
          spacing: AppDimensions.letterSpacingHeadline,
          height: AppDimensions.lineHeightHeading,
          weight: FontWeight.w600,
          color: AppColors.platinum,
        ),
        (
          name: 'title',
          builder: AppText.title,
          size: AppDimensions.fontSizeTitle,
          spacing: AppDimensions.letterSpacingTitle,
          height: AppDimensions.lineHeightHeading,
          weight: FontWeight.w600,
          color: AppColors.platinum,
        ),
        (
          name: 'subhead',
          builder: AppText.subhead,
          size: AppDimensions.fontSizeSubhead,
          spacing: AppDimensions.letterSpacingSubhead,
          height: AppDimensions.lineHeightBody,
          weight: FontWeight.w600,
          color: AppColors.silver,
        ),
        (
          name: 'body',
          builder: AppText.body,
          size: AppDimensions.fontSizeBody,
          spacing: AppDimensions.letterSpacingBody,
          height: AppDimensions.lineHeightBody,
          weight: FontWeight.w400,
          color: AppColors.platinum,
        ),
        (
          name: 'label',
          builder: AppText.label,
          size: AppDimensions.fontSizeLabel,
          spacing: AppDimensions.letterSpacingBody,
          height: AppDimensions.lineHeightBody,
          weight: FontWeight.w500,
          color: AppColors.silver,
        ),
        (
          name: 'caption',
          builder: AppText.caption,
          size: AppDimensions.fontSizeCaption,
          spacing: AppDimensions.letterSpacingBody,
          height: AppDimensions.lineHeightBody,
          weight: FontWeight.w400,
          color: AppColors.pewter,
        ),
      ];

  for (final variant in variants) {
    testWidgets('${variant.name} renders the standard readable style', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(variant.builder('Readable text')));

      final text = tester.widget<Text>(find.text('Readable text'));
      expect(text.style?.fontSize, variant.size);
      expect(text.style?.letterSpacing, variant.spacing);
      expect(text.style?.height, variant.height);
      expect(text.style?.fontWeight, variant.weight);
      expect(text.style?.color, variant.color);
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
    });

    testWidgets(
      '${variant.name} merges overrides and forwards layout options',
      (
        tester,
      ) async {
        const key = ValueKey('text');
        await tester.pumpWidget(
          _wrap(
            variant.builder(
              'Customized text',
              key: key,
              color: AppColors.white,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.pewter,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );

        expect(find.byKey(key), findsOneWidget);
        final text = tester.widget<Text>(find.text('Customized text'));
        expect(text.style?.color, AppColors.white);
        expect(text.style?.fontWeight, FontWeight.w700);
        expect(text.style?.decoration, TextDecoration.underline);
        expect(text.style?.fontSize, variant.size);
        expect(text.style?.height, variant.height);
        expect(text.textAlign, TextAlign.end);
        expect(text.overflow, TextOverflow.ellipsis);
        expect(text.maxLines, 2);
      },
    );
  }

  testWidgets('a style color overrides the default when color is omitted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AppText.body(
          'Content',
          style: TextStyle(color: AppColors.silver),
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Content')).style?.color,
      AppColors.silver,
    );
  });

  testWidgets(
    'uses central theme changes and respects accessible text scaling',
    (
      tester,
    ) async {
      final theme = AppTheme.monochrome;
      const text = 'A longer lesson description wraps into comfortable lines.';
      await tester.pumpWidget(
        _wrap(
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SizedBox(width: 240, child: AppText.body(text)),
          ),
          theme: theme.copyWith(
            textTheme: theme.textTheme.copyWith(
              bodyMedium: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppDimensions.fontSizeSubhead,
              ),
            ),
          ),
        ),
      );

      final rendered = tester.widget<RichText>(
        find.descendant(
          of: find.byType(AppText),
          matching: find.byType(RichText),
        ),
      );
      expect(rendered.text.style?.fontSize, AppDimensions.fontSizeSubhead);
      expect(
        rendered.textScaler.scale(AppDimensions.fontSizeSubhead),
        AppDimensions.fontSizeSubhead * 2,
      );
      expect(tester.getSize(find.byType(AppText)).height, greaterThan(100));
      expect(tester.takeException(), isNull);
    },
  );
}
