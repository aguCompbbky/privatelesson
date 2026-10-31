import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source_exception.dart';
import 'package:privatelesson/features/lesson_listings/data/dtos/lesson_listing_dto.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';

/// Raw document record returned by [FirestoreListingStore].
final class FirestoreListingDocument {
  /// Creates a document record pairing its [id] with its stored [data].
  const FirestoreListingDocument({
    required this.id,
    required this.data,
  });

  /// Firestore document identifier.
  final String id;

  /// Raw field map read from Firestore.
  final Map<String, Object?> data;
}

/// Replaceable store gateway keeping [FirestoreLessonListingDataSource]
/// deterministically unit-testable without native Firestore channels.
abstract interface class FirestoreListingStore {
  /// Queries documents matching optional [deliveryMode] and [hasCertificate].
  Future<List<FirestoreListingDocument>> queryDocuments({
    String? deliveryMode,
    bool? hasCertificate,
  });

  /// Reads a single document by [id], or returns null when absent.
  Future<FirestoreListingDocument?> readDocument(String id);

  /// Allocates a new unique document identifier.
  String allocateDocumentId();

  /// Writes [data] under [id].
  Future<void> writeDocument(String id, Map<String, Object?> data);
}

/// Concrete [LessonListingDataSource] backed by Cloud Firestore.
///
/// Cloud Firestore dependencies remain strictly inside this adapter.
final class FirestoreLessonListingDataSource
    implements LessonListingDataSource {
  /// Creates a listing data source using [store] or lazy `FirebaseFirestore`.
  FirestoreLessonListingDataSource({
    FirestoreListingStore? store,
    String collectionPath = defaultCollectionPath,
  }) : _store = store ?? _SdkFirestoreListingStore(collectionPath);

  /// Default Firestore collection storing published lesson listings.
  static const String defaultCollectionPath = 'lesson_listings';

  static const String _idKey = 'id';
  static const String _deliveryModeKey = 'deliveryMode';
  static const String _hasCertificateKey = 'hasCertificate';

  final FirestoreListingStore _store;

  @override
  Future<List<LessonListingDto>> fetchListings(
    LessonListingFilter filter,
  ) => _guardFirestore(() async {
    final documents = await _store.queryDocuments(
      deliveryMode: filter.deliveryMode?.name,
      hasCertificate: filter.hasCertificateOnly ? true : null,
    );
    final query = _foldTurkish(filter.searchQuery.trim());
    final results = <LessonListingDto>[];
    for (final document in documents) {
      final dto = _toDto(document);
      final matchesMode =
          filter.deliveryMode == null ||
          dto.deliveryMode == filter.deliveryMode?.name;
      final matchesCertificate =
          !filter.hasCertificateOnly || dto.hasCertificate;
      final matchesText =
          query.isEmpty ||
          _foldTurkish(dto.subject).contains(query) ||
          _foldTurkish(dto.teacherName).contains(query);
      if (matchesMode && matchesCertificate && matchesText) {
        results.add(dto);
      }
    }
    return List<LessonListingDto>.unmodifiable(results);
  });

  @override
  Future<LessonListingDto> fetchListingById(String id) =>
      _guardFirestore(() async {
        final trimmedId = id.trim();
        if (trimmedId.isEmpty) {
          throw const LessonListingDataSourceException(
            LessonListingDataSourceError.notFound,
          );
        }
        final document = await _store.readDocument(trimmedId);
        if (document == null) {
          throw const LessonListingDataSourceException(
            LessonListingDataSourceError.notFound,
          );
        }
        return _toDto(document);
      });

  @override
  Future<LessonListingDto> insertListing(NewLessonListing listing) =>
      _guardFirestore(() async {
        final id = _store.allocateDocumentId();
        final dto = LessonListingDto.fromNewListing(listing, id: id);
        await _store.writeDocument(id, dto.toMap());
        return dto;
      });

  LessonListingDto _toDto(FirestoreListingDocument document) =>
      LessonListingDto.fromMap(<String, Object?>{
        ...document.data,
        _idKey: document.data[_idKey] ?? document.id,
      });

  Future<T> _guardFirestore<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on LessonListingDataSourceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw LessonListingDataSourceException(switch (error.code) {
        'unavailable' ||
        'deadline-exceeded' ||
        'network-request-failed' => LessonListingDataSourceError.connection,
        'not-found' => LessonListingDataSourceError.notFound,
        _ => LessonListingDataSourceError.storage,
      });
    }
  }

  static String _foldTurkish(String value) =>
      value.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
}

final class _SdkFirestoreListingStore implements FirestoreListingStore {
  const _SdkFirestoreListingStore(this._collectionPath);

  final String _collectionPath;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(_collectionPath);

  @override
  Future<List<FirestoreListingDocument>> queryDocuments({
    String? deliveryMode,
    bool? hasCertificate,
  }) async {
    Query<Map<String, dynamic>> query = _collection;
    if (deliveryMode != null) {
      query = query.where(
        FirestoreLessonListingDataSource._deliveryModeKey,
        isEqualTo: deliveryMode,
      );
    }
    if (hasCertificate != null) {
      query = query.where(
        FirestoreLessonListingDataSource._hasCertificateKey,
        isEqualTo: hasCertificate,
      );
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => FirestoreListingDocument(
            id: doc.id,
            data: Map<String, Object?>.from(doc.data()),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<FirestoreListingDocument?> readDocument(String id) async {
    final snapshot = await _collection.doc(id).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return FirestoreListingDocument(
      id: snapshot.id,
      data: Map<String, Object?>.from(data),
    );
  }

  @override
  String allocateDocumentId() => _collection.doc().id;

  @override
  Future<void> writeDocument(String id, Map<String, Object?> data) async {
    await _collection.doc(id).set(Map<String, dynamic>.from(data));
  }
}
