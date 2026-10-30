import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text_field.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:privatelesson/features/auth/presentation/pages/login_page.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/mock_lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/repositories/lesson_listing_repository_impl.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/create_lesson_listing_page.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/lesson_listing_detail_page.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/lesson_listings_page.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/create_listing_failure_message.dart';
import 'package:privatelesson/features/lesson_listings/presentation/widgets/lesson_listing_card.dart';

import '../../../../helpers/auth_test_app.dart';
import '../../../../helpers/lesson_listings_test_support.dart';

void main() {
  configureTestLocalization();

  testWidgets('guards signed-out and incomplete profiles', (
    tester,
  ) async {
    final auth = createTestAuthCubit();
    var creationCalls = 0;
    final router = await pumpAuthApp(
      tester,
      auth,
      createCreateLessonListingCubit: () {
        creationCalls += 1;
        return testCreateListingCubit();
      },
    );
    router.go(AppRoutes.createListingPath);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.loginPath);
    expect(find.byType(LoginPage), findsOneWidget);
    await auth.signInWithGoogle();
    router.go(AppRoutes.createListingPath);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.completeProfilePath,
    );
    expect(find.byType(CompleteProfilePage), findsOneWidget);
    expect(find.byType(CreateLessonListingPage), findsNothing);
    expect(creationCalls, isZero);
  });

  testWidgets('students cannot access creation even by a direct route', (
    tester,
  ) async {
    var creationCalls = 0;
    final router = await pumpListingsApp(
      tester,
      createCreateLessonListingCubit: () {
        creationCalls += 1;
        return testCreateListingCubit();
      },
    );
    expect(find.byType(LessonListingsPage), findsOneWidget);
    expect(_button('title'), findsNothing);
    router.go(AppRoutes.createListingPath);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.homePath);
    expect(find.byType(LessonListingsPage), findsOneWidget);
    expect(find.byType(CreateLessonListingPage), findsNothing);
    expect(_button('title'), findsNothing);
    expect(creationCalls, isZero);
  });

  testWidgets('teachers open creation with empty contacts', (
    tester,
  ) async {
    final cubit = testCreateListingCubit();
    final router = await pumpListingsApp(
      tester,
      role: UserRole.teacher,
      createCreateLessonListingCubit: () => cubit,
    );
    expect(_button('title'), findsOneWidget);
    await _tap(tester, _button('title'));
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.createListingPath,
    );
    expect(find.byType(CreateLessonListingPage), findsOneWidget);
    expect(find.byType(LessonListingDetailPage), findsNothing);
    expect(find.text(_copy('contactNotice')), findsOneWidget);
    expect(_field(_copy('emailAddress')), findsNothing);
    expect(cubit.state.emailAddress, isEmpty);
    await _tap(tester, _switch('shareEmail'));
    expect(_controller(tester, _copy('emailAddress')).text, isEmpty);
    expect(cubit.state.emailAddress, isEmpty);
    await _tap(tester, _switch('shareWhatsApp'));
    expect(_controller(tester, _copy('whatsAppNumber')).text, isEmpty);
    expect(find.text(_copy('whatsAppHint')), findsOneWidget);
    await _tap(tester, find.byTooltip(listingCopy('back')));
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.homePath);
    expect(cubit.isClosed, isTrue);
  });

  testWidgets('validates input and translates preserved edits and failures', (
    tester,
  ) async {
    final cubit = testCreateListingCubit();
    await pumpListingsApp(
      tester,
      role: UserRole.teacher,
      createCreateLessonListingCubit: () => cubit,
    );
    await _tap(tester, _button('title'));
    await _submitExpect(tester, LessonListingFailureType.invalidSubject);
    await _enter(tester, _copy('subject'), 'Geometri');
    await _submitExpect(tester, LessonListingFailureType.invalidDescription);
    await _enter(tester, listingCopy('description'), 'Üçgenler ve çemberler.');
    await _tap(tester, _switch('hasCertificate'));
    await _submitExpect(
      tester,
      LessonListingFailureType.missingCertificateDescription,
    );
    await _enter(
      tester,
      _copy('certificateDescription'),
      'Matematik diploması',
    );
    await _submitExpect(tester, LessonListingFailureType.missingContactMethod);
    await _tap(tester, _switch('shareWhatsApp'));
    await _enter(tester, _copy('whatsAppNumber'), '05550000001');
    await _submitExpect(tester, LessonListingFailureType.invalidWhatsAppNumber);
    await _enter(tester, _copy('whatsAppNumber'), '+905550000001');
    await _tap(tester, _switch('shareEmail'));
    await _submitExpect(tester, LessonListingFailureType.invalidEmailAddress);
    await _enter(tester, _copy('emailAddress'), 'invalid-email');
    await _submitExpect(tester, LessonListingFailureType.invalidEmailAddress);

    final previous = cubit.state;
    final subjectController = _controller(tester, _copy('subject'));
    final emailController = _controller(tester, _copy('emailAddress'));
    for (final locale in [
      AppConstants.englishLocale,
      AppConstants.turkishLocale,
    ]) {
      await _tap(tester, find.byType(LanguageSwitcherButton));
      expect(cubit.state, same(previous));
      expect(find.text(_copy('title', locale: locale)), findsOneWidget);
      expect(find.text(_copy('contactNotice', locale: locale)), findsOneWidget);
      expect(
        find.text(_copy('errors.invalidEmailAddress', locale: locale)),
        findsOneWidget,
      );
      expect(
        _controller(tester, _copy('subject', locale: locale)),
        same(subjectController),
      );
      expect(subjectController.text, 'Geometri');
      expect(
        _controller(tester, listingCopy('description', locale: locale)).text,
        'Üçgenler ve çemberler.',
      );
      expect(
        _controller(
          tester,
          _copy('certificateDescription', locale: locale),
        ).text,
        'Matematik diploması',
      );
      expect(
        _controller(tester, _copy('whatsAppNumber', locale: locale)).text,
        '+905550000001',
      );
      expect(
        _controller(tester, _copy('emailAddress', locale: locale)),
        same(emailController),
      );
      expect(emailController.text, 'invalid-email');
    }
    await _enter(tester, _copy('emailAddress'), 'chosen@example.invalid');
    expect(find.byType(CreateListingFailureMessage), findsNothing);
  });

  for (final locale in AppConstants.supportedLocales) {
    for (final type in LessonListingFailureType.values) {
      testWidgets('announces ${type.name} in ${locale.languageCode}', (
        tester,
      ) async {
        final cubit = testCreateListingCubit(
          repository: TestLessonRepository(
            onCreate: (_) => Future.error(LessonListingFailure(type)),
          ),
        );
        cubit.updateSubject('Matematik');
        cubit.updateDescription('Ders açıklaması.');
        cubit.setShareEmail(value: true);
        cubit.updateEmailAddress('chosen@example.invalid');
        final router = await pumpListingsApp(
          tester,
          role: UserRole.teacher,
          createCreateLessonListingCubit: () => cubit,
        );
        await _tap(tester, _button('title'));
        if (locale == AppConstants.englishLocale) {
          await _tap(tester, find.byType(LanguageSwitcherButton));
        }
        final semantics = tester.ensureSemantics();
        try {
          await _tap(tester, _button('submit', locale: locale));
          final message = _copy('errors.${type.name}', locale: locale);
          final errors = {
            for (final failure in LessonListingFailureType.values)
              _copy('errors.${failure.name}', locale: locale),
          };
          expect(errors, hasLength(LessonListingFailureType.values.length));
          expect(find.text(message), findsOneWidget);
          await tester.ensureVisible(find.text(message));
          await tester.pumpAndSettle();
          expect(find.bySemanticsLabel(message), findsOneWidget);
          final region = tester.widget<Semantics>(
            find.descendant(
              of: find.byType(CreateListingFailureMessage),
              matching: find.byType(Semantics),
            ),
          );
          expect(region.properties.liveRegion, isTrue);
          expect(
            router.routeInformationProvider.value.uri.path,
            AppRoutes.createListingPath,
          );
          expect(cubit.state.isSubmitting, isFalse);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets('locks controls and announces publication', (
    tester,
  ) async {
    final completion = Completer<LessonListing>();
    final repository = TestLessonRepository(onCreate: (_) => completion.future);
    final cubit = testCreateListingCubit(repository: repository);
    cubit.updateSubject('Matematik');
    cubit.updateDescription('Ders açıklaması.');
    cubit.setShareEmail(value: true);
    cubit.updateEmailAddress('chosen@example.invalid');
    final router = await pumpListingsApp(
      tester,
      role: UserRole.teacher,
      createCreateLessonListingCubit: () => cubit,
    );
    await _tap(tester, _button('title'));
    final semantics = tester.ensureSemantics();
    try {
      await tester.ensureVisible(_button('submit'));
      await tester.tap(_button('submit'));
      await tester.pump();
      expect(
        tester.widget<AppButton>(_buttonForSubmission()).isLoading,
        isTrue,
      );
      final fields = tester.widgetList<AppTextField>(find.byType(AppTextField));
      for (final field in fields) {
        expect(field.enabled, isFalse);
      }
      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      for (final control in switches) {
        expect(control.onChanged, isNull);
      }
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      for (final chip in chips) {
        expect(chip.onSelected, isNull);
      }
      for (final icon in [Icons.arrow_back, Icons.logout]) {
        expect(
          tester
              .widget<IconButton>(find.widgetWithIcon(IconButton, icon))
              .onPressed,
          isNull,
        );
      }
      expect(find.bySemanticsLabel(_copy('submitting')), findsOneWidget);
      await tester.tap(_buttonForSubmission());
      expect(repository.created, hasLength(1));
      completion.completeError(
        const LessonListingFailure(LessonListingFailureType.connection),
      );
      await tester.pumpAndSettle();
      expect(cubit.state.isSubmitting, isFalse);
      expect(find.text(_copy('errors.connection')), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.createListingPath,
      );
      expect(
        _controller(tester, _copy('emailAddress')).text,
        'chosen@example.invalid',
      );
    } finally {
      semantics.dispose();
    }
  });

  for (final channels in [(true, false), (false, true), (true, true)]) {
    testWidgets('publishes $channels through list and detail', (
      tester,
    ) async {
      final repository = LessonListingRepositoryImpl(
        MockLessonListingDataSource(),
      );
      final cubit = testCreateListingCubit(repository: repository);
      final lists = <LessonListingsCubit>[];
      final details = <LessonListingDetailCubit>[];
      final contacts = TestContactRepository();
      final router = await pumpListingsApp(
        tester,
        role: UserRole.teacher,
        createCreateLessonListingCubit: () => cubit,
        createListings: () {
          final listingCubit = testListingsCubit(repository: repository);
          lists.add(listingCubit);
          return listingCubit;
        },
        createDetail: (id) {
          final detail = testDetailCubit(
            listingId: id,
            repository: repository,
            contacts: contacts,
          );
          details.add(detail);
          return detail;
        },
      );
      expect(lists, hasLength(1));
      expect(find.byType(LessonListingCard), findsNothing);
      await _tap(tester, _button('title'));
      expect(lists.single.isClosed, isTrue);
      await _enter(tester, _copy('subject'), ' Yeni geometri dersi ');
      await _enter(tester, listingCopy('description'), 'Çemberler ve açılar.');
      for (final mode in LessonDeliveryMode.values) {
        await _tap(
          tester,
          find.widgetWithText(ChoiceChip, listingCopy('modes.${mode.name}')),
        );
        expect(cubit.state.deliveryMode, mode);
      }
      await _tap(tester, _switch('hasCertificate'));
      await _enter(
        tester,
        _copy('certificateDescription'),
        'Matematik diploması',
      );
      if (channels.$1) {
        await _tap(tester, _switch('shareWhatsApp'));
        await _enter(tester, _copy('whatsAppNumber'), '+90 (555) 000-00-01');
      }
      if (channels.$2) {
        await _tap(tester, _switch('shareEmail'));
        expect(_controller(tester, _copy('emailAddress')).text, isEmpty);
        await _enter(tester, _copy('emailAddress'), 'chosen@example.invalid');
      }
      await _tap(tester, _button('submit'));
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.homePath,
      );
      expect(find.byType(LessonListingsPage), findsOneWidget);
      expect(find.byType(CreateLessonListingPage), findsNothing);
      expect(find.byType(LessonListingCard), findsOneWidget);
      expect(find.text('Yeni geometri dersi'), findsOneWidget);
      expect(lists, hasLength(2));
      expect(cubit.isClosed, isTrue);
      final saved = lists.last.state.listings.single;
      expect(saved.id, cubit.state.createdListing!.id);
      await _tap(tester, find.byType(LessonListingCard));
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.listingDetailPath(saved.id),
      );
      expect(find.byType(LessonListingDetailPage), findsOneWidget);
      expect(find.text('Çemberler ve açılar.'), findsOneWidget);
      expect(find.text('Matematik diploması'), findsOneWidget);
      expect(find.text(testAuthUser.displayName), findsOneWidget);
      expect(find.text(listingCopy('modes.recordedVideo')), findsOneWidget);
      final detail = details.single.state.listing!;
      expect(detail.teacherId, testAuthUser.userId);
      expect(
        detail.contact.whatsAppNumber,
        channels.$1 ? '+905550000001' : null,
      );
      expect(
        detail.contact.emailAddress,
        channels.$2 ? 'chosen@example.invalid' : null,
      );
      final whatsapp = find.widgetWithText(
        AppButton,
        listingCopy('contact.whatsApp'),
      );
      final email = find.widgetWithText(
        AppButton,
        listingCopy('contact.email'),
      );
      expect(whatsapp, channels.$1 ? findsOneWidget : findsNothing);
      expect(email, channels.$2 ? findsOneWidget : findsNothing);
      if (channels.$1) {
        await _tap(tester, whatsapp);
        expect(contacts.whatsAppValues, ['+905550000001']);
      }
      if (channels.$2) {
        await _tap(tester, email);
        expect(contacts.emailValues, ['chosen@example.invalid']);
      }
    });
  }
}

String _copy(String key, {Locale locale = AppConstants.turkishLocale}) =>
    listingCopy('create.$key', locale: locale);

Finder _button(String key, {Locale locale = AppConstants.turkishLocale}) =>
    find.widgetWithText(AppButton, _copy(key, locale: locale));

Finder _buttonForSubmission() => find.byType(AppButton);

Finder _switch(String key) => find.widgetWithText(SwitchListTile, _copy(key));

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is AppTextField && widget.label == label,
);

TextEditingController _controller(WidgetTester tester, String label) =>
    tester.widget<AppTextField>(_field(label)).controller!;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = _field(label);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

Future<void> _submitExpect(
  WidgetTester tester,
  LessonListingFailureType type,
) async {
  await _tap(tester, _button('submit'));
  expect(find.text(_copy('errors.${type.name}')), findsOneWidget);
  expect(find.byType(CreateLessonListingPage), findsOneWidget);
}
