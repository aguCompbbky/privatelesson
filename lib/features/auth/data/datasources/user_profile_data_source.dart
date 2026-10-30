import 'package:privatelesson/features/auth/data/dtos/user_profile_dto.dart';

/// The replaceable data-layer contract for profile persistence.
abstract interface class UserProfileDataSource {
  /// Returns the stored payload, or null when the user has no profile.
  ///
  /// Provider exceptions and malformed payloads are mapped by the repository.
  Future<UserProfileDto?> fetchProfile(String userId);

  /// Inserts or replaces a profile and returns the stored payload.
  ///
  /// Provider exceptions are mapped by the repository.
  Future<UserProfileDto> upsertProfile(UserProfileDto profile);
}
