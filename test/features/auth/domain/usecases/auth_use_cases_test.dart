import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';
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

enum _RepositoryCall { signIn, signOut }

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failure, this.signOutCompletion});

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
