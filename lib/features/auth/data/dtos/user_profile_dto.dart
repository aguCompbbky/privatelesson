import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';

/// The storage payload for a completed profile, without email fields.
final class UserProfileDto {
  /// Creates a profile payload using a storage role string.
  const UserProfileDto({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  /// Reads required fields, rejecting blank values and unsupported roles.
  ///
  /// Throws [FormatException] for malformed fields; extra keys are discarded.
  factory UserProfileDto.fromMap(Map<String, Object?> map) {
    final userId = map[_userIdKey];
    final displayName = map[_displayNameKey];
    final role = map[_roleKey];
    if (userId is! String ||
        userId.trim().isEmpty ||
        displayName is! String ||
        displayName.trim().isEmpty ||
        role is! String ||
        (role != _studentRole && role != _teacherRole)) {
      throw const FormatException(_invalidProfileMessage);
    }
    return UserProfileDto(
      userId: userId,
      displayName: displayName,
      role: role,
    );
  }

  /// Converts a domain profile to the provider-independent storage format.
  factory UserProfileDto.fromEntity(UserProfile profile) => UserProfileDto(
    userId: profile.userId,
    displayName: profile.displayName,
    role: switch (profile.role) {
      UserRole.student => _studentRole,
      UserRole.teacher => _teacherRole,
    },
  );

  static const String _userIdKey = 'userId';
  static const String _displayNameKey = 'displayName';
  static const String _roleKey = 'role';
  static const String _studentRole = 'student';
  static const String _teacherRole = 'teacher';
  static const String _invalidProfileMessage =
      'Profile requires nonblank userId, displayName and a supported role.';

  /// The identifier linking the payload to an authenticated identity.
  final String userId;

  /// The user's chosen display name.
  final String displayName;

  /// The stored role, either student or teacher.
  final String role;

  /// Writes only profile fields, excluding authentication or contact emails.
  Map<String, Object?> toMap() => {
    _userIdKey: userId,
    _displayNameKey: displayName,
    _roleKey: role,
  };

  /// Maps the payload to a domain profile, rejecting unsupported role strings.
  UserProfile toEntity() => UserProfile(
    userId: userId,
    displayName: displayName,
    role: switch (role) {
      _studentRole => UserRole.student,
      _teacherRole => UserRole.teacher,
      _ => throw const FormatException(_invalidProfileMessage),
    },
  );
}
