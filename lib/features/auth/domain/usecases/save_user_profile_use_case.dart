import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/user_profile_repository.dart';

/// Validates and saves the user's chosen profile independently of sign-in.
final class SaveUserProfileUseCase {
  /// Creates the use case with its profile repository.
  const SaveUserProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  /// Trims the identifier and name, then returns the saved profile.
  ///
  /// Throws [ProfileFailure] for empty input and propagates repository
  /// failures unchanged.
  Future<UserProfile> call({
    required String userId,
    required String displayName,
    required UserRole role,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedDisplayName = displayName.trim();
    if (normalizedUserId.isEmpty) {
      throw const ProfileFailure(ProfileFailureType.invalidUserId);
    }
    if (normalizedDisplayName.isEmpty) {
      throw const ProfileFailure(ProfileFailureType.invalidDisplayName);
    }
    return _repository.saveProfile(
      UserProfile(
        userId: normalizedUserId,
        displayName: normalizedDisplayName,
        role: role,
      ),
    );
  }
}
