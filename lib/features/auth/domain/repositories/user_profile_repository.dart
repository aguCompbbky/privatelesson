import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';

/// Provides completed profiles independently of the storage provider.
abstract interface class UserProfileRepository {
  /// Returns the saved profile and role, or null before profile completion.
  ///
  /// Throws [ProfileFailure] if the profile cannot be loaded.
  Future<UserProfile?> getProfile(String userId);

  /// Saves the profile and returns the stored values.
  ///
  /// Throws [ProfileFailure] if the profile cannot be saved.
  Future<UserProfile> saveProfile(UserProfile profile);
}
