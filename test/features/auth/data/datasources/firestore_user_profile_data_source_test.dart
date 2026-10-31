import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/data/datasources/firestore_user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/user_profile_dto.dart';
import 'package:privatelesson/features/auth/data/repositories/user_profile_repository_impl.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';

final class _InMemoryFirestoreProfileStore implements FirestoreProfileStore {
  final Map<String, Map<String, Object?>> documents = {};
  Exception? error;

  @override
  Future<Map<String, Object?>?> readDocument(String documentId) async {
    final activeError = error;
    if (activeError != null) {
      throw activeError;
    }
    final stored = documents[documentId];
    return stored == null ? null : Map<String, Object?>.from(stored);
  }

  @override
  Future<void> writeDocument(
    String documentId,
    Map<String, Object?> data,
  ) async {
    final activeError = error;
    if (activeError != null) {
      throw activeError;
    }
    documents[documentId] = Map<String, Object?>.from(data);
  }
}

void main() {
  group('FirestoreUserProfileDataSource', () {
    test('returns null for blank id or missing document', () async {
      final store = _InMemoryFirestoreProfileStore();
      final source = FirestoreUserProfileDataSource(store: store);

      expect(await source.fetchProfile('   '), isNull);
      expect(await source.fetchProfile('missing-user'), isNull);
    });

    test(
      'upserts and reads profile, filling missing userId from doc id',
      () async {
        final store = _InMemoryFirestoreProfileStore();
        final source = FirestoreUserProfileDataSource(store: store);
        const dto = UserProfileDto(
          userId: 'user-42',
          displayName: 'Deniz Kaya',
          role: 'teacher',
        );

        final saved = await source.upsertProfile(dto);
        expect(saved.userId, 'user-42');
        expect(saved.displayName, 'Deniz Kaya');
        expect(saved.role, 'teacher');

        store.documents['user-99'] = <String, Object?>{
          'displayName': 'Ece Yılmaz',
          'role': 'student',
        };
        final hydrated = await source.fetchProfile('user-99');
        expect(hydrated, isNotNull);
        expect(hydrated!.userId, 'user-99');
        expect(hydrated.displayName, 'Ece Yılmaz');
        expect(hydrated.role, 'student');
      },
    );

    test(
      'maps Firestore errors cleanly through UserProfileRepositoryImpl',
      () async {
        final store = _InMemoryFirestoreProfileStore();
        store.error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
        final repository = UserProfileRepositoryImpl(
          FirestoreUserProfileDataSource(store: store),
        );

        await expectLater(
          repository.getProfile('user-1'),
          throwsA(
            isA<ProfileFailure>().having(
              (e) => e.type,
              'type',
              ProfileFailureType.loadFailed,
            ),
          ),
        );

        await expectLater(
          repository.saveProfile(
            const UserProfile(
              userId: 'user-1',
              displayName: 'User One',
              role: UserRole.student,
            ),
          ),
          throwsA(
            isA<ProfileFailure>().having(
              (e) => e.type,
              'type',
              ProfileFailureType.saveFailed,
            ),
          ),
        );
      },
    );
  });
}
