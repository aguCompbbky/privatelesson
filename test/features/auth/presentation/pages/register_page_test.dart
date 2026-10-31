import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text_field.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:privatelesson/features/auth/presentation/pages/login_page.dart';
import 'package:privatelesson/features/auth/presentation/pages/register_page.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/lesson_listings_page.dart';

import '../../../../helpers/auth_test_app.dart';

/// Exercises registration, profile gating, stored roles and bilingual feedback.
void main() {
  configureTestLocalization();

  for (final locale in AppConstants.supportedLocales) {
    final copy = translationSection(locale, 'auth');
    final errors = copy['errors'] as Map<String, dynamic>;
    final cases = [
      (
        name: '',
        email: 'ada@example.com',
        password: 'secret',
        confirmation: 'secret',
        error: 'invalidDisplayName',
      ),
      (
        name: 'Ada',
        email: 'invalid',
        password: 'secret',
        confirmation: 'secret',
        error: 'invalidEmail',
      ),
      (
        name: 'Ada',
        email: 'ada@example.com',
        password: 'short',
        confirmation: 'short',
        error: 'weakPassword',
      ),
      (
        name: 'Ada',
        email: 'ada@example.com',
        password: 'secret',
        confirmation: 'different',
        error: 'passwordMismatch',
      ),
    ];
    for (final value in cases) {
      testWidgets('${locale.languageCode} validates ${value.error}', (
        tester,
      ) async {
        final cubit = createTestAuthCubit();
        final router = await pumpAuthApp(tester, cubit, locale: locale);
        router.go(AppRoutes.registerPath);
        await tester.pumpAndSettle();
        await _fill(
          tester,
          name: value.name,
          email: value.email,
          password: value.password,
          confirmation: value.confirmation,
        );
        await _tap(tester, copy['registerAction'] as String);
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.registerPath,
        );
        final message = (errors[value.error] as String).replaceAll(
          '{minLength}',
          AppConstants.minPasswordLength.toString(),
        );
        expect(find.text(message), findsOneWidget);
        expect(find.byType(CompleteProfilePage), findsNothing);
        expect(
          tester
              .widget<AppTextField>(find.byType(AppTextField).at(1))
              .controller
              ?.text,
          value.email,
        );
      });
    }
    testWidgets('${locale.languageCode} reports duplicate email', (
      tester,
    ) async {
      final cubit = createTestAuthCubit();
      await cubit.registerWithEmail(
        displayName: 'Ada',
        email: 'ada@example.com',
        password: 'secret',
        confirmPassword: 'secret',
      );
      await cubit.signOut();
      final router = await pumpAuthApp(tester, cubit, locale: locale);
      router.go(AppRoutes.registerPath);
      await tester.pumpAndSettle();
      await _fill(tester, email: 'ADA@example.com');
      await _tap(tester, copy['registerAction'] as String);
      expect(find.text(errors['emailAlreadyInUse'] as String), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.registerPath,
      );
    });
  }

  for (final role in UserRole.values) {
    testWidgets(
      'registers ${role.name} and returns without repeating role choice',
      (tester) async {
        final cubit = createTestAuthCubit();
        final router = await pumpAuthApp(tester, cubit);
        final copy = translationSection(AppConstants.turkishLocale, 'auth');
        final profileCopy = translationSection(
          AppConstants.turkishLocale,
          'profile',
        );
        await _tap(tester, copy['goToRegister'] as String);
        expect(find.byType(RegisterPage), findsOneWidget);
        await _fill(
          tester,
          name: '  Ada Lovelace  ',
          email: ' Ada@Example.com ',
        );
        await _tap(tester, copy['registerAction'] as String);
        expect(find.byType(CompleteProfilePage), findsOneWidget);
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.completeProfilePath,
        );
        final incomplete = cubit.state as AuthProfileIncomplete;
        expect(incomplete.displayName, 'Ada Lovelace');
        router.go(AppRoutes.registerPath);
        await tester.pumpAndSettle();
        expect(find.byType(CompleteProfilePage), findsOneWidget);
        final roles = profileCopy['roles'] as Map<String, dynamic>;
        await tester.tap(find.text(roles[role.name] as String));
        await _tap(tester, profileCopy['save'] as String);
        expect(find.byType(LessonListingsPage), findsOneWidget);
        expect((cubit.state as AuthAuthenticated).profile.role, role);
        for (final path in [
          AppRoutes.loginPath,
          AppRoutes.registerPath,
          AppRoutes.completeProfilePath,
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(
            router.routeInformationProvider.value.uri.path,
            AppRoutes.homePath,
          );
        }
        await tester.tap(find.byTooltip(copy['signOut'] as String));
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);
        await tester.enterText(
          find.byType(AppTextField).at(0),
          'ada@example.com',
        );
        await tester.enterText(find.byType(AppTextField).at(1), 'secret');
        final states = <AuthState>[];
        final subscription = cubit.stream.listen(states.add);
        addTearDown(subscription.cancel);
        await _tap(tester, copy['signInWithEmail'] as String);
        expect(states, [isA<AuthLoading>(), isA<AuthAuthenticated>()]);
        expect(find.byType(LessonListingsPage), findsOneWidget);
        expect(find.byType(CompleteProfilePage), findsNothing);
        final authenticated = cubit.state as AuthAuthenticated;
        expect(authenticated.session.userId, incomplete.session.userId);
        expect(authenticated.profile.role, role);
        expect(authenticated.profile.displayName, 'Ada Lovelace');
      },
    );
  }

  for (final toolbarBack in [false, true]) {
    testWidgets('return action $toolbarBack clears stale registration errors', (
      tester,
    ) async {
      final cubit = createTestAuthCubit();
      final router = await pumpAuthApp(tester, cubit);
      router.go(AppRoutes.registerPath);
      await tester.pumpAndSettle();
      final copy = translationSection(AppConstants.turkishLocale, 'auth');
      await _tap(tester, copy['registerAction'] as String);
      expect(cubit.state, isA<AuthFailureState>());
      if (toolbarBack) {
        await tester.tap(find.byTooltip(copy['backToLogin'] as String));
        await tester.pumpAndSettle();
      } else {
        await _tap(tester, copy['backToLogin'] as String);
      }
      expect(cubit.state, isA<AuthUnauthenticated>());
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.loginPath,
      );
    });
  }

  testWidgets('language switching preserves registration input and error', (
    tester,
  ) async {
    final cubit = createTestAuthCubit();
    final router = await pumpAuthApp(tester, cubit);
    router.go(AppRoutes.registerPath);
    await tester.pumpAndSettle();
    final turkish = translationSection(AppConstants.turkishLocale, 'auth');
    final english = translationSection(AppConstants.englishLocale, 'auth');
    await _fill(tester, confirmation: 'mismatch');
    await _tap(tester, turkish['registerAction'] as String);
    final previous = cubit.state;
    await tester.tap(find.byType(LanguageSwitcherButton));
    await tester.pumpAndSettle();
    expect(find.text(english['registerTitle'] as String), findsOneWidget);
    expect(
      find.text(english['confirmPasswordLabel'] as String),
      findsOneWidget,
    );
    expect(
      find.text(
        (english['errors'] as Map<String, dynamic>)['passwordMismatch']
            as String,
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppTextField>(find.byType(AppTextField).at(3))
          .controller
          ?.text,
      'mismatch',
    );
    expect(cubit.state, same(previous));
  });

  testWidgets('pending registration disables fields and announces progress', (
    tester,
  ) async {
    final completion = Completer<AuthSession>();
    final repository = _PendingRepository(completion);
    final cubit = createTestAuthCubit(authRepository: repository);
    final router = await pumpAuthApp(tester, cubit);
    router.go(AppRoutes.registerPath);
    await tester.pumpAndSettle();
    final copy = translationSection(AppConstants.turkishLocale, 'auth');
    await _fill(tester);
    final button = find.widgetWithText(
      AppButton,
      copy['registerAction'] as String,
    );
    await tester.ensureVisible(button);
    final semantics = tester.ensureSemantics();
    try {
      await tester.tap(button);
      await tester.pump();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.registerPath,
      );
      expect(
        tester
            .widgetList<AppTextField>(find.byType(AppTextField))
            .every((field) => !field.enabled),
        isTrue,
      );
      expect(
        find.bySemanticsLabel(copy['registering'] as String),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.arrow_back),
            )
            .onPressed,
        isNull,
      );
      final buttons = tester.widgetList<AppButton>(find.byType(AppButton));
      expect(buttons.first.isLoading, isTrue);
      expect(buttons.last.onPressed, isNull);
      expect(repository.calls, 1);
      completion.complete(const AuthSession(userId: 'new', displayName: 'Ada'));
      await tester.pumpAndSettle();
      expect(find.byType(CompleteProfilePage), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _fill(
  WidgetTester tester, {
  String name = 'Ada',
  String email = 'ada@example.com',
  String password = 'secret',
  String confirmation = 'secret',
}) async {
  final values = [name, email, password, confirmation];
  for (var index = 0; index < values.length; index++) {
    await tester.enterText(find.byType(AppTextField).at(index), values[index]);
  }
}

Future<void> _tap(WidgetTester tester, String label) async {
  final button = find.widgetWithText(AppButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

class _PendingRepository implements AuthRepository {
  _PendingRepository(this.completion);
  final Completer<AuthSession> completion;
  int calls = 0;

  @override
  Future<AuthSession> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) {
    calls += 1;
    return completion.future;
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AuthSession> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}
