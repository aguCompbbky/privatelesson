import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text_field.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:privatelesson/features/auth/presentation/pages/login_page.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/lesson_listings_page.dart';

import '../../../../helpers/auth_test_app.dart';

const Locale _turkish = AppConstants.turkishLocale;
const Locale _english = AppConstants.englishLocale;
const _chosenName = 'Chosen Name';

/// Exercises profile gating, role persistence, validation and live translation.
void main() {
  configureTestLocalization();

  testWidgets('first login requires completion and blocks all other paths', (
    tester,
  ) async {
    final cubit = createTestAuthCubit();
    final router = await pumpAuthApp(tester, cubit);
    for (final path in [AppRoutes.homePath, AppRoutes.completeProfilePath]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.loginPath,
      );
      expect(find.byType(LoginPage), findsOneWidget);
    }

    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.completeProfilePath,
    );
    expect(find.byType(CompleteProfilePage), findsOneWidget);
    expect(
      tester.widget<AppTextField>(find.byType(AppTextField)).controller?.text,
      testAuthUser.displayName,
    );
    expect(
      tester
          .widget<SegmentedButton<UserRole>>(
            find.byType(SegmentedButton<UserRole>),
          )
          .selected,
      {UserRole.student},
    );

    for (final path in [AppRoutes.homePath, AppRoutes.loginPath, '/unknown']) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.completeProfilePath,
      );
      expect(find.byType(LessonListingsPage), findsNothing);
    }

    await tester.tap(find.byTooltip(_authCopy(_turkish)['signOut'] as String));
    await tester.pumpAndSettle();
    expect(cubit.state, isA<AuthUnauthenticated>());
    router.go(AppRoutes.homePath);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.loginPath);
  });

  for (final role in UserRole.values) {
    testWidgets(
      'completes ${role.name} and retains role after sign-out and sign-in',
      (
        tester,
      ) async {
        final cubit = createTestAuthCubit();
        final router = await pumpAuthApp(tester, cubit);
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();
        final roles = _profileCopy(_turkish)['roles'] as Map<String, dynamic>;
        await tester.tap(find.text(roles[role.name] as String));
        await tester.enterText(find.byType(AppTextField), _chosenName);
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.homePath,
        );
        expect(find.text(_chosenName), findsOneWidget);
        expect(find.text(roles[role.name] as String), findsOneWidget);
        expect((cubit.state as AuthAuthenticated).profile.role, role);
        for (final path in [
          AppRoutes.loginPath,
          AppRoutes.completeProfilePath,
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(
            router.routeInformationProvider.value.uri.path,
            AppRoutes.homePath,
          );
        }

        await tester.tap(find.byType(LanguageSwitcherButton));
        await tester.pumpAndSettle();
        final englishRoles =
            _profileCopy(_english)['roles'] as Map<String, dynamic>;
        expect(find.text(englishRoles[role.name] as String), findsOneWidget);
        expect(find.text(_chosenName), findsOneWidget);
        await tester.tap(
          find.byTooltip(_authCopy(_english)['signOut'] as String),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);
        final states = <AuthState>[];
        final subscription = cubit.stream.listen(states.add);
        addTearDown(subscription.cancel);

        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(states, [isA<AuthLoading>(), isA<AuthAuthenticated>()]);
        expect(find.byType(CompleteProfilePage), findsNothing);
        expect(find.byType(LessonListingsPage), findsOneWidget);
        expect(find.text(_chosenName), findsOneWidget);
        expect((cubit.state as AuthAuthenticated).profile.role, role);
      },
    );
  }

  testWidgets(
    'blank name stays on form and language changes preserve edits and error',
    (
      tester,
    ) async {
      final cubit = createTestAuthCubit();
      await pumpAuthApp(tester, cubit);
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      final turkish = _profileCopy(_turkish);
      final english = _profileCopy(_english);
      final turkishRoles = turkish['roles'] as Map<String, dynamic>;
      final turkishErrors = turkish['errors'] as Map<String, dynamic>;
      final englishRoles = english['roles'] as Map<String, dynamic>;
      final englishErrors = english['errors'] as Map<String, dynamic>;
      final controller = tester
          .widget<AppTextField>(find.byType(AppTextField))
          .controller;
      await tester.tap(find.text(turkishRoles['teacher'] as String));
      await tester.enterText(find.byType(AppTextField), '   ');
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(
        find.text(turkishErrors['invalidDisplayName'] as String),
        findsOneWidget,
      );
      expect(find.byType(LessonListingsPage), findsNothing);
      final previous = cubit.state;
      await tester.tap(find.byType(LanguageSwitcherButton));
      await tester.pumpAndSettle();

      expect(cubit.state, same(previous));
      expect(
        tester.widget<AppTextField>(find.byType(AppTextField)).controller,
        same(controller),
      );
      expect(controller?.text, '   ');
      expect(find.text(english['title'] as String), findsOneWidget);
      expect(find.text(english['displayName'] as String), findsOneWidget);
      expect(find.text(english['role'] as String), findsOneWidget);
      expect(find.text(english['save'] as String), findsOneWidget);
      expect(find.text(englishRoles['teacher'] as String), findsOneWidget);
      expect(
        find.text(englishErrors['invalidDisplayName'] as String),
        findsOneWidget,
      );
      expect(
        find.text(turkishErrors['invalidDisplayName'] as String),
        findsNothing,
      );
      expect(
        (cubit.state as AuthProfileIncomplete).selectedRole,
        UserRole.teacher,
      );
      expect(
        find.byTooltip(_authCopy(_english)['signOut'] as String),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          translationSection(_english, 'language')['switchToTurkish'] as String,
        ),
        findsOneWidget,
      );

      await tester.enterText(find.byType(AppTextField), _chosenName);
      await tester.pumpAndSettle();
      expect(
        find.text(englishErrors['invalidDisplayName'] as String),
        findsNothing,
      );
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      expect(find.text(_chosenName), findsOneWidget);
      expect((cubit.state as AuthAuthenticated).profile.role, UserRole.teacher);
    },
  );

  for (final locale in AppConstants.supportedLocales) {
    for (final type in ProfileFailureType.values) {
      testWidgets(
        '${locale.languageCode} displays distinct ${type.name} profile failure',
        (
          tester,
        ) async {
          final repository = _ProfileRepository(
            onSave: (_) => Future<UserProfile>.error(ProfileFailure(type)),
          );
          final cubit = createTestAuthCubit(profileRepository: repository);
          await cubit.signInWithGoogle();
          final router = await pumpAuthApp(tester, cubit, locale: locale);

          await tester.tap(find.byType(AppButton));
          await tester.pumpAndSettle();

          final errors = _profileCopy(locale)['errors'] as Map<String, dynamic>;
          expect(
            errors.values.toSet(),
            hasLength(ProfileFailureType.values.length),
          );
          expect(find.text(errors[type.name] as String), findsOneWidget);
          for (final other in ProfileFailureType.values.where(
            (value) => value != type,
          )) {
            expect(find.text(errors[other.name] as String), findsNothing);
          }
          expect(
            router.routeInformationProvider.value.uri.path,
            AppRoutes.completeProfilePath,
          );
          expect(
            tester.widget<AppButton>(find.byType(AppButton)).isLoading,
            isFalse,
          );
        },
      );
    }
  }

  testWidgets('saving disables form and sign-out with accessible progress', (
    tester,
  ) async {
    final completion = Completer<UserProfile>();
    final repository = _ProfileRepository(onSave: (_) => completion.future);
    final cubit = createTestAuthCubit(profileRepository: repository);
    await cubit.signInWithGoogle();
    await pumpAuthApp(tester, cubit);
    final semantics = tester.ensureSemantics();
    try {
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(
        tester.widget<AppButton>(find.byType(AppButton)).isLoading,
        isTrue,
      );
      expect(
        tester.widget<AppTextField>(find.byType(AppTextField)).enabled,
        isFalse,
      );
      expect(
        tester
            .widget<SegmentedButton<UserRole>>(
              find.byType(SegmentedButton<UserRole>),
            )
            .onSelectionChanged,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.logout),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.bySemanticsLabel(_profileCopy(_turkish)['saving'] as String),
        findsOneWidget,
      );
      await tester.tap(find.byType(AppButton));
      expect(repository.saveCalls, 1);
      completion.complete(
        UserProfile(
          userId: testAuthUser.userId,
          displayName: testAuthUser.displayName,
          role: UserRole.student,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LessonListingsPage), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}

Map<String, dynamic> _profileCopy(Locale locale) =>
    translationSection(locale, 'profile');

Map<String, dynamic> _authCopy(Locale locale) =>
    translationSection(locale, 'auth');

class _ProfileRepository implements UserProfileRepository {
  _ProfileRepository({required this.onSave});

  final Future<UserProfile> Function(UserProfile) onSave;
  int saveCalls = 0;

  @override
  Future<UserProfile?> getProfile(String userId) async => null;

  @override
  Future<UserProfile> saveProfile(UserProfile profile) {
    saveCalls += 1;
    return onSave(profile);
  }
}
