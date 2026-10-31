import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:privatelesson/features/auth/data/datasources/user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/user_profile_dto.dart';

/// Replaceable document gateway keeping [FirestoreUserProfileDataSource]
/// testable without native Firestore channels.
abstract interface class FirestoreProfileStore {
  /// Reads a document snapshot map by [documentId], or null when absent.
  Future<Map<String, Object?>?> readDocument(String documentId);

  /// Writes [data] under [documentId], replacing any existing payload.
  Future<void> writeDocument(String documentId, Map<String, Object?> data);
}

/// Concrete [UserProfileDataSource] backed by Cloud Firestore.
///
/// Cloud Firestore imports remain strictly inside this data-source adapter.
final class FirestoreUserProfileDataSource implements UserProfileDataSource {
  /// Creates a profile data source using [store] or lazy `FirebaseFirestore`.
  FirestoreUserProfileDataSource({
    FirestoreProfileStore? store,
    String collectionPath = defaultCollectionPath,
  }) : _store = store ?? _SdkFirestoreProfileStore(collectionPath);

  /// Default Firestore collection storing completed user profiles.
  static const String defaultCollectionPath = 'user_profiles';

  static const String _userIdKey = 'userId';

  final FirestoreProfileStore _store;

  @override
  Future<UserProfileDto?> fetchProfile(String userId) async {
    final trimmedId = userId.trim();
    if (trimmedId.isEmpty) {
      return null;
    }
    final data = await _store.readDocument(trimmedId);
    if (data == null) {
      return null;
    }
    final normalized = <String, Object?>{
      ...data,
      _userIdKey: data[_userIdKey] ?? trimmedId,
    };
    return UserProfileDto.fromMap(normalized);
  }

  @override
  Future<UserProfileDto> upsertProfile(UserProfileDto profile) async {
    final payload = profile.toMap();
    await _store.writeDocument(profile.userId, payload);
    return UserProfileDto.fromMap(payload);
  }
}

final class _SdkFirestoreProfileStore implements FirestoreProfileStore {
  const _SdkFirestoreProfileStore(this._collectionPath);

  final String _collectionPath;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(_collectionPath);

  @override
  Future<Map<String, Object?>?> readDocument(String documentId) async {
    final snapshot = await _collection.doc(documentId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return Map<String, Object?>.from(data);
  }

  @override
  Future<void> writeDocument(
    String documentId,
    Map<String, Object?> data,
  ) async {
    await _collection.doc(documentId).set(Map<String, dynamic>.from(data));
  }
}
