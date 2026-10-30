import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/user_profile_dto.dart';
import 'package:privatelesson/features/auth/data/repositories/user_profile_repository_impl.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';

const _profile = UserProfile(
  userId: 'profile-user',
  displayName: 'Profile User',
  role: UserRole.teacher,
);
const _dto = UserProfileDto(
  userId: 'profile-user',
  displayName: 'Profile User',
  role: 'teacher',
);
const _invalidDto = UserProfileDto(
  userId: 'profile-user',
  displayName: 'Profile User',
  role: 'unknown',
);

/// Verifies storage delegation, returned payloads and domain failure mapping.
void main() {
  group('UserProfileRepositoryImpl', () {
    test('loads a profile through the requested user identifier', () async {
      final source = _FakeUserProfileDataSource();
      final repository = UserProfileRepositoryImpl(source);

      expect(
        await repository.getProfile(_profile.userId),
        _matchesProfile(_profile),
      );
      expect(source.requestedUserIds, [_profile.userId]);
      expect(source.savedProfiles, isEmpty);
    });

    test('preserves null for a user without a completed profile', () async {
      final source = _FakeUserProfileDataSource(onFetch: (_) async => null);
      final repository = UserProfileRepositoryImpl(source);

      expect(await repository.getProfile(_profile.userId), isNull);
      expect(source.requestedUserIds, [_profile.userId]);
    });

    test('converts the input profile and returns the stored payload', () async {
      const stored = UserProfileDto(
        userId: 'profile-user',
        displayName: 'Stored Name',
        role: 'teacher',
      );
      final source = _FakeUserProfileDataSource(onUpsert: (_) async => stored);
      final repository = UserProfileRepositoryImpl(source);

      final result = await repository.saveProfile(_profile);

      expect(source.savedProfiles, hasLength(1));
      expect(source.savedProfiles.single.toMap(), _dto.toMap());
      expect(source.requestedUserIds, isEmpty);
      expect(result, _matchesProfile(stored.toEntity()));
    });

    for (final role in UserRole.values) {
      test('retains the saved ${role.name} role on later access', () async {
        final source = MockUserProfileDataSource();
        final repository = UserProfileRepositoryImpl(source);
        final profile = UserProfile(
          userId: _profile.userId,
          displayName: _profile.displayName,
          role: role,
        );
        expect(await repository.getProfile(profile.userId), isNull);

        expect(await repository.saveProfile(profile), _matchesProfile(profile));
        final laterRepository = UserProfileRepositoryImpl(source);

        expect(
          await laterRepository.getProfile(profile.userId),
          _matchesProfile(profile),
        );
      });
    }

    final exceptions = <String, Exception>{
      'provider exception': Exception('Storage unavailable'),
      'malformed payload': const FormatException('Invalid profile'),
    };
    for (final entry in exceptions.entries) {
      test('maps a read ${entry.key} to loadFailed', () async {
        final source = _FakeUserProfileDataSource(
          onFetch: (_) => Future<UserProfileDto?>.error(entry.value),
        );
        final repository = UserProfileRepositoryImpl(source);

        await expectLater(
          repository.getProfile(_profile.userId),
          throwsA(_failureWithType(ProfileFailureType.loadFailed)),
        );
        expect(source.requestedUserIds, [_profile.userId]);
      });

      test('maps a write ${entry.key} to saveFailed', () async {
        final source = _FakeUserProfileDataSource(
          onUpsert: (_) => Future<UserProfileDto>.error(entry.value),
        );
        final repository = UserProfileRepositoryImpl(source);

        await expectLater(
          repository.saveProfile(_profile),
          throwsA(_failureWithType(ProfileFailureType.saveFailed)),
        );
        expect(source.savedProfiles, hasLength(1));
      });
    }

    test('maps an invalid fetched role to loadFailed', () async {
      final source = _FakeUserProfileDataSource(
        onFetch: (_) async => _invalidDto,
      );
      final repository = UserProfileRepositoryImpl(source);

      await expectLater(
        repository.getProfile(_profile.userId),
        throwsA(_failureWithType(ProfileFailureType.loadFailed)),
      );
    });

    test('maps an invalid saved role to saveFailed', () async {
      final source = _FakeUserProfileDataSource(
        onUpsert: (_) async => _invalidDto,
      );
      final repository = UserProfileRepositoryImpl(source);

      await expectLater(
        repository.saveProfile(_profile),
        throwsA(_failureWithType(ProfileFailureType.saveFailed)),
      );
    });

    test('preserves programming errors during loading and saving', () async {
      final error = StateError('Programming error');
      final source = _FakeUserProfileDataSource(
        onFetch: (_) => throw error,
        onUpsert: (_) => throw error,
      );
      final repository = UserProfileRepositoryImpl(source);

      await expectLater(
        repository.getProfile(_profile.userId),
        throwsA(same(error)),
      );
      await expectLater(repository.saveProfile(_profile), throwsA(same(error)));
    });
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

class _FakeUserProfileDataSource implements UserProfileDataSource {
  _FakeUserProfileDataSource({
    Future<UserProfileDto?> Function(String)? onFetch,
    Future<UserProfileDto> Function(UserProfileDto)? onUpsert,
  }) : _onFetch = onFetch,
       _onUpsert = onUpsert;

  final Future<UserProfileDto?> Function(String)? _onFetch;
  final Future<UserProfileDto> Function(UserProfileDto)? _onUpsert;

  /// The identifiers received by the read operation.
  final List<String> requestedUserIds = [];

  /// The payloads received by the write operation.
  final List<UserProfileDto> savedProfiles = [];

  /// Records the identifier and returns the configured payload or failure.
  @override
  Future<UserProfileDto?> fetchProfile(String userId) {
    requestedUserIds.add(userId);
    return _onFetch?.call(userId) ?? Future<UserProfileDto?>.value(_dto);
  }

  /// Records the payload and returns the configured result or input payload.
  @override
  Future<UserProfileDto> upsertProfile(UserProfileDto profile) {
    savedProfiles.add(profile);
    return _onUpsert?.call(profile) ?? Future<UserProfileDto>.value(profile);
  }
}
