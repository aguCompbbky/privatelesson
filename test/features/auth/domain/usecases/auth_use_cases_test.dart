import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';
import 'package:privatelesson/features/auth/domain/usecases/register_with_email_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_out_use_case.dart';

const _session = AuthSession(userId: 'mock-user', displayName: 'Mock User');

/// Verifies that both use cases delegate through the domain contract only.
void main() {
  group('SignInWithGoogleUseCase', () {
    test('calls sign-in once and returns the repository session', () async {
      final repository = _FakeAuthRepository();
      final useCase = SignInWithGoogleUseCase(repository);

      expect(await useCase(), same(_session));
      expect(repository.calls, [_RepositoryCall.signIn]);
    });

    for (final type in AuthFailureType.values) {
      test('preserves the ${type.name} domain failure', () async {
        final failure = AuthFailure(type);
        final repository = _FakeAuthRepository(failure: failure);
        final useCase = SignInWithGoogleUseCase(repository);

        await expectLater(useCase(), throwsA(same(failure)));
        expect(repository.calls, [_RepositoryCall.signIn]);
      });
    }
  });

  group('email validation and normalization', () {
    for (final registering in [false, true]) {
      for (final email in [
        '',
        '  ',
        'example',
        'a@',
        '@example.com',
        'a@example',
        'a b@example.com',
        'a@@example.com',
      ]) {
        test('$registering rejects malformed email: $email', () async {
          final repository = _FakeAuthRepository();
          await expectLater(
            _emailOperation(repository, registering, email: email),
            throwsA(_failure(AuthFailureType.invalidEmail)),
          );
          expect(repository.calls, isEmpty);
        });
      }
      for (final password in [
        '',
        ' ' * (AppConstants.minPasswordLength - 1),
        'a' * (AppConstants.minPasswordLength - 1),
      ]) {
        test(
          '$registering rejects short password of ${password.length}',
          () async {
            final repository = _FakeAuthRepository();
            await expectLater(
              _emailOperation(repository, registering, password: password),
              throwsA(_failure(AuthFailureType.weakPassword)),
            );
            expect(repository.calls, isEmpty);
          },
        );
      }
      for (final password in [
        'a' * AppConstants.minPasswordLength,
        ' secret ',
      ]) {
        test(
          '$registering normalizes identity but preserves $password',
          () async {
            final repository = _FakeAuthRepository();
            expect(
              await _emailOperation(
                repository,
                registering,
                displayName: '  Ada Lovelace  ',
                email: '  Ada@Example.com  ',
                password: password,
                confirmPassword: password,
              ),
              same(_session),
            );
            expect(repository.email, 'Ada@Example.com');
            expect(repository.password, password);
            expect(repository.displayName, registering ? 'Ada Lovelace' : null);
            expect(repository.calls, [
              if (registering)
                _RepositoryCall.register
              else
                _RepositoryCall.email,
            ]);
          },
        );
      }
      for (final type in AuthFailureType.values) {
        test('$registering preserves ${type.name}', () async {
          final failure = AuthFailure(type);
          final repository = _FakeAuthRepository(failure: failure);
          await expectLater(
            _emailOperation(repository, registering),
            throwsA(same(failure)),
          );
          expect(repository.calls, hasLength(1));
        });
      }
    }
    for (final name in ['', '  ', '\t\n']) {
      test('registration rejects blank display name $name first', () async {
        final repository = _FakeAuthRepository();
        await expectLater(
          _emailOperation(
            repository,
            true,
            displayName: name,
            email: '',
            password: '',
          ),
          throwsA(_failure(AuthFailureType.invalidDisplayName)),
        );
        expect(repository.calls, isEmpty);
      });
    }
    for (final confirmation in ['', 'different', 'secret ']) {
      test(
        'registration rejects mismatched confirmation $confirmation',
        () async {
          final repository = _FakeAuthRepository();
          await expectLater(
            _emailOperation(
              repository,
              true,
              confirmPassword: confirmation,
            ),
            throwsA(_failure(AuthFailureType.passwordMismatch)),
          );
          expect(repository.calls, isEmpty);
        },
      );
    }
  });

  group('SignOutUseCase', () {
    test('calls sign-out once without invoking sign-in', () async {
      final repository = _FakeAuthRepository();
      final useCase = SignOutUseCase(repository);

      await useCase();

      expect(repository.calls, [_RepositoryCall.signOut]);
    });

    test('waits for repository sign-out completion', () async {
      final completion = Completer<void>();
      final repository = _FakeAuthRepository(signOutCompletion: completion);
      final useCase = SignOutUseCase(repository);
      var finished = false;
      final result = useCase().then((_) {
        finished = true;
      });

      await Future<void>.value();
      expect(finished, isFalse);
      completion.complete();
      await result;

      expect(finished, isTrue);
      expect(repository.calls, [_RepositoryCall.signOut]);
    });

    for (final type in AuthFailureType.values) {
      test('preserves the ${type.name} domain failure', () async {
        final failure = AuthFailure(type);
        final repository = _FakeAuthRepository(failure: failure);
        final useCase = SignOutUseCase(repository);

        await expectLater(useCase(), throwsA(same(failure)));
        expect(repository.calls, [_RepositoryCall.signOut]);
      });
    }
  });
}

enum _RepositoryCall { signIn, signOut, email, register }

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failure, this.signOutCompletion});

  String? email;
  String? password;
  String? displayName;

  /// The domain failure returned by either operation, if configured.
  final AuthFailure? failure;

  /// Optional completion used to hold sign-out pending.
  final Completer<void>? signOutCompletion;

  /// The ordered operations received by the fake.
  final List<_RepositoryCall> calls = [];

  /// Records sign-in and returns the fixture or configured domain failure.
  @override
  Future<AuthSession> signInWithGoogle() async {
    calls.add(_RepositoryCall.signIn);
    final error = failure;
    if (error != null) {
      throw error;
    }
    return _session;
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    calls.add(_RepositoryCall.email);
    this.email = email;
    this.password = password;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return _session;
  }

  @override
  Future<AuthSession> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    calls.add(_RepositoryCall.register);
    this.displayName = displayName;
    this.email = email;
    this.password = password;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return _session;
  }

  /// Records sign-out and awaits completion or throws the configured failure.
  @override
  Future<void> signOut() async {
    calls.add(_RepositoryCall.signOut);
    final error = failure;
    if (error != null) {
      throw error;
    }
    final completion = signOutCompletion;
    if (completion != null) {
      await completion.future;
    }
  }
}

Matcher _failure(AuthFailureType type) =>
    isA<AuthFailure>().having((value) => value.type, 'type', type);

Future<AuthSession> _emailOperation(
  AuthRepository repository,
  bool registering, {
  String displayName = 'Ada',
  String email = 'ada@example.com',
  String password = 'secret',
  String confirmPassword = 'secret',
}) => registering
    ? RegisterWithEmailUseCase(repository)(
        displayName: displayName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      )
    : SignInWithEmailUseCase(repository)(email: email, password: password);
