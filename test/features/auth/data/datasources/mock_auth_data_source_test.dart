import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source_exception.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';

const _user = AuthUserDto(userId: 'mock-user', displayName: 'Mock User');

/// Verifies every configured mock scenario and the in-memory session lifecycle.
void main() {
  group('email accounts', () {
    test(
      'registers unique identities, normalizes keys and restores sessions',
      () async {
        final source = MockAuthDataSource(user: _user);
        final first = await source.registerWithEmail(
          displayName: 'Ada',
          email: '  Ada@Example.com ',
          password: ' secret ',
        );
        expect(first.userId, 'email-user-1');
        expect(first.displayName, 'Ada');
        expect(source.currentUser, same(first));
        final second = await source.registerWithEmail(
          displayName: 'Grace',
          email: 'grace@example.com',
          password: 'another',
        );
        expect(second.userId, 'email-user-2');
        expect(source.currentUser, same(second));
        await source.signOut();
        expect(source.currentUser, isNull);
        expect(
          await source.signInWithEmail(
            email: ' ADA@example.COM ',
            password: ' secret ',
          ),
          same(first),
        );
        expect(source.currentUser, same(first));
        expect(await source.signInWithGoogle(), same(_user));
      },
    );

    test(
      'duplicate email never replaces credentials or the current session',
      () async {
        final source = MockAuthDataSource(user: _user);
        final original = await source.registerWithEmail(
          displayName: 'Ada',
          email: 'ada@example.com',
          password: 'secret',
        );
        await expectLater(
          source.registerWithEmail(
            displayName: 'Replacement',
            email: ' ADA@EXAMPLE.COM ',
            password: 'changed',
          ),
          throwsA(_dataFailure(AuthDataSourceError.emailAlreadyInUse)),
        );
        expect(source.currentUser, same(original));
        await source.signOut();
        expect(
          await source.signInWithEmail(
            email: 'ada@example.com',
            password: 'secret',
          ),
          same(original),
        );
      },
    );

    for (final credentials in [
      (email: 'missing@example.com', password: 'secret'),
      (email: 'ada@example.com', password: 'wrong'),
      (email: 'ada@example.com', password: ' secret '),
    ]) {
      test(
        'rejects invalid credentials $credentials without a new session',
        () async {
          final source = MockAuthDataSource(user: _user);
          await source.registerWithEmail(
            displayName: 'Ada',
            email: 'ada@example.com',
            password: 'secret',
          );
          await source.signOut();
          await expectLater(
            source.signInWithEmail(
              email: credentials.email,
              password: credentials.password,
            ),
            throwsA(_dataFailure(AuthDataSourceError.invalidCredentials)),
          );
          expect(source.currentUser, isNull);
        },
      );
    }
    const scenarios = {
      MockAuthOutcome.cancelled: AuthDataSourceError.cancelled,
      MockAuthOutcome.connectionFailure: AuthDataSourceError.connection,
      MockAuthOutcome.authenticationFailure: AuthDataSourceError.authentication,
      MockAuthOutcome.profileLoadingFailure: AuthDataSourceError.profileLoading,
    };
    for (final scenario in scenarios.entries) {
      test('email operations respect ${scenario.key.name}', () async {
        final source = MockAuthDataSource(user: _user, outcome: scenario.key);
        await expectLater(
          source.registerWithEmail(
            displayName: 'Ada',
            email: 'ada@example.com',
            password: 'secret',
          ),
          throwsA(_dataFailure(scenario.value)),
        );
        await expectLater(
          source.signInWithEmail(
            email: 'ada@example.com',
            password: 'secret',
          ),
          throwsA(_dataFailure(scenario.value)),
        );
        expect(source.currentUser, isNull);
      });
    }
  });

  group('MockAuthDataSource', () {
    test(
      'starts without a session and stores the configured user on success',
      () async {
        final source = MockAuthDataSource(user: _user);
        expect(source.currentUser, isNull);

        final user = await source.signInWithGoogle();

        expect(user, same(_user));
        expect(source.currentUser, same(_user));
      },
    );

    const failureScenarios = <MockAuthOutcome, AuthDataSourceError>{
      MockAuthOutcome.cancelled: AuthDataSourceError.cancelled,
      MockAuthOutcome.connectionFailure: AuthDataSourceError.connection,
      MockAuthOutcome.authenticationFailure: AuthDataSourceError.authentication,
      MockAuthOutcome.profileLoadingFailure: AuthDataSourceError.profileLoading,
    };

    for (final entry in failureScenarios.entries) {
      test(
        '${entry.key.name} reports its own error without storing a user',
        () async {
          final source = MockAuthDataSource(user: _user, outcome: entry.key);

          await expectLater(
            source.signInWithGoogle(),
            throwsA(
              isA<AuthDataSourceException>().having(
                (error) => error.code,
                'code',
                entry.value,
              ),
            ),
          );
          expect(source.currentUser, isNull);
        },
      );
    }

    test('clears a session and supports signing in again', () async {
      final source = MockAuthDataSource(user: _user);
      await source.signInWithGoogle();

      await source.signOut();
      expect(source.currentUser, isNull);

      expect(await source.signInWithGoogle(), same(_user));
      expect(source.currentUser, same(_user));
    });

    test('sign-out succeeds without a session and on repeated calls', () async {
      final source = MockAuthDataSource(user: _user);

      await source.signOut();
      await source.signOut();

      expect(source.currentUser, isNull);
    });
  });
}

Matcher _dataFailure(AuthDataSourceError code) =>
    isA<AuthDataSourceException>().having((value) => value.code, 'code', code);
