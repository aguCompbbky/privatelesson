import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/user_profile_dto.dart';

const _student = UserProfileDto(
  userId: 'profile-user',
  displayName: 'Student User',
  role: 'student',
);
const _updated = UserProfileDto(
  userId: 'profile-user',
  displayName: 'Teacher User',
  role: 'teacher',
);
const _otherUser = UserProfileDto(
  userId: 'other-user',
  displayName: 'Other User',
  role: 'teacher',
);

/// Verifies profile persistence, independent users and injected failures.
void main() {
  group('MockUserProfileDataSource', () {
    test('starts empty and returns null before the first save', () async {
      final source = MockUserProfileDataSource();

      expect(await source.fetchProfile(_student.userId), isNull);
      expect(await source.fetchProfile(_otherUser.userId), isNull);
    });

    for (final profile in [_student, _updated]) {
      test(
        'preserves the saved ${profile.role} profile across reads',
        () async {
          final source = MockUserProfileDataSource();

          final saved = await source.upsertProfile(profile);
          final firstRead = await source.fetchProfile(profile.userId);
          final laterRead = await source.fetchProfile(profile.userId);

          expect(saved.toMap(), profile.toMap());
          expect(firstRead?.toMap(), profile.toMap());
          expect(laterRead?.toMap(), profile.toMap());
        },
      );
    }

    test('updates one user without replacing another user', () async {
      final source = MockUserProfileDataSource();
      await source.upsertProfile(_student);
      await source.upsertProfile(_otherUser);

      final saved = await source.upsertProfile(_updated);

      expect(saved.toMap(), _updated.toMap());
      expect(
        (await source.fetchProfile(_student.userId))?.toMap(),
        _updated.toMap(),
      );
      expect(
        (await source.fetchProfile(_otherUser.userId))?.toMap(),
        _otherUser.toMap(),
      );
    });

    test('keeps separate source instances isolated', () async {
      final source = MockUserProfileDataSource();
      final otherSource = MockUserProfileDataSource();
      await source.upsertProfile(_student);

      expect(await otherSource.fetchProfile(_student.userId), isNull);
    });

    test(
      'injects read failures without blocking writes or losing data',
      () async {
        final exception = Exception('Read unavailable');
        final source = MockUserProfileDataSource(readException: exception);

        await expectLater(
          source.fetchProfile(_student.userId),
          throwsA(same(exception)),
        );
        await source.upsertProfile(_student);
        await expectLater(
          source.fetchProfile(_student.userId),
          throwsA(same(exception)),
        );
        source.readException = null;

        expect(
          (await source.fetchProfile(_student.userId))?.toMap(),
          _student.toMap(),
        );
      },
    );

    test('a failed first write leaves the profile absent', () async {
      final exception = Exception('Write unavailable');
      final source = MockUserProfileDataSource(writeException: exception);

      await expectLater(
        source.upsertProfile(_student),
        throwsA(same(exception)),
      );

      expect(await source.fetchProfile(_student.userId), isNull);
    });

    test('a failed update preserves saved data and allows retry', () async {
      final source = MockUserProfileDataSource();
      await source.upsertProfile(_student);
      final exception = Exception('Write unavailable');
      source.writeException = exception;

      await expectLater(
        source.upsertProfile(_updated),
        throwsA(same(exception)),
      );
      expect(
        (await source.fetchProfile(_student.userId))?.toMap(),
        _student.toMap(),
      );
      source.writeException = null;
      await source.upsertProfile(_updated);

      expect(
        (await source.fetchProfile(_student.userId))?.toMap(),
        _updated.toMap(),
      );
    });
  });
}
