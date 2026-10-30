import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:privatelesson/features/auth/domain/usecases/get_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/save_user_profile_use_case.dart';

const _profile = UserProfile(
  userId: 'profile-user',
  displayName: 'Profile User',
  role: UserRole.teacher,
);
const _blankInputs = <String, String>{
  'empty': '',
  'spaces': '   ',
  'mixed whitespace': ' \t\n\r ',
};

/// Verifies normalization, validation and unchanged repository results/errors.
void main() {
  group('GetUserProfileUseCase', () {
    test('returns the saved profile and delegates exactly once', () async {
      final repository = _FakeUserProfileRepository();
      final useCase = GetUserProfileUseCase(repository);

      expect(await useCase(_profile.userId), same(_profile));
      expect(repository.requestedUserIds, [_profile.userId]);
      expect(repository.savedProfiles, isEmpty);
    });

    test('preserves null for a user without a completed profile', () async {
      final repository = _FakeUserProfileRepository(profile: null);
      final useCase = GetUserProfileUseCase(repository);

      expect(await useCase(_profile.userId), isNull);
      expect(repository.requestedUserIds, [_profile.userId]);
    });

    test('trims the identifier before loading', () async {
      final repository = _FakeUserProfileRepository();
      final useCase = GetUserProfileUseCase(repository);

      expect(await useCase(' \t${_profile.userId}\n '), same(_profile));
      expect(repository.requestedUserIds, [_profile.userId]);
    });

    for (final entry in _blankInputs.entries) {
      test(
        'rejects ${entry.key} identifiers without calling storage',
        () async {
          final repository = _FakeUserProfileRepository();
          final useCase = GetUserProfileUseCase(repository);

          await expectLater(
            useCase(entry.value),
            throwsA(_failureWithType(ProfileFailureType.invalidUserId)),
          );
          expect(repository.requestedUserIds, isEmpty);
          expect(repository.savedProfiles, isEmpty);
        },
      );
    }

    for (final type in ProfileFailureType.values) {
      test(
        'propagates the ${type.name} repository failure unchanged',
        () async {
          final failure = ProfileFailure(type);
          final repository = _FakeUserProfileRepository(failure: failure);
          final useCase = GetUserProfileUseCase(repository);

          await expectLater(useCase(_profile.userId), throwsA(same(failure)));
          expect(repository.requestedUserIds, [_profile.userId]);
        },
      );
    }
  });

  group('SaveUserProfileUseCase', () {
    for (final role in UserRole.values) {
      test('saves a ${role.name} profile and returns stored values', () async {
        final stored = UserProfile(
          userId: _profile.userId,
          displayName: 'Stored Name',
          role: role,
        );
        final repository = _FakeUserProfileRepository(profile: stored);
        final useCase = SaveUserProfileUseCase(repository);

        final result = await useCase(
          userId: _profile.userId,
          displayName: _profile.displayName,
          role: role,
        );

        expect(result, same(stored));
        expect(repository.savedProfiles, [
          _matchesProfile(
            UserProfile(
              userId: _profile.userId,
              displayName: _profile.displayName,
              role: role,
            ),
          ),
        ]);
        expect(repository.requestedUserIds, isEmpty);
      });
    }

    test('trims both fields while preserving spaces inside the name', () async {
      final repository = _FakeUserProfileRepository();
      final useCase = SaveUserProfileUseCase(repository);

      await useCase(
        userId: ' \t${_profile.userId}\n ',
        displayName: ' \n${_profile.displayName}\t ',
        role: _profile.role,
      );

      expect(repository.savedProfiles, [_matchesProfile(_profile)]);
    });

    for (final entry in _blankInputs.entries) {
      test(
        'rejects ${entry.key} identifiers without calling storage',
        () async {
          final repository = _FakeUserProfileRepository();
          final useCase = SaveUserProfileUseCase(repository);

          await expectLater(
            useCase(
              userId: entry.value,
              displayName: _profile.displayName,
              role: _profile.role,
            ),
            throwsA(_failureWithType(ProfileFailureType.invalidUserId)),
          );
          expect(repository.savedProfiles, isEmpty);
          expect(repository.requestedUserIds, isEmpty);
        },
      );

      test('rejects ${entry.key} names without calling storage', () async {
        final repository = _FakeUserProfileRepository();
        final useCase = SaveUserProfileUseCase(repository);

        await expectLater(
          useCase(
            userId: _profile.userId,
            displayName: entry.value,
            role: _profile.role,
          ),
          throwsA(_failureWithType(ProfileFailureType.invalidDisplayName)),
        );
        expect(repository.savedProfiles, isEmpty);
        expect(repository.requestedUserIds, isEmpty);
      });
    }

    test('validates the identifier first when both fields are blank', () async {
      final repository = _FakeUserProfileRepository();
      final useCase = SaveUserProfileUseCase(repository);

      await expectLater(
        useCase(userId: '', displayName: '', role: UserRole.student),
        throwsA(_failureWithType(ProfileFailureType.invalidUserId)),
      );
      expect(repository.savedProfiles, isEmpty);
    });

    for (final type in ProfileFailureType.values) {
      test(
        'propagates the ${type.name} repository failure unchanged',
        () async {
          final failure = ProfileFailure(type);
          final repository = _FakeUserProfileRepository(failure: failure);
          final useCase = SaveUserProfileUseCase(repository);

          await expectLater(
            useCase(
              userId: _profile.userId,
              displayName: _profile.displayName,
              role: _profile.role,
            ),
            throwsA(same(failure)),
          );
          expect(repository.savedProfiles, [_matchesProfile(_profile)]);
        },
      );
    }
  });
}

Matcher _matchesProfile(UserProfile expected) => isA<UserProfile>()
    .having((profile) => profile.userId, 'userId', expected.userId)
    .having(
      (profile) => profile.displayName,
      'displayName',
      expected.displayName,
    )
    .having((profile) => profile.role, 'role', expected.role);

Matcher _failureWithType(ProfileFailureType type) =>
    isA<ProfileFailure>().having((failure) => failure.type, 'type', type);

class _FakeUserProfileRepository implements UserProfileRepository {
  _FakeUserProfileRepository({this.profile = _profile, this.failure});

  /// The configured profile returned by the repository.
  final UserProfile? profile;

  /// The configured domain failure returned by either operation.
  final ProfileFailure? failure;

  /// The identifiers submitted for loading.
  final List<String> requestedUserIds = [];

  /// The normalized profiles submitted for saving.
  final List<UserProfile> savedProfiles = [];

  /// Records the identifier and returns the configured result or failure.
  @override
  Future<UserProfile?> getProfile(String userId) async {
    requestedUserIds.add(userId);
    final error = failure;
    if (error != null) {
      throw error;
    }
    return profile;
  }

  /// Records the profile and returns stored values or the configured failure.
  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    savedProfiles.add(profile);
    final error = failure;
    if (error != null) {
      throw error;
    }
    return this.profile ?? profile;
  }
}
