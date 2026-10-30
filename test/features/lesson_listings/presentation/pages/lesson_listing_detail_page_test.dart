import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/platform_external_contact_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/repositories/external_contact_repository_impl.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_state.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/lesson_listing_detail_page.dart';

import '../../../../helpers/auth_test_app.dart';
import '../../../../helpers/lesson_listings_test_support.dart';

void main() {
  configureTestLocalization();

  for (final contact in const [
    TeacherContactInfo(whatsAppNumber: '+905550000001'),
    TeacherContactInfo(emailAddress: 'teacher@example.invalid'),
    TeacherContactInfo(
      whatsAppNumber: '+905550000001',
      emailAddress: 'teacher@example.invalid',
    ),
  ]) {
    testWidgets(
      'shared channels: WhatsApp ${contact.hasWhatsApp}, '
      'email ${contact.hasEmail}',
      (tester) async {
        final cubit = testDetailCubit(
          repository: TestLessonRepository(
            onDetail: (_) async => testListing(contact: contact),
          ),
        );
        await pumpListingsApp(
          tester,
          listingId: cubit.listingId,
          createDetail: (_) => cubit,
        );
        expect(find.byType(LessonListingDetailPage), findsOneWidget);
        expect(
          find.widgetWithText(AppButton, listingCopy('contact.whatsApp')),
          contact.hasWhatsApp ? findsOneWidget : findsNothing,
        );
        expect(
          find.widgetWithText(AppButton, listingCopy('contact.email')),
          contact.hasEmail ? findsOneWidget : findsNothing,
        );
        expect(find.text(listingCopy('contact.copy')), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  }

  for (final settle in [false, true]) {
    testWidgets(
      'opens detail with pending parent listings, settle: $settle',
      (tester) async {
        final completion = Completer<List<LessonListing>>();
        final listings = testListingsCubit(
          repository: TestLessonRepository(onList: (_) => completion.future),
        );
        final detail = testDetailCubit();
        try {
          final router = await pumpListingsApp(
            tester,
            listingId: detail.listingId,
            createListings: () => listings,
            createDetail: (_) => detail,
            settle: settle,
          );
          expect(
            router.routeInformationProvider.value.uri.path,
            AppRoutes.listingDetailPath(detail.listingId),
          );
          expect(find.byType(LessonListingDetailPage), findsOneWidget);
          expect(find.text('Matematik'), findsOneWidget);
          expect(detail.state.listing!.id, detail.listingId);
          expect(listings.state.isLoading, isTrue);
          expect(completion.isCompleted, isFalse);
        } finally {
          completion.complete([testListing()]);
          await tester.pumpAndSettle();
        }
        expect(listings.state.isLoading, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  }

  for (final hasCertificate in [false, true]) {
    testWidgets(
      'declares certificate: $hasCertificate',
      (tester) async {
        final listing = testListing(hasCertificate: hasCertificate);
        final certificateKey = hasCertificate
            ? 'certificateAvailable'
            : 'certificateNotProvided';
        final cubit = testDetailCubit(
          repository: TestLessonRepository(onDetail: (_) async => listing),
        );
        await pumpListingsApp(
          tester,
          listingId: cubit.listingId,
          createDetail: (_) => cubit,
        );
        for (final locale in AppConstants.supportedLocales) {
          expect(find.text(listing.subject), findsOneWidget);
          expect(find.text(listing.teacherName), findsOneWidget);
          expect(find.text(listing.description), findsOneWidget);
          expect(
            find.text(
              listingCopy(certificateKey, locale: locale),
            ),
            findsOneWidget,
          );
          expect(
            find.text('Öğretmenlik diploması'),
            hasCertificate ? findsOneWidget : findsNothing,
          );
          expect(
            find.textContaining(
              RegExp('verified|doğrulanmış', caseSensitive: false),
            ),
            findsNothing,
          );
          if (locale == AppConstants.turkishLocale) {
            await tester.tap(find.byType(LanguageSwitcherButton));
            await tester.pumpAndSettle();
          }
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  }

  for (final channel in ContactChannel.values) {
    testWidgets(
      '$channel failure copies its value',
      (tester) async {
        String? clipboard;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard =
                  (call.arguments as Map<Object?, Object?>)['text']! as String;
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });
        final cubit = testDetailCubit(
          contacts: const ExternalContactRepositoryImpl(
            PlatformExternalContactDataSource(),
          ),
        );
        await pumpListingsApp(
          tester,
          listingId: cubit.listingId,
          createDetail: (_) => cubit,
        );
        final key = channel == ContactChannel.whatsApp
            ? 'contact.whatsApp'
            : 'contact.email';
        final value = channel == ContactChannel.whatsApp
            ? '+905550000001'
            : 'teacher@example.invalid';
        await tester.tap(find.widgetWithText(AppButton, listingCopy(key)));
        await tester.pumpAndSettle();
        expect(
          find.text(listingCopy('contact.errors.cannotOpenExternalApp')),
          findsOneWidget,
        );
        expect(find.text(value), findsOneWidget);
        expect(cubit.state.contactState!.channel, channel);
        expect(clipboard, isNull);
        await tester.ensureVisible(find.text(listingCopy('contact.copy')));
        await tester.tap(
          find.widgetWithText(AppButton, listingCopy('contact.copy')),
        );
        await tester.pumpAndSettle();
        expect(clipboard, value);
        expect(find.text(listingCopy('contact.copied')), findsOneWidget);
        expect(find.text(listingCopy('contact.copy')), findsNothing);
        expect(cubit.state.contactState!.isCopied, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  }

  testWidgets(
    'retries failed clipboard access',
    (tester) async {
      var failCopy = true;
      String? clipboard;
      final cubit = testDetailCubit(
        contacts: ExternalContactRepositoryImpl(
          PlatformExternalContactDataSource(
            clipboardWriter: (text) async {
              if (failCopy) {
                throw PlatformException(code: 'clipboard-unavailable');
              }
              clipboard = text;
            },
          ),
        ),
      );
      await pumpListingsApp(
        tester,
        listingId: cubit.listingId,
        createDetail: (_) => cubit,
      );
      await tester.tap(
        find.widgetWithText(AppButton, listingCopy('contact.email')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(AppButton, listingCopy('contact.copy')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(listingCopy('contact.errors.clipboardFailed')),
        findsOneWidget,
      );
      expect(find.text('teacher@example.invalid'), findsOneWidget);
      expect(find.text(listingCopy('contact.copied')), findsNothing);
      failCopy = false;
      await tester.tap(
        find.widgetWithText(AppButton, listingCopy('contact.copy')),
      );
      await tester.pumpAndSettle();
      expect(clipboard, 'teacher@example.invalid');
      expect(find.text(listingCopy('contact.copied')), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets(
    'offers copying for invalid contacts',
    (tester) async {
      final cubit = testDetailCubit(
        repository: TestLessonRepository(
          onDetail: (_) async => testListing(
            contact: const TeacherContactInfo(emailAddress: 'invalid-address'),
          ),
        ),
      );
      await pumpListingsApp(
        tester,
        listingId: cubit.listingId,
        createDetail: (_) => cubit,
      );
      await tester.tap(
        find.widgetWithText(AppButton, listingCopy('contact.email')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(listingCopy('contact.errors.invalidContactValue')),
        findsOneWidget,
      );
      expect(find.text('invalid-address'), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, listingCopy('contact.copy')),
        findsOneWidget,
      );
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets('announces pending detail', (tester) async {
    final completion = Completer<LessonListing>();
    final cubit = testDetailCubit(
      repository: TestLessonRepository(onDetail: (_) => completion.future),
    );
    final semantics = tester.ensureSemantics();
    try {
      await pumpListingsApp(
        tester,
        listingId: cubit.listingId,
        createDetail: (_) => cubit,
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.bySemanticsLabel(listingCopy('detailLoading')),
        findsOneWidget,
      );
      completion.complete(testListing());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Matematik'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 10)));

  for (final type in [
    LessonListingFailureType.notFound,
    LessonListingFailureType.connection,
    LessonListingFailureType.storage,
  ]) {
    testWidgets(
      '$type displays feedback and retry',
      (tester) async {
        final repository = TestLessonRepository(
          onDetail: (_) => Future.error(LessonListingFailure(type)),
        );
        final cubit = testDetailCubit(repository: repository);
        await pumpListingsApp(
          tester,
          listingId: cubit.listingId,
          createDetail: (_) => cubit,
        );
        expect(find.text(listingCopy('errors.${type.name}')), findsOneWidget);
        expect(find.text(listingCopy('contact.email')), findsNothing);
        await tester.tap(find.byType(LanguageSwitcherButton));
        await tester.pumpAndSettle();
        expect(
          find.text(
            listingCopy(
              'errors.${type.name}',
              locale: AppConstants.englishLocale,
            ),
          ),
          findsOneWidget,
        );
        repository.onDetail = null;
        await tester.tap(
          find.widgetWithText(
            AppButton,
            listingCopy('retry', locale: AppConstants.englishLocale),
          ),
        );
        await tester.pumpAndSettle();
        expect(repository.requestedIds, [cubit.listingId, cubit.listingId]);
        expect(find.text('Matematik'), findsOneWidget);
        expect(cubit.state.failureType, isNull);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  }

  testWidgets(
    'translates detail and contact feedback',
    (tester) async {
      final contacts = TestContactRepository(
        onOpen: (_) => Future.error(
          const ExternalContactFailure(
            ExternalContactFailureType.cannotOpenExternalApp,
          ),
        ),
      );
      final cubit = testDetailCubit(contacts: contacts);
      await pumpListingsApp(
        tester,
        listingId: cubit.listingId,
        createDetail: (_) => cubit,
      );
      await tester.tap(
        find.widgetWithText(AppButton, listingCopy('contact.whatsApp')),
      );
      await tester.pumpAndSettle();
      final previous = cubit.state;
      await tester.tap(find.byType(LanguageSwitcherButton));
      await tester.pumpAndSettle();
      for (final key in [
        'detailTitle',
        'description',
        'certificateAvailable',
        'contact.title',
        'contact.whatsApp',
        'contact.email',
        'contact.errors.cannotOpenExternalApp',
        'contact.copy',
      ]) {
        expect(
          find.text(listingCopy(key, locale: AppConstants.englishLocale)),
          findsOneWidget,
        );
        expect(find.text(listingCopy(key)), findsNothing);
      }
      expect(cubit.state, same(previous));
      expect(find.text('+905550000001'), findsOneWidget);
      expect(
        find.byTooltip(listingCopy('back', locale: AppConstants.englishLocale)),
        findsOneWidget,
      );
      await tester.tap(
        find.widgetWithText(
          AppButton,
          listingCopy('contact.copy', locale: AppConstants.englishLocale),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          listingCopy('contact.copied', locale: AppConstants.englishLocale),
        ),
        findsOneWidget,
      );
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets(
    'replaces detail cubit when the route identifier changes',
    (
      tester,
    ) async {
      final first = testDetailCubit(listingId: 'first');
      final second = testDetailCubit(listingId: 'second');
      final requestedIds = <String>[];
      final router = await pumpListingsApp(
        tester,
        listingId: first.listingId,
        createDetail: (id) {
          requestedIds.add(id);
          return id == first.listingId ? first : second;
        },
      );
      expect(first.state.listing!.id, first.listingId);
      router.go(AppRoutes.listingDetailPath(second.listingId));
      await tester.pumpAndSettle();
      expect(requestedIds, [first.listingId, second.listingId]);
      expect(first.isClosed, isTrue);
      expect(second.isClosed, isFalse);
      expect(second.state.listing!.id, second.listingId);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets('guards the detail route', (tester) async {
    final auth = createTestAuthCubit();
    final router = await pumpAuthApp(tester, auth);
    router.go(AppRoutes.listingDetailPath('mock-lesson-1'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.loginPath);
    unawaited(auth.signInWithGoogle());
    router.go(AppRoutes.listingDetailPath('mock-lesson-1'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.completeProfilePath,
    );
    expect(find.byType(LessonListingDetailPage), findsNothing);
  }, timeout: const Timeout(Duration(seconds: 10)));
}
