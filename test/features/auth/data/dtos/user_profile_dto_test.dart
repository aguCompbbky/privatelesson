import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/data/dtos/user_profile_dto.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';

const _userId = 'profile-user';
const _displayName = 'Profile User';
const _validMap = <String, Object?>{
  'userId': _userId,
  'displayName': _displayName,
  'role': 'student',
};
const _roles = <String, UserRole>{
  'student': UserRole.student,
  'teacher': UserRole.teacher,
};

/// Verifies the storage format, domain mapping and malformed payload handling.
void main() {
  group('UserProfileDto', () {
    for (final entry in _roles.entries) {
      final map = Map<String, Object?>.of(_validMap);
      map['role'] = entry.key;
      final profile = UserProfile(
        userId: _userId,
        displayName: _displayName,
        role: entry.value,
      );

      test('reads and writes all fields for ${entry.key}', () {
        final dto = UserProfileDto.fromMap(map);

        expect(dto.userId, _userId);
        expect(dto.displayName, _displayName);
        expect(dto.role, entry.key);
        expect(dto.toMap(), map);
      });

      test('converts ${entry.key} payload to a domain profile', () {
        final dto = UserProfileDto.fromMap(map);

        expect(dto.toEntity(), _matchesProfile(profile));
      });

      test('converts ${entry.key} profile to a storage payload', () {
        final dto = UserProfileDto.fromEntity(profile);

        expect(dto.userId, _userId);
        expect(dto.displayName, _displayName);
        expect(dto.role, entry.key);
        expect(dto.toMap(), map);
        expect(dto.toEntity(), _matchesProfile(profile));
      });
    }

    test('discards authentication and contact email fields', () {
      final map = Map<String, Object?>.of(_validMap);
      map['email'] = 'authentication@example.invalid';
      map['contactEmail'] = 'contact@example.invalid';

      final dto = UserProfileDto.fromMap(map);

      expect(dto.toMap(), _validMap);
    });

    test('returns maps that cannot mutate the DTO', () {
      final dto = UserProfileDto.fromMap(_validMap);
      final map = dto.toMap();
      map['role'] = 'teacher';

      expect(dto.toMap(), _validMap);
    });

    test('rejects an empty map', () {
      expect(
        () => UserProfileDto.fromMap({}),
        throwsA(isA<FormatException>()),
      );
    });

    for (final field in _validMap.keys) {
      test('rejects missing $field', () {
        final map = Map<String, Object?>.of(_validMap);
        map.remove(field);

        expect(
          () => UserProfileDto.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      });

      for (final invalid in <Object?>[
        null,
        42,
        true,
        <String>[],
        '',
        ' \t\n ',
      ]) {
        test('rejects $field containing $invalid', () {
          final map = Map<String, Object?>.of(_validMap);
          map[field] = invalid;

          expect(
            () => UserProfileDto.fromMap(map),
            throwsA(isA<FormatException>()),
          );
        });
      }
    }

    for (final role in ['admin', 'Teacher', ' student ', 'student,teacher']) {
      test('rejects unsupported role $role', () {
        final map = Map<String, Object?>.of(_validMap);
        map['role'] = role;

        expect(
          () => UserProfileDto.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('rejects a directly constructed unsupported role at conversion', () {
      const dto = UserProfileDto(
        userId: _userId,
        displayName: _displayName,
        role: 'admin',
      );

      expect(dto.toEntity, throwsA(isA<FormatException>()));
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
