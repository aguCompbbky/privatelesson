import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';

const _userId = 'profile-user';
const _displayName = 'Profile User';

/// Verifies profile fields for both student and teacher roles.
void main() {
  group('UserProfile', () {
    for (final role in UserRole.values) {
      test('retains all fields for a ${role.name} profile', () {
        final profile = UserProfile(
          userId: _userId,
          displayName: _displayName,
          role: role,
        );

        expect(profile, _profileWithRole(role));
      });
    }
  });
}

Matcher _profileWithRole(UserRole role) => isA<UserProfile>()
    .having((profile) => profile.userId, 'userId', _userId)
    .having((profile) => profile.displayName, 'displayName', _displayName)
    .having((profile) => profile.role, 'role', role);
