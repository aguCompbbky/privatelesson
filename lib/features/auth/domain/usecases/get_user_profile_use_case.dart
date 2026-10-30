import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';
import 'package:privatelesson/features/auth/domain/repositories/user_profile_repository.dart';

/// Loads the saved profile without treating a missing profile as a failure.
final class GetUserProfileUseCase {
  /// Creates the use case with its profile repository.
  const GetUserProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  /// Trims the identifier and returns the profile or null on first use.
  ///
  /// Throws [ProfileFailure] for an empty identifier and propagates failures
  /// from the repository unchanged.
  Future<UserProfile?> call(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const ProfileFailure(ProfileFailureType.invalidUserId);
    }
    return _repository.getProfile(normalizedUserId);
  }
}
