import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/firestore_lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source_exception.dart';
import 'package:privatelesson/features/lesson_listings/data/repositories/lesson_listing_repository_impl.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/certification_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';

final class _InMemoryFirestoreListingStore implements FirestoreListingStore {
  final Map<String, Map<String, Object?>> documents = {};
  int _nextId = 1;
  Exception? error;
  String? lastQueriedMode;
  bool? lastQueriedCertificate;

  @override
  Future<List<FirestoreListingDocument>> queryDocuments({
    String? deliveryMode,
    bool? hasCertificate,
  }) async {
    final activeError = error;
    if (activeError != null) {
      throw activeError;
    }
    lastQueriedMode = deliveryMode;
    lastQueriedCertificate = hasCertificate;
    return documents.entries
        .where((entry) {
          final modeMatches =
              deliveryMode == null ||
              entry.value['deliveryMode'] == deliveryMode;
          final certMatches =
              hasCertificate == null ||
              entry.value['hasCertificate'] == hasCertificate;
          return modeMatches && certMatches;
        })
        .map(
          (entry) => FirestoreListingDocument(
            id: entry.key,
            data: Map<String, Object?>.from(entry.value),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<FirestoreListingDocument?> readDocument(String id) async {
    final activeError = error;
    if (activeError != null) {
      throw activeError;
    }
    final stored = documents[id];
    if (stored == null) {
      return null;
    }
    return FirestoreListingDocument(
      id: id,
      data: Map<String, Object?>.from(stored),
    );
  }

  @override
  String allocateDocumentId() {
    final id = 'firestore-lesson-$_nextId';
    _nextId += 1;
    return id;
  }

  @override
  Future<void> writeDocument(String id, Map<String, Object?> data) async {
    final activeError = error;
    if (activeError != null) {
      throw activeError;
    }
    documents[id] = Map<String, Object?>.from(data);
  }
}

void main() {
  group('FirestoreLessonListingDataSource', () {
    test(
      'inserts, reads by id, and filters with Turkish case folding',
      () async {
        final store = _InMemoryFirestoreListingStore();
        final source = FirestoreLessonListingDataSource(store: store);

        final created = await source.insertListing(
          const NewLessonListing(
            teacherId: 'teacher-1',
            teacherName: 'İpek Yılmaz',
            subject: 'İstatistik ve Matematik',
            description: 'Uygulamalı birebir ders.',
            deliveryMode: LessonDeliveryMode.online,
            certification: CertificationInfo(
              hasCertificate: true,
              certificateDescription: 'Yüksek lisans diploması',
            ),
            contact: TeacherContactInfo(whatsAppNumber: '+905551112233'),
          ),
        );
        expect(created.id, 'firestore-lesson-1');

        store.documents['firestore-lesson-2'] = <String, Object?>{
          'teacherId': 'teacher-2',
          'teacherName': 'Işıl Kaya',
          'subject': 'Fizik',
          'description': 'Temel fizik dersleri.',
          'deliveryMode': 'inPerson',
          'hasCertificate': false,
          'emailAddress': 'isil@example.com',
        };

        final fetchedById = await source.fetchListingById('firestore-lesson-2');
        expect(fetchedById.id, 'firestore-lesson-2');
        expect(fetchedById.teacherName, 'Işıl Kaya');

        final turkishDotlessSearch = await source.fetchListings(
          const LessonListingFilter(searchQuery: 'ışıl'),
        );
        expect(turkishDotlessSearch.map((e) => e.id), ['firestore-lesson-2']);

        final turkishDottedSearch = await source.fetchListings(
          const LessonListingFilter(
            searchQuery: 'ipek',
            deliveryMode: LessonDeliveryMode.online,
            hasCertificateOnly: true,
          ),
        );
        expect(store.lastQueriedMode, 'online');
        expect(store.lastQueriedCertificate, isTrue);
        expect(turkishDottedSearch.map((e) => e.id), ['firestore-lesson-1']);
      },
    );

    test('reports notFound for blank or missing document ids', () async {
      final store = _InMemoryFirestoreListingStore();
      final source = FirestoreLessonListingDataSource(store: store);

      for (final candidate in ['   ', 'unknown-id']) {
        await expectLater(
          source.fetchListingById(candidate),
          throwsA(
            isA<LessonListingDataSourceException>().having(
              (e) => e.type,
              'type',
              LessonListingDataSourceError.notFound,
            ),
          ),
        );
      }
    });

    test('maps FirebaseException codes cleanly to domain failures', () async {
      final store = _InMemoryFirestoreListingStore();
      final repository = LessonListingRepositoryImpl(
        FirestoreLessonListingDataSource(store: store),
      );

      final expectedMappings = <String, LessonListingFailureType>{
        'unavailable': LessonListingFailureType.connection,
        'deadline-exceeded': LessonListingFailureType.connection,
        'network-request-failed': LessonListingFailureType.connection,
        'not-found': LessonListingFailureType.notFound,
        'permission-denied': LessonListingFailureType.storage,
      };

      for (final entry in expectedMappings.entries) {
        store.error = FirebaseException(
          plugin: 'cloud_firestore',
          code: entry.key,
        );
        await expectLater(
          repository.getListings(const LessonListingFilter()),
          throwsA(
            isA<LessonListingFailure>().having(
              (e) => e.type,
              'type',
              entry.value,
            ),
          ),
        );
      }
    });
  });
}
