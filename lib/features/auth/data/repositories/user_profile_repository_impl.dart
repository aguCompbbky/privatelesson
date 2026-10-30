import 'package:privatelesson/features/auth/data/datasources/user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/user_profile_dto.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/user_profile_repository.dart';

/// Converts profile payloads and storage exceptions into domain types.
final class UserProfileRepositoryImpl implements UserProfileRepository {
  /// Creates a repository using any adapter for the profile source contract.
  const UserProfileRepositoryImpl(this._dataSource);

  final UserProfileDataSource _dataSource;

  /// Returns the saved profile or null, mapping exceptions to load failures.
  ///
  /// Includes malformed payloads; programming errors are not intercepted.
  @override
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final profile = await _dataSource.fetchProfile(userId);
      return profile?.toEntity();
    } on Exception {
      throw const ProfileFailure(ProfileFailureType.loadFailed);
    }
  }

  /// Returns the stored profile, mapping storage or format exceptions.
  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    try {
      final storedProfile = await _dataSource.upsertProfile(
        UserProfileDto.fromEntity(profile),
      );
      return storedProfile.toEntity();
    } on Exception {
      throw const ProfileFailure(ProfileFailureType.saveFailed);
    }
  }
}
