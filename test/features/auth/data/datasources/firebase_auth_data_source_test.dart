import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source_exception.dart';
import 'package:privatelesson/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:privatelesson/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';

final class _TestFirebaseAuthException extends FirebaseAuthException {
  _TestFirebaseAuthException(String code) : super(code: code);
}

final class _FakeFirebaseAuthGateway implements FirebaseAuthGateway {
  Future<GoogleAuthTokens> Function()? onGoogleTokens;
  Future<FirebaseAuthIdentity?> Function(String idToken)? onGoogleSignIn;
  Future<FirebaseAuthIdentity?> Function(String email, String password)?
  onEmailSignIn;
  Future<FirebaseAuthIdentity?> Function(
    String displayName,
    String email,
    String password,
  )?
  onEmailRegister;
  Future<void> Function()? onSignOut;

  int signOutCalls = 0;

  @override
  Future<GoogleAuthTokens> authenticateWithGoogle() => onGoogleTokens != null
      ? onGoogleTokens!()
      : Future.value(
          const GoogleAuthTokens(
            idToken: 'google-id-token',
            displayName: 'Google Fallback Name',
          ),
        );

  @override
  Future<FirebaseAuthIdentity?> signInWithGoogleIdToken(String idToken) =>
      onGoogleSignIn != null
      ? onGoogleSignIn!(idToken)
      : Future.value(
          const FirebaseAuthIdentity(
            uid: 'firebase-uid-1',
            displayName: 'Firebase User',
          ),
        );

  @override
  Future<FirebaseAuthIdentity?> signInWithEmail({
    required String email,
    required String password,
  }) => onEmailSignIn != null
      ? onEmailSignIn!(email, password)
      : Future.value(
          const FirebaseAuthIdentity(
            uid: 'email-uid-1',
            displayName: 'Email User',
          ),
        );

  @override
  Future<FirebaseAuthIdentity?> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) => onEmailRegister != null
      ? onEmailRegister!(displayName, email, password)
      : Future.value(
          FirebaseAuthIdentity(
            uid: 'registered-uid-1',
            displayName: displayName,
          ),
        );

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    await onSignOut?.call();
  }
}

void main() {
  group('FirebaseAuthDataSource', () {
    test('signInWithGoogle returns Firebase identity and falls back to Google '
        'displayName when Firebase displayName is blank', () async {
      final gateway = _FakeFirebaseAuthGateway();
      final source = FirebaseAuthDataSource(gateway: gateway);

      final primary = await source.signInWithGoogle();
      expect(primary.userId, 'firebase-uid-1');
      expect(primary.displayName, 'Firebase User');

      gateway.onGoogleSignIn = (_) async => const FirebaseAuthIdentity(
        uid: 'firebase-uid-2',
        displayName: '   ',
      );
      final fallback = await source.signInWithGoogle();
      expect(fallback.userId, 'firebase-uid-2');
      expect(fallback.displayName, 'Google Fallback Name');
    });

    test('signInWithGoogle rejects blank uid from Firebase', () async {
      final gateway = _FakeFirebaseAuthGateway();
      gateway.onGoogleSignIn = (_) async => const FirebaseAuthIdentity(
        uid: '   ',
        displayName: 'User',
      );
      await expectLater(
        FirebaseAuthDataSource(gateway: gateway).signInWithGoogle(),
        throwsA(
          isA<AuthDataSourceException>().having(
            (e) => e.code,
            'code',
            AuthDataSourceError.authentication,
          ),
        ),
      );
    });

    test(
      'signInWithGoogle maps missing tokens and Google exceptions',
      () async {
        final missingTokenGateway = _FakeFirebaseAuthGateway();
        missingTokenGateway.onGoogleTokens = () async => const GoogleAuthTokens(
          idToken: null,
          displayName: 'User',
        );
        final missingTokenSource = FirebaseAuthDataSource(
          gateway: missingTokenGateway,
        );
        await expectLater(
          missingTokenSource.signInWithGoogle(),
          throwsA(
            isA<AuthDataSourceException>().having(
              (e) => e.code,
              'code',
              AuthDataSourceError.authentication,
            ),
          ),
        );

        final canceledGateway = _FakeFirebaseAuthGateway();
        canceledGateway.onGoogleTokens = () async =>
            throw const GoogleSignInException(
              code: GoogleSignInExceptionCode.canceled,
            );
        await expectLater(
          FirebaseAuthDataSource(gateway: canceledGateway).signInWithGoogle(),
          throwsA(
            isA<AuthDataSourceException>().having(
              (e) => e.code,
              'code',
              AuthDataSourceError.cancelled,
            ),
          ),
        );

        final interruptedGateway = _FakeFirebaseAuthGateway();
        interruptedGateway.onGoogleTokens = () async =>
            throw const GoogleSignInException(
              code: GoogleSignInExceptionCode.interrupted,
            );
        await expectLater(
          FirebaseAuthDataSource(
            gateway: interruptedGateway,
          ).signInWithGoogle(),
          throwsA(
            isA<AuthDataSourceException>().having(
              (e) => e.code,
              'code',
              AuthDataSourceError.connection,
            ),
          ),
        );

        final misconfiguredGateway = _FakeFirebaseAuthGateway();
        misconfiguredGateway.onGoogleTokens = () async =>
            throw const GoogleSignInException(
              code: GoogleSignInExceptionCode.clientConfigurationError,
            );
        await expectLater(
          FirebaseAuthDataSource(
            gateway: misconfiguredGateway,
          ).signInWithGoogle(),
          throwsA(
            isA<AuthDataSourceException>().having(
              (e) => e.code,
              'code',
              AuthDataSourceError.authentication,
            ),
          ),
        );
      },
    );

    test('signInWithEmail maps credentials, network and auth errors', () async {
      final gateway = _FakeFirebaseAuthGateway();
      final source = FirebaseAuthDataSource(gateway: gateway);

      final dto = await source.signInWithEmail(
        email: 'user@example.com',
        password: 'secret',
      );
      expect(dto.userId, 'email-uid-1');
      expect(dto.displayName, 'Email User');

      for (final code in [
        'invalid-credential',
        'wrong-password',
        'user-not-found',
        'invalid-email',
      ]) {
        gateway.onEmailSignIn = (_, _) async =>
            throw _TestFirebaseAuthException(code);
        await expectLater(
          source.signInWithEmail(email: 'user@example.com', password: 'bad'),
          throwsA(
            isA<AuthDataSourceException>().having(
              (e) => e.code,
              'code',
              AuthDataSourceError.invalidCredentials,
            ),
          ),
        );
      }

      gateway.onEmailSignIn = (_, _) async =>
          throw _TestFirebaseAuthException('network-request-failed');
      await expectLater(
        source.signInWithEmail(email: 'user@example.com', password: 'secret'),
        throwsA(
          isA<AuthDataSourceException>().having(
            (e) => e.code,
            'code',
            AuthDataSourceError.connection,
          ),
        ),
      );
    });

    test('registerWithEmail trims displayName, maps duplicate email, and works '
        'behind AuthRepositoryImpl', () async {
      final gateway = _FakeFirebaseAuthGateway();
      final source = FirebaseAuthDataSource(gateway: gateway);
      final repository = AuthRepositoryImpl(source);

      final session = await repository.registerWithEmail(
        displayName: '  Ada Lovelace  ',
        email: 'ada@example.com',
        password: 'password123',
      );
      expect(session.userId, 'registered-uid-1');
      expect(session.displayName, 'Ada Lovelace');

      gateway.onEmailRegister = (_, _, _) async =>
          throw _TestFirebaseAuthException('email-already-in-use');
      await expectLater(
        repository.registerWithEmail(
          displayName: 'Ada',
          email: 'ada@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.type,
            'type',
            AuthFailureType.emailAlreadyInUse,
          ),
        ),
      );
    });

    test('signOut delegates and translates Firebase exceptions', () async {
      final gateway = _FakeFirebaseAuthGateway();
      final source = FirebaseAuthDataSource(gateway: gateway);

      await source.signOut();
      expect(gateway.signOutCalls, 1);

      gateway.onSignOut = () async => throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'unavailable',
      );
      await expectLater(
        source.signOut(),
        throwsA(
          isA<AuthDataSourceException>().having(
            (e) => e.code,
            'code',
            AuthDataSourceError.connection,
          ),
        ),
      );
    });
  });
}
