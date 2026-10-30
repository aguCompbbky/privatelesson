import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';
import 'package:privatelesson/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:privatelesson/features/auth/domain/usecases/get_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/save_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';

const _session = AuthSession(userId: 'mock-user', displayName: 'Mock User');
const _profile = UserProfile(
  userId: 'mock-user',
  displayName: 'Saved Name',
  role: UserRole.teacher,
);

/// Verifies authentication state order, failure types and concurrent calls.
void main() {
  test('starts idle without calling either use case or emitting', () async {
    final repository = _FakeAuthRepository();
    final cubit = _createCubit(repository);
    final states = cubit.stream.toList();

    expect(cubit.state, isA<AuthInitial>());
    expect(repository.calls, isEmpty);
    await cubit.close();
    expect(await states, isEmpty);
  });

  group('signInWithGoogle', () {
    test('emits loading then the exact authenticated session', () async {
      final completion = Completer<AuthSession>();
      final repository = _FakeAuthRepository(
        onSignIn: () => completion.future,
      );
      final cubit = _createCubit(repository);
      final states = cubit.stream.toList();

      final result = cubit.signInWithGoogle();

      expect(cubit.state, isA<AuthLoading>());
      expect(repository.calls, [_RepositoryCall.signIn]);
      completion.complete(_session);
      await result;

      expect(cubit.state, _authenticatedWithSession());
      await cubit.close();
      expect(await states, [isA<AuthLoading>(), _authenticatedWithSession()]);
    });

    for (final type in AuthFailureType.values) {
      test('emits loading then a ${type.name} failure', () async {
        final repository = _FakeAuthRepository(
          onSignIn: () => Future<AuthSession>.error(AuthFailure(type)),
        );
        final cubit = _createCubit(repository);
        final states = cubit.stream.toList();

        await cubit.signInWithGoogle();

        expect(cubit.state, _failureWithType(type));
        expect(repository.calls, [_RepositoryCall.signIn]);
        await cubit.close();
        expect(await states, [isA<AuthLoading>(), _failureWithType(type)]);
      });
    }

    test('ignores both operations while sign-in is pending', () async {
      final completion = Completer<AuthSession>();
      final repository = _FakeAuthRepository(
        onSignIn: () => completion.future,
      );
      final cubit = _createCubit(repository);
      final states = cubit.stream.toList();

      final result = cubit.signInWithGoogle();
      await cubit.signInWithGoogle();
      await cubit.signOut();

      expect(cubit.state, isA<AuthLoading>());
      expect(repository.calls, [_RepositoryCall.signIn]);
      completion.complete(_session);
      await result;
      await cubit.close();

      expect(repository.calls, [_RepositoryCall.signIn]);
      expect(await states, [isA<AuthLoading>(), _authenticatedWithSession()]);
    });

    test('allows retry after a controlled failure', () async {
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
      final states = cubit.stream.toList();

      await cubit.signInWithGoogle();
      await cubit.signInWithGoogle();
      await cubit.close();

      expect(repository.calls, [
        _RepositoryCall.signIn,
        _RepositoryCall.signIn,
      ]);
      expect(await states, [
        isA<AuthLoading>(),
        _failureWithType(AuthFailureType.connection),
        isA<AuthLoading>(),
        _authenticatedWithSession(),
      ]);
    });

    test(
      'propagates an unexpected exception without a failure state',
      () async {
        final exception = Exception('Unexpected sign-in exception');
        final repository = _FakeAuthRepository(
          onSignIn: () => Future<AuthSession>.error(exception),
        );
        final cubit = _createCubit(repository);
        final previousState = cubit.state;
        final states = cubit.stream.toList();

        await expectLater(cubit.signInWithGoogle(), throwsA(same(exception)));
        expect(cubit.state, isNot(isA<AuthLoading>()));
        expect(cubit.state, same(previousState));
        await cubit.close();

        expect(repository.calls, [_RepositoryCall.signIn]);
        expect(await states, [isA<AuthLoading>(), same(previousState)]);
      },
    );

    test('propagates a synchronous programming error', () async {
      final error = StateError('Unexpected sign-in error');
      final repository = _FakeAuthRepository(
        onSignIn: () => throw error,
      );
      final cubit = _createCubit(repository);
      final previousState = cubit.state;
      final states = cubit.stream.toList();

      await expectLater(cubit.signInWithGoogle(), throwsA(same(error)));
      expect(cubit.state, isNot(isA<AuthLoading>()));
      expect(cubit.state, same(previousState));
      await cubit.close();

      expect(repository.calls, [_RepositoryCall.signIn]);
      expect(await states, [isA<AuthLoading>(), same(previousState)]);
    });

    test(
      'restores signed-out state after an exception and allows retry',
      () async {
        final exception = Exception('Unexpected sign-in exception');
        var attempts = 0;
        final repository = _FakeAuthRepository(
          onSignIn: () async {
            attempts += 1;
            if (attempts == 1) {
              throw exception;
            }
            return _session;
          },
        );
        final cubit = _createCubit(repository);
        await cubit.signOut();
        expect(cubit.state, isA<AuthUnauthenticated>());
        final previousState = cubit.state;
        final states = cubit.stream.toList();

        await expectLater(cubit.signInWithGoogle(), throwsA(same(exception)));

        expect(cubit.state, isNot(isA<AuthLoading>()));
        expect(cubit.state, same(previousState));
        await cubit.signInWithGoogle();

        expect(cubit.state, _authenticatedWithSession());
        expect(attempts, 2);
        expect(repository.calls, [
          _RepositoryCall.signOut,
          _RepositoryCall.signIn,
          _RepositoryCall.signIn,
        ]);
        await cubit.close();
        expect(await states, [
          isA<AuthLoading>(),
          same(previousState),
          isA<AuthLoading>(),
          _authenticatedWithSession(),
        ]);
      },
    );
  });

  group('profile loading and completion', () {
    test(
      'first sign-in loads the profile and initializes editable values',
      () async {
        final profiles = _FakeProfileRepository(profile: null);
        final cubit = _createCubit(_FakeAuthRepository(), profiles: profiles);
        final states = cubit.stream.toList();

        await cubit.signInWithGoogle();

        expect(cubit.state, _incompleteProfile());
        expect(profiles.requestedUserIds, [_session.userId]);
        expect(profiles.savedProfiles, isEmpty);
        await cubit.close();
        expect(await states, [isA<AuthLoading>(), _incompleteProfile()]);
      },
    );

    for (final role in UserRole.values) {
      test(
        'loads saved ${role.name} directly without asking for a role',
        () async {
          final profile = UserProfile(
            userId: _session.userId,
            displayName: _profile.displayName,
            role: role,
          );
          final profiles = _FakeProfileRepository(profile: profile);
          final cubit = _createCubit(_FakeAuthRepository(), profiles: profiles);
          final states = cubit.stream.toList();

          await cubit.signInWithGoogle();

          expect((cubit.state as AuthAuthenticated).profile, same(profile));
          expect(profiles.requestedUserIds, [_session.userId]);
          await cubit.close();
          expect(await states, [
            isA<AuthLoading>(),
            _authenticatedWithSession(),
          ]);
        },
      );

      test(
        'saves ${role.name} and reuses the saved profile after sign-out',
        () async {
          final profiles = _FakeProfileRepository(profile: null);
          final cubit = _createCubit(_FakeAuthRepository(), profiles: profiles);
          await cubit.signInWithGoogle();

          cubit.selectRole(role);
          cubit.updateDisplayName('  Chosen Name  ');
          final states = cubit.stream.toList();
          await cubit.completeProfile();

          final authenticated = cubit.state as AuthAuthenticated;
          expect(authenticated.session, same(_session));
          expect(authenticated.profile, same(profiles.profile));
          expect(authenticated.profile.displayName, 'Chosen Name');
          expect(authenticated.profile.role, role);
          expect(profiles.savedProfiles, hasLength(1));
          await cubit.signOut();
          await cubit.signInWithGoogle();
          expect(
            (cubit.state as AuthAuthenticated).profile,
            same(authenticated.profile),
          );
          await cubit.close();
          expect(await states, [
            _incompleteProfile(
              name: '  Chosen Name  ',
              role: role,
              submitting: true,
            ),
            isA<AuthAuthenticated>(),
            isA<AuthLoading>(),
            isA<AuthUnauthenticated>(),
            isA<AuthLoading>(),
            isA<AuthAuthenticated>(),
          ]);
        },
      );
    }

    for (final type in ProfileFailureType.values) {
      test(
        'maps profile read ${type.name} to authentication profileLoading',
        () async {
          final profiles = _FakeProfileRepository(
            onRead: (_) => Future<UserProfile?>.error(ProfileFailure(type)),
          );
          final cubit = _createCubit(_FakeAuthRepository(), profiles: profiles);
          final states = cubit.stream.toList();

          await cubit.signInWithGoogle();

          expect(cubit.state, _failureWithType(AuthFailureType.profileLoading));
          await cubit.close();
          expect(await states, [
            isA<AuthLoading>(),
            _failureWithType(AuthFailureType.profileLoading),
          ]);
        },
      );

      test(
        'keeps form values for ${type.name} and clears failure on edits',
        () async {
          final profiles = _FakeProfileRepository(
            profile: null,
            onSave: (_) => Future<UserProfile>.error(ProfileFailure(type)),
          );
          final cubit = _createCubit(_FakeAuthRepository(), profiles: profiles);
          await cubit.signInWithGoogle();
          cubit.selectRole(UserRole.teacher);
          cubit.updateDisplayName(_profile.displayName);
          final states = cubit.stream.toList();

          await cubit.completeProfile();
          expect(
            cubit.state,
            _incompleteProfile(
              name: _profile.displayName,
              role: UserRole.teacher,
              failure: type,
            ),
          );
          cubit.selectRole(UserRole.student);
          expect((cubit.state as AuthProfileIncomplete).failureType, isNull);
          await cubit.completeProfile();
          cubit.updateDisplayName(_session.displayName);
          expect(cubit.state, _incompleteProfile());
          await cubit.close();
          final emitted = await states;
          expect(
            emitted.first,
            _incompleteProfile(
              name: _profile.displayName,
              role: UserRole.teacher,
              submitting: true,
            ),
          );
          expect(
            emitted[1],
            _incompleteProfile(
              name: _profile.displayName,
              role: UserRole.teacher,
              failure: type,
            ),
          );
        },
      );
    }

    test(
      'blank name is validated before storage and can be corrected',
      () async {
        final profiles = _FakeProfileRepository(profile: null);
        final cubit = _createCubit(_FakeAuthRepository(), profiles: profiles);
        await cubit.signInWithGoogle();
        cubit.updateDisplayName('   ');

        await cubit.completeProfile();

        expect(
          cubit.state,
          _incompleteProfile(
            name: '   ',
            failure: ProfileFailureType.invalidDisplayName,
          ),
        );
        expect(profiles.savedProfiles, isEmpty);
        cubit.updateDisplayName(_profile.displayName);
        await cubit.completeProfile();
        expect(cubit.state, isA<AuthAuthenticated>());
      },
    );

    test('blocks all operations while profile loading is pending', () async {
      final completion = Completer<UserProfile?>();
      final auth = _FakeAuthRepository();
      final profiles = _FakeProfileRepository(onRead: (_) => completion.future);
      final cubit = _createCubit(auth, profiles: profiles);
      final result = cubit.signInWithGoogle();
      await Future<void>.value();

      await cubit.signInWithGoogle();
      await cubit.signOut();
      await cubit.completeProfile();
      cubit.selectRole(UserRole.teacher);
      cubit.updateDisplayName(_profile.displayName);
      expect(cubit.state, isA<AuthLoading>());
      expect(auth.calls, [_RepositoryCall.signIn]);
      expect(profiles.requestedUserIds, [_session.userId]);
      expect(profiles.savedProfiles, isEmpty);
      completion.complete(null);
      await result;
      expect(cubit.state, _incompleteProfile());
    });

    test(
      'blocks all operations while saving and uses the returned profile',
      () async {
        final completion = Completer<UserProfile>();
        final auth = _FakeAuthRepository();
        final profiles = _FakeProfileRepository(
          profile: null,
          onSave: (_) => completion.future,
        );
        final cubit = _createCubit(auth, profiles: profiles);
        await cubit.signInWithGoogle();
        final result = cubit.completeProfile();
        final submitting = cubit.state;

        cubit.selectRole(UserRole.teacher);
        cubit.updateDisplayName('Changed while saving');
        await cubit.completeProfile();
        await cubit.signInWithGoogle();
        await cubit.signOut();

        expect(cubit.state, same(submitting));
        expect(profiles.savedProfiles, hasLength(1));
        expect(auth.calls, [_RepositoryCall.signIn]);
        completion.complete(_profile);
        await result;
        expect((cubit.state as AuthAuthenticated).profile, same(_profile));
      },
    );

    test('skips profile operations outside an incomplete profile', () async {
      final cubit = _createCubit(_FakeAuthRepository());
      for (final prepare in <Future<void> Function()>[
        () async {},
        cubit.signOut,
        cubit.signInWithGoogle,
      ]) {
        await prepare();
        final previous = cubit.state;
        cubit.selectRole(UserRole.teacher);
        cubit.updateDisplayName(_profile.displayName);
        await cubit.completeProfile();
        expect(cubit.state, same(previous));
      }
    });

    for (final error in <Object>[
      Exception('Unexpected profile error'),
      StateError('Profile bug'),
    ]) {
      test(
        'restores state after unexpected read $error and permits retry',
        () async {
          var fail = true;
          final profiles = _FakeProfileRepository(
            onRead: (_) async {
              if (fail) {
                if (error is Exception) {
                  throw error;
                }
                throw error as Error;
              }
              return null;
            },
          );
          final cubit = _createCubit(_FakeAuthRepository(), profiles: profiles);
          final previous = cubit.state;
          await expectLater(cubit.signInWithGoogle(), throwsA(same(error)));
          expect(cubit.state, same(previous));
          fail = false;
          await cubit.signInWithGoogle();
          expect(cubit.state, _incompleteProfile());
        },
      );

      test(
        'restores edited form after unexpected save $error and retries',
        () async {
          var fail = true;
          final profiles = _FakeProfileRepository(
            profile: null,
            onSave: (profile) async {
              if (fail) {
                if (error is Exception) {
                  throw error;
                }
                throw error as Error;
              }
              return profile;
            },
          );
          final cubit = _createCubit(_FakeAuthRepository(), profiles: profiles);
          await cubit.signInWithGoogle();
          cubit.selectRole(UserRole.teacher);
          cubit.updateDisplayName(_profile.displayName);
          final previous = cubit.state;

          await expectLater(cubit.completeProfile(), throwsA(same(error)));

          expect(cubit.state, same(previous));
          fail = false;
          await cubit.completeProfile();
          expect(
            (cubit.state as AuthAuthenticated).profile.role,
            UserRole.teacher,
          );
        },
      );
    }
  });

  group('signOut', () {
    test(
      'emits loading then signed-out after an authenticated session',
      () async {
        final completion = Completer<void>();
        final repository = _FakeAuthRepository(
          onSignOut: () => completion.future,
        );
        final cubit = _createCubit(repository);
        await cubit.signInWithGoogle();
        expect(cubit.state, _authenticatedWithSession());
        final states = cubit.stream.toList();

        final result = cubit.signOut();

        expect(cubit.state, isA<AuthLoading>());
        completion.complete();
        await result;

        expect(cubit.state, isA<AuthUnauthenticated>());
        expect(repository.calls, [
          _RepositoryCall.signIn,
          _RepositoryCall.signOut,
        ]);
        await cubit.close();
        expect(await states, [isA<AuthLoading>(), isA<AuthUnauthenticated>()]);
      },
    );

    for (final type in AuthFailureType.values) {
      test('emits loading then a ${type.name} failure', () async {
        final repository = _FakeAuthRepository(
          onSignOut: () => Future<void>.error(AuthFailure(type)),
        );
        final cubit = _createCubit(repository);
        final states = cubit.stream.toList();

        await cubit.signOut();

        expect(cubit.state, _failureWithType(type));
        expect(repository.calls, [_RepositoryCall.signOut]);
        await cubit.close();
        expect(await states, [isA<AuthLoading>(), _failureWithType(type)]);
      });
    }

    test('ignores both operations while sign-out is pending', () async {
      final completion = Completer<void>();
      final repository = _FakeAuthRepository(
        onSignOut: () => completion.future,
      );
      final cubit = _createCubit(repository);
      final states = cubit.stream.toList();

      final result = cubit.signOut();
      await cubit.signOut();
      await cubit.signInWithGoogle();

      expect(cubit.state, isA<AuthLoading>());
      expect(repository.calls, [_RepositoryCall.signOut]);
      completion.complete();
      await result;
      await cubit.close();

      expect(repository.calls, [_RepositoryCall.signOut]);
      expect(await states, [isA<AuthLoading>(), isA<AuthUnauthenticated>()]);
    });

    test('allows sign-in again after sign-out completes', () async {
      final repository = _FakeAuthRepository();
      final cubit = _createCubit(repository);
      final states = cubit.stream.toList();

      await cubit.signOut();
      await cubit.signInWithGoogle();
      await cubit.close();

      expect(repository.calls, [
        _RepositoryCall.signOut,
        _RepositoryCall.signIn,
      ]);
      expect(await states, [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
        isA<AuthLoading>(),
        _authenticatedWithSession(),
      ]);
    });

    test(
      'propagates an unexpected exception without a failure state',
      () async {
        final exception = Exception('Unexpected sign-out exception');
        final repository = _FakeAuthRepository(
          onSignOut: () => Future<void>.error(exception),
        );
        final cubit = _createCubit(repository);
        final previousState = cubit.state;
        final states = cubit.stream.toList();

        await expectLater(cubit.signOut(), throwsA(same(exception)));
        expect(cubit.state, isNot(isA<AuthLoading>()));
        expect(cubit.state, same(previousState));
        await cubit.close();

        expect(repository.calls, [_RepositoryCall.signOut]);
        expect(await states, [isA<AuthLoading>(), same(previousState)]);
      },
    );

    test('propagates a synchronous programming error', () async {
      final error = StateError('Unexpected sign-out error');
      final repository = _FakeAuthRepository(
        onSignOut: () => throw error,
      );
      final cubit = _createCubit(repository);
      final previousState = cubit.state;
      final states = cubit.stream.toList();

      await expectLater(cubit.signOut(), throwsA(same(error)));
      expect(cubit.state, isNot(isA<AuthLoading>()));
      expect(cubit.state, same(previousState));
      await cubit.close();

      expect(repository.calls, [_RepositoryCall.signOut]);
      expect(await states, [isA<AuthLoading>(), same(previousState)]);
    });

    test(
      'restores authenticated state after an exception and allows retry',
      () async {
        final exception = Exception('Unexpected sign-out exception');
        var attempts = 0;
        final repository = _FakeAuthRepository(
          onSignOut: () async {
            attempts += 1;
            if (attempts == 1) {
              throw exception;
            }
          },
        );
        final cubit = _createCubit(repository);
        await cubit.signInWithGoogle();
        expect(cubit.state, _authenticatedWithSession());
        final previousState = cubit.state;
        final states = cubit.stream.toList();

        await expectLater(cubit.signOut(), throwsA(same(exception)));

        expect(cubit.state, isNot(isA<AuthLoading>()));
        expect(cubit.state, same(previousState));
        await cubit.signOut();

        expect(cubit.state, isA<AuthUnauthenticated>());
        expect(attempts, 2);
        expect(repository.calls, [
          _RepositoryCall.signIn,
          _RepositoryCall.signOut,
          _RepositoryCall.signOut,
        ]);
        await cubit.close();
        expect(await states, [
          isA<AuthLoading>(),
          same(previousState),
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ]);
      },
    );
  });
}

AuthCubit _createCubit(
  AuthRepository repository, {
  UserProfileRepository? profiles,
}) {
  final profileRepository = profiles ?? _FakeProfileRepository();
  final cubit = AuthCubit(
    signInWithGoogleUseCase: SignInWithGoogleUseCase(repository),
    signOutUseCase: SignOutUseCase(repository),
    getUserProfileUseCase: GetUserProfileUseCase(profileRepository),
    saveUserProfileUseCase: SaveUserProfileUseCase(profileRepository),
  );
  addTearDown(cubit.close);
  return cubit;
}

Matcher _authenticatedWithSession() => isA<AuthAuthenticated>().having(
  (state) => state.session,
  'session',
  same(_session),
);

Matcher _failureWithType(AuthFailureType type) =>
    isA<AuthFailureState>().having((state) => state.type, 'type', type);

enum _RepositoryCall { signIn, signOut }

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    Future<AuthSession> Function()? onSignIn,
    Future<void> Function()? onSignOut,
  }) : _onSignIn = onSignIn,
       _onSignOut = onSignOut;

  final Future<AuthSession> Function()? _onSignIn;
  final Future<void> Function()? _onSignOut;

  /// The ordered operations received through the real use cases.
  final List<_RepositoryCall> calls = [];

  /// Records sign-in and returns the configured outcome or the fixture.
  @override
  Future<AuthSession> signInWithGoogle() {
    calls.add(_RepositoryCall.signIn);
    return _onSignIn?.call() ?? Future<AuthSession>.value(_session);
  }

  /// Records sign-out and returns the configured outcome or completes.
  @override
  Future<void> signOut() {
    calls.add(_RepositoryCall.signOut);
    return _onSignOut?.call() ?? Future<void>.value();
  }
}

Matcher _incompleteProfile({
  String name = 'Mock User',
  UserRole role = UserRole.student,
  ProfileFailureType? failure,
  bool submitting = false,
}) => isA<AuthProfileIncomplete>()
    .having((state) => state.session, 'session', same(_session))
    .having((state) => state.displayName, 'displayName', name)
    .having((state) => state.selectedRole, 'selectedRole', role)
    .having((state) => state.failureType, 'failureType', failure)
    .having((state) => state.isSubmitting, 'isSubmitting', submitting);

class _FakeProfileRepository implements UserProfileRepository {
  _FakeProfileRepository({this.profile = _profile, this.onRead, this.onSave});

  UserProfile? profile;
  final Future<UserProfile?> Function(String)? onRead;
  final Future<UserProfile> Function(UserProfile)? onSave;
  final List<String> requestedUserIds = [];
  final List<UserProfile> savedProfiles = [];

  @override
  Future<UserProfile?> getProfile(String userId) async {
    requestedUserIds.add(userId);
    return onRead == null ? profile : onRead!(userId);
  }

  @override
  Future<UserProfile> saveProfile(UserProfile value) async {
    savedProfiles.add(value);
    final stored = onSave == null ? value : await onSave!(value);
    profile = stored;
    return stored;
  }
}
