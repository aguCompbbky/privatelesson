import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source_exception.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';
import 'package:privatelesson/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';

const _user = AuthUserDto(userId: 'mock-user', displayName: 'Mock User');

/// Verifies DTO conversion, asynchronous delegation and provider error mapping.
void main() {
  group('email repository operations', () {
    for (final registering in [false, true]) {
      test('$registering delegates arguments and converts the DTO', () async {
        final source = _FakeAuthDataSource();
        final session = await _emailOperation(
          AuthRepositoryImpl(source),
          registering,
        );
        expect(session.userId, _user.userId);
        expect(session.displayName, _user.displayName);
        expect(source.email, 'ada@example.com');
        expect(source.password, ' secret ');
        expect(source.displayName, registering ? 'Ada' : null);
        expect(source.calls, [
          if (registering) _DataSourceCall.register else _DataSourceCall.email,
        ]);
      });
      final failures = <Exception, AuthFailureType>{
        for (final code in AuthDataSourceError.values)
          AuthDataSourceException(code): AuthFailureType.values.byName(
            code.name,
          ),
        const FormatException(): AuthFailureType.profileLoading,
        Exception('provider details'): AuthFailureType.authentication,
      };
      for (final entry in failures.entries) {
        test('$registering maps ${entry.key} to ${entry.value.name}', () async {
          await expectLater(
            _emailOperation(
              AuthRepositoryImpl(_FakeAuthDataSource(exception: entry.key)),
              registering,
            ),
            throwsA(_failureWithType(entry.value)),
          );
        });
      }
    }
    test(
      'registers, rejects duplicates and authenticates stored credentials',
      () async {
        final repository = AuthRepositoryImpl(MockAuthDataSource(user: _user));
        final session = await _emailOperation(repository, true);
        await expectLater(
          _emailOperation(repository, true),
          throwsA(_failureWithType(AuthFailureType.emailAlreadyInUse)),
        );
        await repository.signOut();
        await expectLater(
          repository.signInWithEmail(
            email: 'ada@example.com',
            password: 'wrong',
          ),
          throwsA(_failureWithType(AuthFailureType.invalidCredentials)),
        );
        expect(
          (await _emailOperation(repository, false)).userId,
          session.userId,
        );
      },
    );
  });

  group('AuthRepositoryImpl', () {
    test('maps a successful user payload into a session', () async {
      final source = _FakeAuthDataSource();
      final repository = AuthRepositoryImpl(source);

      final session = await repository.signInWithGoogle();

      expect(session.userId, _user.userId);
      expect(session.displayName, _user.displayName);
      expect(source.calls, [_DataSourceCall.signIn]);
    });

    test('delegates sign-out to the data source', () async {
      final source = _FakeAuthDataSource();
      final repository = AuthRepositoryImpl(source);

      await repository.signOut();

      expect(source.calls, [_DataSourceCall.signOut]);
    });

    test('waits for the data source to finish signing out', () async {
      final completion = Completer<void>();
      final source = _FakeAuthDataSource(signOutCompletion: completion);
      final repository = AuthRepositoryImpl(source);
      var finished = false;
      final result = repository.signOut().then((_) {
        finished = true;
      });

      await Future<void>.value();
      expect(finished, isFalse);
      completion.complete();
      await result;

      expect(finished, isTrue);
      expect(source.calls, [_DataSourceCall.signOut]);
    });

    const failureMapping = <AuthDataSourceError, AuthFailureType>{
      AuthDataSourceError.invalidCredentials:
          AuthFailureType.invalidCredentials,
      AuthDataSourceError.emailAlreadyInUse: AuthFailureType.emailAlreadyInUse,
      AuthDataSourceError.cancelled: AuthFailureType.cancelled,
      AuthDataSourceError.connection: AuthFailureType.connection,
      AuthDataSourceError.authentication: AuthFailureType.authentication,
      AuthDataSourceError.profileLoading: AuthFailureType.profileLoading,
    };

    for (final entry in failureMapping.entries) {
      test('maps ${entry.key.name} during sign-in', () async {
        final source = _FakeAuthDataSource(
          exception: AuthDataSourceException(entry.key),
        );
        final repository = AuthRepositoryImpl(source);

        await expectLater(
          repository.signInWithGoogle(),
          throwsA(_failureWithType(entry.value)),
        );
        expect(source.calls, [_DataSourceCall.signIn]);
      });

      test('maps ${entry.key.name} during sign-out', () async {
        final source = _FakeAuthDataSource(
          exception: AuthDataSourceException(entry.key),
        );
        final repository = AuthRepositoryImpl(source);

        await expectLater(
          repository.signOut(),
          throwsA(_failureWithType(entry.value)),
        );
        expect(source.calls, [_DataSourceCall.signOut]);
      });
    }

    test(
      'classifies a malformed sign-in payload as a profile failure',
      () async {
        final source = _FakeAuthDataSource(exception: const FormatException());
        final repository = AuthRepositoryImpl(source);

        await expectLater(
          repository.signInWithGoogle(),
          throwsA(_failureWithType(AuthFailureType.profileLoading)),
        );
      },
    );

    test('contains unclassified provider exceptions during sign-in', () async {
      final source = _FakeAuthDataSource(exception: Exception());
      final repository = AuthRepositoryImpl(source);

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(_failureWithType(AuthFailureType.authentication)),
      );
    });

    test('contains unclassified provider exceptions during sign-out', () async {
      final source = _FakeAuthDataSource(exception: Exception());
      final repository = AuthRepositoryImpl(source);

      await expectLater(
        repository.signOut(),
        throwsA(_failureWithType(AuthFailureType.authentication)),
      );
    });
  });
}

Matcher _failureWithType(AuthFailureType type) =>
    isA<AuthFailure>().having((failure) => failure.type, 'type', type);

enum _DataSourceCall { signIn, signOut, email, register }

class _FakeAuthDataSource implements AuthDataSource {
  _FakeAuthDataSource({this.exception, this.signOutCompletion});

  String? email;
  String? password;
  String? displayName;

  /// The provider exception returned by either operation, if configured.
  final Exception? exception;

  /// Optional completion used to hold sign-out pending.
  final Completer<void>? signOutCompletion;

  /// The ordered operations received by the fake.
  final List<_DataSourceCall> calls = [];

  /// Records sign-in and returns the fixture or configured provider exception.
  @override
  Future<AuthUserDto> signInWithGoogle() async {
    calls.add(_DataSourceCall.signIn);
    final failure = exception;
    if (failure != null) {
      throw failure;
    }
    return _user;
  }

  @override
  Future<AuthUserDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    calls.add(_DataSourceCall.email);
    this.email = email;
    this.password = password;

    final error = exception;
    if (error != null) {
      throw error;
    }
    return _user;
  }

  @override
  Future<AuthUserDto> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    calls.add(_DataSourceCall.register);
    this.email = email;
    this.password = password;
    this.displayName = displayName;
    final error = exception;
    if (error != null) {
      throw error;
    }
    return _user;
  }

  /// Records sign-out and awaits completion or throws the configured exception.
  @override
  Future<void> signOut() async {
    calls.add(_DataSourceCall.signOut);
    final failure = exception;
    if (failure != null) {
      throw failure;
    }
    final completion = signOutCompletion;
    if (completion != null) {
      await completion.future;
    }
  }
}

Future<AuthSession> _emailOperation(
  AuthRepositoryImpl repository,
  bool registering,
) => registering
    ? repository.registerWithEmail(
        displayName: 'Ada',
        email: 'ada@example.com',
        password: ' secret ',
      )
    : repository.signInWithEmail(
        email: 'ada@example.com',
        password: ' secret ',
      );
