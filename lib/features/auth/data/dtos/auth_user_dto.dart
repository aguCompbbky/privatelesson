import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';

/// The minimal user payload used by the mock authentication source.
final class AuthUserDto {
  /// Creates a user payload without any SDK objects.
  const AuthUserDto({required this.userId, required this.displayName});

  /// Reads the mock map format, rejecting missing or non-string user fields.
  ///
  /// Throws [FormatException] for invalid fields; additional keys are ignored.
  factory AuthUserDto.fromMap(Map<String, Object?> map) {
    final userId = map[_userIdKey];
    final displayName = map[_displayNameKey];
    if (userId is! String || displayName is! String) {
      throw const FormatException(_invalidUserMapMessage);
    }
    return AuthUserDto(userId: userId, displayName: displayName);
  }

  static const String _userIdKey = 'userId';
  static const String _displayNameKey = 'displayName';
  static const String _invalidUserMapMessage =
      'Auth user payload requires string userId and displayName fields.';

  /// The identifier provided by the data source.
  final String userId;

  /// The display name provided by the data source.
  final String displayName;

  /// Writes the mock map format without serialisation packages.
  Map<String, Object?> toMap() => {
    _userIdKey: userId,
    _displayNameKey: displayName,
  };

  /// Maps the data payload into the provider-independent domain identity.
  AuthSession toEntity() =>
      AuthSession(userId: userId, displayName: displayName);
}
