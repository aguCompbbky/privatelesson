import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';

const _userId = 'mock-user';
const _displayName = 'Mock User';
const _userIdKey = 'userId';
const _displayNameKey = 'displayName';
const _validMap = <String, Object?>{
  _userIdKey: _userId,
  _displayNameKey: _displayName,
};

/// Verifies the mock payload format and its conversion at the data boundary.
void main() {
  group('AuthUserDto', () {
    test('reads identity fields from the mock map format', () {
      final dto = AuthUserDto.fromMap(_validMap);

      expect(dto.userId, _userId);
      expect(dto.displayName, _displayName);
    });

    test('writes only the identity fields in the mock map format', () {
      const dto = AuthUserDto(userId: _userId, displayName: _displayName);

      expect(dto.toMap(), _validMap);
    });

    test('converts the payload into a domain session', () {
      final dto = AuthUserDto.fromMap(_validMap);

      final session = dto.toEntity();

      expect(session.userId, _userId);
      expect(session.displayName, _displayName);
    });

    test('ignores additional provider fields', () {
      const extraFieldKey = 'providerOnly';
      const extraFieldValue = 'ignored';
      final dto = AuthUserDto.fromMap({
        _userIdKey: _userId,
        _displayNameKey: _displayName,
        extraFieldKey: extraFieldValue,
      });

      expect(dto.toMap(), _validMap);
    });

    const invalidMaps = <String, Map<String, Object?>>{
      'missing userId': {_displayNameKey: _displayName},
      'missing displayName': {_userIdKey: _userId},
      'null userId': {_userIdKey: null, _displayNameKey: _displayName},
      'null displayName': {_userIdKey: _userId, _displayNameKey: null},
      'non-string userId': {_userIdKey: true, _displayNameKey: _displayName},
      'non-string displayName': {_userIdKey: _userId, _displayNameKey: false},
    };

    for (final entry in invalidMaps.entries) {
      test('rejects ${entry.key}', () {
        expect(
          () => AuthUserDto.fromMap(entry.value),
          throwsA(isA<FormatException>()),
        );
      });
    }
  });
}
