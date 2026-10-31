import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/app.dart';
import 'package:privatelesson/core/constants/app_assets.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text_field.dart';
import 'package:privatelesson/core/widgets/language_switcher_button.dart';
import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:privatelesson/features/auth/presentation/pages/login_page.dart';
import 'package:privatelesson/features/auth/presentation/pages/register_page.dart';
import 'package:privatelesson/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/lesson_listings_page.dart';

import '../../../../helpers/auth_test_app.dart';

const _session = AuthSession(userId: 'test-user', displayName: 'Test User');
const _turkish = Locale('tr');
const _english = Locale('en');
const Map<AuthFailureType, String> _failureKeys = {
  AuthFailureType.invalidDisplayName: 'invalidDisplayName',
  AuthFailureType.invalidEmail: 'invalidEmail',
  AuthFailureType.weakPassword: 'weakPassword',
  AuthFailureType.passwordMismatch: 'passwordMismatch',
  AuthFailureType.invalidCredentials: 'invalidCredentials',
  AuthFailureType.emailAlreadyInUse: 'emailAlreadyInUse',
  AuthFailureType.cancelled: 'cancelled',
  AuthFailureType.connection: 'connection',
  AuthFailureType.authentication: 'authentication',
  AuthFailureType.profileLoading: 'profileLoading',
};

/// Exercises login with real use cases and cubits over a fake repository.
void main() {
  configureTestLocalization();

  testWidgets('shows the registered brand asset with an accessible fallback', (
    tester,
  ) async {
    await pumpAuthApp(tester, createTestAuthCubit());
    expect(find.byType(AuthBrandHeader), findsOneWidget);
    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, AppAssets.appLogo);
    expect(logo.width, AppDimensions.logoSize);
    expect(logo.height, AppDimensions.logoSize);
    expect(logo.fit, BoxFit.cover);
    expect(logo.semanticLabel, translationSection(_turkish, 'app')['title']);
    final fallback = logo.errorBuilder!(
      tester.element(find.byType(Image)),
      const FormatException('Invalid image'),
      StackTrace.current,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: fallback)));
    final emblem = tester.widget<Icon>(find.byIcon(Icons.school_outlined));
    expect(emblem.semanticLabel, translationSection(_turkish, 'app')['title']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'email sign-in submits normalized credentials and resolves profile',
    (tester) async {
      final repository = _FakeAuthRepository();
      final cubit = _createCubit(repository);
      await pumpAuthApp(tester, cubit);
      await tester.enterText(
        find.byType(AppTextField).at(0),
        ' Ada@Example.com ',
      );
      await tester.enterText(find.byType(AppTextField).at(1), ' secret ');
      final button = find.widgetWithText(
        AppButton,
        _authCopy(_turkish)['signInWithEmail'] as String,
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(repository.email, 'Ada@Example.com');
      expect(repository.password, ' secret ');
      expect(find.byType(CompleteProfilePage), findsOneWidget);
    },
  );

  testWidgets('registration navigation clears the current login failure', (
    tester,
  ) async {
    final cubit = createTestAuthCubit();
    final router = await pumpAuthApp(tester, cubit);
    final copy = _authCopy(_turkish);
    final signIn = find.widgetWithText(
      AppButton,
      copy['signInWithEmail'] as String,
    );
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pumpAndSettle();
    expect(cubit.state, isA<AuthFailureState>());
    final register = find.widgetWithText(
      AppButton,
      copy['goToRegister'] as String,
    );
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.registerPath,
    );
    expect(cubit.state, isA<AuthUnauthenticated>());
  });

  testWidgets('initial state offers sign-in without starting it', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final cubit = _createCubit(repository);
    await pumpAuthApp(tester, cubit);

    final copy = _authCopy(_turkish);
    expect(find.text(copy['loginTitle'] as String), findsOneWidget);
    expect(find.text(copy['signInWithGoogle'] as String), findsOneWidget);
    expect(cubit.state, isA<AuthInitial>());
    expect(repository.signInCalls, 0);
    expect(tester.widget<AppButton>(_googleButton()).isLoading, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('signed-out state offers sign-in again', (tester) async {
    final repository = _FakeAuthRepository();
    final cubit = _createCubit(repository);
    await cubit.signOut();
    await pumpAuthApp(tester, cubit);

    expect(cubit.state, isA<AuthUnauthenticated>());
    expect(_googleButton(), findsOneWidget);
    expect(
      tester
          .widget<CupertinoButton>(
            find.descendant(
              of: _googleButton(),
              matching: find.byType(CupertinoButton),
            ),
          )
          .onPressed,
      isNotNull,
    );

    await tester.ensureVisible(_googleButton());
    await tester.tap(_googleButton());
    await tester.pumpAndSettle();

    expect(repository.signInCalls, 1);
    expect(find.byType(CompleteProfilePage), findsOneWidget);
  });

  testWidgets('tap calls cubit, disables loading button, then navigates', (
    tester,
  ) async {
    final completion = Completer<AuthSession>();
    final repository = _FakeAuthRepository(onSignIn: () => completion.future);
    final cubit = _createCubit(repository);
    final router = await pumpAuthApp(tester, cubit);
    final semantics = tester.ensureSemantics();
    try {
      await tester.ensureVisible(_googleButton());
      await tester.tap(_googleButton());
      await tester.pump();

      expect(repository.signInCalls, 1);
      expect(
        tester
            .widgetList<AppTextField>(find.byType(AppTextField))
            .every((field) => !field.enabled),
        isTrue,
      );
      expect(cubit.state, isA<AuthLoading>());
      expect(
        tester
            .widget<AppButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is AppButton &&
                    widget.variant == AppButtonVariant.primary,
              ),
            )
            .isLoading,
        isTrue,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<CupertinoButton>(
              find.descendant(
                of: _googleButton(),
                matching: find.byType(CupertinoButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.bySemanticsLabel(_authCopy(_turkish)['signingIn'] as String),
        findsOneWidget,
      );

      await tester.ensureVisible(_googleButton());
      await tester.tap(_googleButton());
      expect(repository.signInCalls, 1);

      router.go(AppRoutes.homePath);
      await tester.pump();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.loginPath,
      );
      expect(find.byType(LessonListingsPage), findsNothing);

      completion.complete(_session);
      await tester.pumpAndSettle();

      expect(cubit.state, isA<AuthProfileIncomplete>());
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.completeProfilePath,
      );
      expect(find.byType(CompleteProfilePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  for (final locale in AppConstants.supportedLocales) {
    for (final credentials in [
      (email: 'invalid', password: 'secret', error: 'invalidEmail'),
      (email: 'ada@example.com', password: 'short', error: 'weakPassword'),
      (
        email: 'missing@example.com',
        password: 'secret',
        error: 'invalidCredentials',
      ),
    ]) {
      testWidgets(
        '${locale.languageCode} email login shows ${credentials.error}',
        (tester) async {
          final cubit = createTestAuthCubit();
          final router = await pumpAuthApp(tester, cubit, locale: locale);
          final copy = _authCopy(locale);
          await tester.enterText(
            find.byType(AppTextField).at(0),
            credentials.email,
          );
          await tester.enterText(
            find.byType(AppTextField).at(1),
            credentials.password,
          );
          final button = find.widgetWithText(
            AppButton,
            copy['signInWithEmail'] as String,
          );
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(
            find.text(
              (copy['errors'] as Map<String, dynamic>)[credentials.error]
                  as String,
            ),
            findsOneWidget,
          );
          expect(
            router.routeInformationProvider.value.uri.path,
            AppRoutes.loginPath,
          );
        },
      );
    }
    for (final entry in _failureKeys.entries) {
      testWidgets('${locale.languageCode} shows only ${entry.value} failure', (
        tester,
      ) async {
        final repository = _FakeAuthRepository(
          onSignIn: () => Future<AuthSession>.error(AuthFailure(entry.key)),
        );
        final cubit = _createCubit(repository);
        final router = await pumpAuthApp(tester, cubit, locale: locale);
        final messages = _authCopy(locale)['errors'] as Map<String, dynamic>;
        expect(
          messages.values.toSet(),
          hasLength(AuthFailureType.values.length),
        );

        await tester.ensureVisible(_googleButton());
        await tester.tap(_googleButton());
        await tester.pumpAndSettle();

        expect(
          cubit.state,
          isA<AuthFailureState>().having(
            (state) => state.type,
            'type',
            entry.key,
          ),
        );
        expect(find.text(messages[entry.value] as String), findsOneWidget);
        for (final other in _failureKeys.values.where(
          (key) => key != entry.value,
        )) {
          expect(find.text(messages[other] as String), findsNothing);
        }
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          tester
              .widget<CupertinoButton>(
                find.descendant(
                  of: _googleButton(),
                  matching: find.byType(CupertinoButton),
                ),
              )
              .onPressed,
          isNotNull,
        );
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.loginPath,
        );
        router.go(AppRoutes.completeProfilePath);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.loginPath,
        );
      });
    }
  }

  testWidgets('failure can be retried successfully', (tester) async {
    var attempts = 0;
    final repository = _FakeAuthRepository(
      onSignIn: () async {
        attempts += 1;
        if (attempts == 1) {
          throw const AuthFailure(AuthFailureType.connection);
        }
        return _session;
      },
    );
    final cubit = _createCubit(repository);
    await pumpAuthApp(tester, cubit);

    await tester.ensureVisible(_googleButton());
    await tester.tap(_googleButton());
    await tester.pumpAndSettle();
    expect(cubit.state, isA<AuthFailureState>());

    await tester.ensureVisible(_googleButton());
    await tester.tap(_googleButton());
    await tester.pumpAndSettle();

    expect(repository.signInCalls, 2);
    expect(find.byType(CompleteProfilePage), findsOneWidget);
  });

  testWidgets('changing locale refreshes title, action and current failure', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(
      onSignIn: () => Future<AuthSession>.error(
        const AuthFailure(AuthFailureType.connection),
      ),
    );
    final cubit = _createCubit(repository);
    await pumpAuthApp(tester, cubit);
    await tester.ensureVisible(_googleButton());
    await tester.tap(_googleButton());
    await tester.pumpAndSettle();
    final previousState = cubit.state;
    final turkish = _authCopy(_turkish);
    final english = _authCopy(_english);
    final turkishErrors = turkish['errors'] as Map<String, dynamic>;
    final englishErrors = english['errors'] as Map<String, dynamic>;
    expect(find.text(turkishErrors['connection'] as String), findsOneWidget);

    await tester.tap(find.byType(LanguageSwitcherButton));
    await tester.pumpAndSettle();

    expect(find.text(english['loginTitle'] as String), findsOneWidget);
    expect(find.text(english['signInWithGoogle'] as String), findsOneWidget);
    expect(find.text(englishErrors['connection'] as String), findsOneWidget);
    expect(find.text(turkish['loginTitle'] as String), findsNothing);
    expect(find.text(turkish['signInWithGoogle'] as String), findsNothing);
    expect(find.text(turkishErrors['connection'] as String), findsNothing);
    expect(cubit.state, same(previousState));
    expect(repository.signInCalls, 1);
  });

  testWidgets(
    'app preserves cubit and router across language changes and signs in again',
    (
      tester,
    ) async {
      await tester.pumpWidget(localizedApp(child: const App()));
      await tester.pumpAndSettle();

      final loginContext = tester.element(find.byType(LoginPage));
      final router = GoRouter.of(loginContext);
      final cubit = loginContext.read<AuthCubit>();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.loginPath,
      );

      await tester.ensureVisible(_googleButton());
      await tester.tap(_googleButton());
      await tester.pumpAndSettle();

      expect(find.byType(CompleteProfilePage), findsOneWidget);
      expect(cubit.state, isA<AuthProfileIncomplete>());
      expect(
        tester.element(find.byType(CompleteProfilePage)).read<AuthCubit>(),
        same(cubit),
      );
      expect(cubit.isClosed, isFalse);
      final incomplete = cubit.state;
      await tester.tap(find.byType(LanguageSwitcherButton));
      await tester.pumpAndSettle();
      final profileContext = tester.element(find.byType(CompleteProfilePage));
      expect(profileContext.read<AuthCubit>(), same(cubit));
      expect(GoRouter.of(profileContext), same(router));
      expect(cubit.state, same(incomplete));

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      final authenticated = cubit.state as AuthAuthenticated;
      expect(find.byType(LessonListingsPage), findsOneWidget);
      await tester.tap(find.byType(LanguageSwitcherButton));
      await tester.pumpAndSettle();
      expect(cubit.state, same(authenticated));
      expect(
        GoRouter.of(tester.element(find.byType(LessonListingsPage))),
        same(router),
      );
      await tester.tap(
        find.byTooltip(_authCopy(_turkish)['signOut'] as String),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(_googleButton());
      await tester.tap(_googleButton());
      await tester.pumpAndSettle();
      expect(find.byType(LessonListingsPage), findsOneWidget);
      expect(find.byType(CompleteProfilePage), findsNothing);
      expect(
        (cubit.state as AuthAuthenticated).profile.role,
        authenticated.profile.role,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(cubit.isClosed, isTrue);
    },
  );
}

AuthCubit _createCubit(AuthRepository repository) =>
    createTestAuthCubit(authRepository: repository);

Map<String, dynamic> _authCopy(Locale locale) {
  final copy = translationSection(locale, 'auth');
  final errors = copy['errors'] as Map<String, dynamic>;
  errors['weakPassword'] = (errors['weakPassword'] as String).replaceAll(
    '{minLength}',
    AppConstants.minPasswordLength.toString(),
  );
  return copy;
}

Finder _googleButton() => find.byWidgetPredicate(
  (widget) =>
      widget is AppButton &&
      AppConstants.supportedLocales.any(
        (locale) => widget.label == _authCopy(locale)['signInWithGoogle'],
      ),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({Future<AuthSession> Function()? onSignIn})
    : _onSignIn = onSignIn;

  final Future<AuthSession> Function()? _onSignIn;

  String? email;
  String? password;

  /// Counts calls made through the real cubit and sign-in use case.
  int signInCalls = 0;

  /// Returns the configured response or a successful session.
  @override
  Future<AuthSession> signInWithGoogle() {
    signInCalls += 1;
    return _onSignIn?.call() ?? Future<AuthSession>.value(_session);
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) {
    this.email = email;
    this.password = password;
    return signInWithGoogle();
  }

  @override
  Future<AuthSession> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) => signInWithGoogle();

  /// Completes sign-out without accessing a provider.
  @override
  Future<void> signOut() async {}
}
