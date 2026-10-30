import 'package:privatelesson/features/auth/data/datasources/user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/user_profile_dto.dart';

/// Stores profiles for this instance's lifetime without external services.
final class MockUserProfileDataSource implements UserProfileDataSource {
  /// Creates an empty source with optional read and write exception injection.
  MockUserProfileDataSource({this.readException, this.writeException});

  final Map<String, UserProfileDto> _profiles = {};

  /// The exception thrown on reads; set to null to allow reads again.
  Exception? readException;

  /// The exception thrown before writes; set to null to allow writes again.
  Exception? writeException;

  /// Returns the saved profile and role, or null before the first save.
  @override
  Future<UserProfileDto?> fetchProfile(String userId) async {
    final exception = readException;
    if (exception != null) {
      throw exception;
    }
    return _profiles[userId];
  }

  /// Inserts or replaces a profile unless a write exception is configured.
  @override
  Future<UserProfileDto> upsertProfile(UserProfileDto profile) async {
    final exception = writeException;
    if (exception != null) {
      throw exception;
    }
    _profiles[profile.userId] = profile;
    return profile;
  }
}
