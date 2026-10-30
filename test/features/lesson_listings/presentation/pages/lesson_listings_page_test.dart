import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text_field.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/lesson_listing_detail_page.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/lesson_listings_page.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/lesson_listing_card.dart';

import '../../../../helpers/auth_test_app.dart';
import '../../../../helpers/lesson_listings_test_support.dart';

void main() {
  configureTestLocalization();

  testWidgets('announces loading then shows cards', (tester) async {
    final completion = Completer<List<LessonListing>>();
    final cubit = testListingsCubit(
      repository: TestLessonRepository(onList: (_) => completion.future),
    );
    final semantics = tester.ensureSemantics();
    try {
      await pumpListingsApp(tester, createListings: () => cubit, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel(listingCopy('loading')), findsOneWidget);
      expect(find.byType(LessonListingCard), findsNothing);
      completion.complete([testListing()]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LessonListingCard), findsOneWidget);
      expect(find.text('Matematik'), findsOneWidget);
      expect(find.text('İpek Yılmaz'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('empty results show a localized message', (tester) async {
    final cubit = testListingsCubit(
      repository: TestLessonRepository(onList: (_) async => []),
    );
    await pumpListingsApp(tester, createListings: () => cubit);
    expect(find.text(listingCopy('empty')), findsOneWidget);
    expect(find.byType(LessonListingCard), findsNothing);
  });

  testWidgets('retries connection failures', (tester) async {
    final repository = TestLessonRepository(
      onList: (_) => Future.error(
        const LessonListingFailure(LessonListingFailureType.connection),
      ),
    );
    final cubit = testListingsCubit(repository: repository);
    await pumpListingsApp(tester, createListings: () => cubit);
    expect(find.text(listingCopy('errors.connection')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    repository.onList = null;
    await tester.tap(find.widgetWithText(AppButton, listingCopy('retry')));
    await tester.pumpAndSettle();
    expect(repository.filters, hasLength(2));
    expect(find.byType(LessonListingCard), findsOneWidget);
    expect(find.text(listingCopy('errors.connection')), findsNothing);
  });

  for (final entry in {
    'matematik': 'Matematik',
    'ipek yılmaz': 'Matematik',
    'IŞIL KAYA': 'İngilizce',
  }.entries) {
    testWidgets('searches ${entry.key}', (tester) async {
      final cubit = testListingsCubit();
      await pumpListingsApp(tester, createListings: () => cubit);
      await tester.enterText(find.byType(AppTextField), entry.key);
      await tester.pumpAndSettle();
      expect(find.byType(LessonListingCard), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
      expect(cubit.state.listings.single.subject, entry.value);
      expect(find.text(listingCopy('activeFilters')), findsOneWidget);
    });
  }

  testWidgets('combines filters and clears search', (tester) async {
    final cubit = testListingsCubit();
    await pumpListingsApp(tester, createListings: () => cubit);
    await tester.tap(
      find.widgetWithText(ChoiceChip, listingCopy('modes.online')),
    );
    await tester.pumpAndSettle();
    expect(cubit.state.listings, hasLength(2));
    expect(find.text('İngilizce'), findsOneWidget);
    expect(find.text('Gitar'), findsOneWidget);
    await tester.tap(find.byType(FilterChip));
    await tester.pumpAndSettle();
    expect(cubit.state.listings, isEmpty);
    expect(find.text(listingCopy('empty')), findsOneWidget);
    await tester.tap(
      find.widgetWithText(ChoiceChip, listingCopy('modes.recordedVideo')),
    );
    await tester.pumpAndSettle();
    expect(cubit.state.listings.single.subject, 'Fizik');
    expect(find.text('Fizik'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(ChoiceChip, listingCopy('allModes')),
    );
    await tester.pumpAndSettle();
    expect(cubit.state.listings, hasLength(2));
    await tester.enterText(find.byType(AppTextField), 'ipek');
    await tester.pumpAndSettle();
    expect(find.text('Matematik'), findsOneWidget);
    final controller = tester
        .widget<AppTextField>(find.byType(AppTextField))
        .controller!;
    await tester.tap(
      find.widgetWithText(AppButton, listingCopy('clearFilters')),
    );
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(cubit.state.filter.hasActiveFilters, isFalse);
    expect(cubit.state.listings, hasLength(4));
    expect(find.text(listingCopy('activeFilters')), findsNothing);
    expect(find.text(listingCopy('clearFilters')), findsNothing);
    expect(
      tester.widget<FilterChip>(find.byType(FilterChip)).selected,
      isFalse,
    );
  });

  testWidgets('selects every delivery mode', (tester) async {
    final cubit = testListingsCubit();
    await pumpListingsApp(tester, createListings: () => cubit);
    for (final mode in LessonDeliveryMode.values) {
      await tester.tap(
        find.widgetWithText(ChoiceChip, listingCopy('modes.${mode.name}')),
      );
      await tester.pumpAndSettle();
      expect(cubit.state.filter.deliveryMode, mode);
      expect(cubit.state.listings, isNotEmpty);
      expect(
        cubit.state.listings.every((item) => item.deliveryMode == mode),
        isTrue,
      );
    }
    await tester.tap(find.widgetWithText(ChoiceChip, listingCopy('allModes')));
    await tester.pumpAndSettle();
    expect(cubit.state.listings, hasLength(4));
  });

  testWidgets('translates controls, cards and filters', (tester) async {
    final cubit = testListingsCubit();
    await pumpListingsApp(tester, createListings: () => cubit);
    await tester.enterText(find.byType(AppTextField), 'Matematik');
    await tester.pumpAndSettle();
    final previous = cubit.state;
    final controller = tester
        .widget<AppTextField>(find.byType(AppTextField))
        .controller!;
    await tester.tap(find.byType(LanguageSwitcherButton));
    await tester.pumpAndSettle();
    for (final key in [
      'title',
      'search',
      'deliveryMode',
      'allModes',
      'certificateOnly',
      'activeFilters',
      'clearFilters',
      'certificateAvailable',
    ]) {
      expect(
        find.text(listingCopy(key, locale: AppConstants.englishLocale)),
        findsOneWidget,
      );
      expect(find.text(listingCopy(key)), findsNothing);
    }
    expect(cubit.state, same(previous));
    expect(controller.text, 'Matematik');
    expect(find.text('İpek Yılmaz'), findsOneWidget);
  });

  testWidgets('navigates to detail and back', (tester) async {
    final cubit = testListingsCubit();
    final router = await pumpListingsApp(tester, createListings: () => cubit);
    await tester.enterText(find.byType(AppTextField), 'Matematik');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LessonListingCard));
    await tester.pumpAndSettle();
    expect(find.byType(LessonListingDetailPage), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.listingDetailPath('mock-lesson-1'),
    );
    expect(find.text('İpek Yılmaz'), findsOneWidget);
    await tester.tap(find.byTooltip(listingCopy('back')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonListingsPage), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.homePath);
    expect(cubit.isClosed, isFalse);
    expect(cubit.state.filter.searchQuery, 'Matematik');
    expect(find.text('Matematik'), findsWidgets);
  });
}
