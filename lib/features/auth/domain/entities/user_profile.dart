import 'package:privatelesson/features/auth/domain/entities/user_role.dart';

/// A completed profile, independent of authentication and contact details.
final class UserProfile {
  /// Creates a profile with one role and the user's chosen display name.
  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  /// The identifier linking this profile to an authenticated identity.
  final String userId;

  /// The user's chosen display name.
  final String displayName;

  /// The user's single selected role.
  final UserRole role;
}
