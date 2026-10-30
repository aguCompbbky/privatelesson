import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source_exception.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';

const _user = AuthUserDto(userId: 'mock-user', displayName: 'Mock User');

/// Verifies every configured mock scenario and the in-memory session lifecycle.
void main() {
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
