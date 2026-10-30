import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source_exception.dart';
import 'package:privatelesson/features/lesson_listings/data/dtos/lesson_listing_dto.dart';
import 'package:privatelesson/features/lesson_listings/data/repositories/lesson_listing_repository_impl.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/certification_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/lesson_listing_repository.dart';

const _dto = LessonListingDto(
  id: 'stored-listing',
  teacherId: 'teacher-1',
  teacherName: 'İpek Yılmaz',
  subject: 'Stored subject',
  description: 'Stored description',
  deliveryMode: 'online',
  hasCertificate: true,
  certificateDescription: 'Declared certificate',
  whatsAppNumber: '+905550000001',
  emailAddress: 'contact@example.invalid',
);
const _newListing = NewLessonListing(
  teacherId: 'teacher-1',
  teacherName: 'İpek Yılmaz',
  subject: 'Submitted subject',
  description: 'Submitted description',
  deliveryMode: LessonDeliveryMode.online,
  certification: CertificationInfo(hasCertificate: false),
  contact: TeacherContactInfo(emailAddress: 'contact@example.invalid'),
);
const _invalidDto = LessonListingDto(
  id: 'invalid-listing',
  teacherId: 'teacher-1',
  teacherName: 'İpek Yılmaz',
  subject: 'Matematik',
  description: 'Konu anlatımı.',
  deliveryMode: 'unsupported',
  hasCertificate: false,
  emailAddress: 'contact@example.invalid',
);

/// Verifies delegation, DTO conversion and error mapping on every operation.
void main() {
  group('LessonListingRepositoryImpl', () {
    test('forwards every filter and converts returned listings', () async {
      final source = _RecordingDataSource();
      final repository = LessonListingRepositoryImpl(source);
      const filter = LessonListingFilter(
        searchQuery: 'İpek',
        deliveryMode: LessonDeliveryMode.online,
        hasCertificateOnly: true,
      );

      final listings = await repository.getListings(filter);

      expect(source.filters, [same(filter)]);
      expect(source.ids, isEmpty);
      expect(source.inserted, isEmpty);
      expect(listings, hasLength(1));
      _expectStoredListing(listings.single);
    });

    test('preserves empty results', () async {
      final source = _RecordingDataSource(emptyResults: true);
      final repository = LessonListingRepositoryImpl(source);

      final listings = await repository.getListings(
        const LessonListingFilter(),
      );

      expect(listings, isEmpty);
    });

    test('forwards the requested id and converts its payload', () async {
      final source = _RecordingDataSource();
      final repository = LessonListingRepositoryImpl(source);

      final listing = await repository.getListingById('requested-id');

      expect(source.ids, ['requested-id']);
      expect(source.filters, isEmpty);
      expect(source.inserted, isEmpty);
      _expectStoredListing(listing);
    });

    test('forwards new data and returns values assigned by storage', () async {
      final source = _RecordingDataSource();
      final repository = LessonListingRepositoryImpl(source);

      final listing = await repository.createListing(_newListing);

      expect(source.inserted, [same(_newListing)]);
      expect(source.ids, isEmpty);
      expect(source.filters, isEmpty);
      _expectStoredListing(listing);
      expect(listing.subject, isNot(_newListing.subject));
    });

    final operations =
        <String, Future<Object> Function(LessonListingRepository)>{
          'list': (repository) =>
              repository.getListings(const LessonListingFilter()),
          'detail': (repository) => repository.getListingById('requested-id'),
          'create': (repository) => repository.createListing(_newListing),
        };
    const failureMappings = {
      LessonListingDataSourceError.connection:
          LessonListingFailureType.connection,
      LessonListingDataSourceError.notFound: LessonListingFailureType.notFound,
      LessonListingDataSourceError.storage: LessonListingFailureType.storage,
    };

    for (final operation in operations.entries) {
      for (final mapping in failureMappings.entries) {
        test('${operation.key} maps ${mapping.key.name}', () async {
          final source = _RecordingDataSource(
            exception: LessonListingDataSourceException(mapping.key),
          );
          final repository = LessonListingRepositoryImpl(source);

          await expectLater(
            operation.value(repository),
            throwsA(_failureWithType(mapping.value)),
          );
        });
      }

      test('${operation.key} maps source format failures', () async {
        final source = _RecordingDataSource(
          exception: const FormatException('Malformed source data'),
        );
        final repository = LessonListingRepositoryImpl(source);

        await expectLater(
          operation.value(repository),
          throwsA(_failureWithType(LessonListingFailureType.storage)),
        );
      });

      test('${operation.key} maps DTO conversion failures', () async {
        final source = _RecordingDataSource(dto: _invalidDto);
        final repository = LessonListingRepositoryImpl(source);

        await expectLater(
          operation.value(repository),
          throwsA(_failureWithType(LessonListingFailureType.storage)),
        );
      });

      test('${operation.key} preserves unrelated exceptions', () async {
        final exception = Exception('Unrelated failure');
        final source = _RecordingDataSource(exception: exception);
        final repository = LessonListingRepositoryImpl(source);

        await expectLater(
          operation.value(repository),
          throwsA(same(exception)),
        );
      });

      test('${operation.key} preserves programming errors', () async {
        final error = StateError('Programming error');
        final source = _RecordingDataSource(error: error);
        final repository = LessonListingRepositoryImpl(source);

        await expectLater(operation.value(repository), throwsA(same(error)));
      });
    }
  });
}

void _expectStoredListing(LessonListing listing) {
  expect(listing.id, _dto.id);
  expect(listing.teacherId, _dto.teacherId);
  expect(listing.teacherName, _dto.teacherName);
  expect(listing.subject, _dto.subject);
  expect(listing.description, _dto.description);
  expect(listing.deliveryMode, LessonDeliveryMode.online);
  expect(listing.certification.hasCertificate, isTrue);
  expect(
    listing.certification.certificateDescription,
    _dto.certificateDescription,
  );
  expect(listing.contact.whatsAppNumber, _dto.whatsAppNumber);
  expect(listing.contact.emailAddress, _dto.emailAddress);
}

Matcher _failureWithType(LessonListingFailureType type) =>
    isA<LessonListingFailure>().having((failure) => failure.type, 'type', type);

class _RecordingDataSource implements LessonListingDataSource {
  _RecordingDataSource({
    this.dto = _dto,
    this.emptyResults = false,
    this.exception,
    this.error,
  });

  /// The payload returned by each operation.
  final LessonListingDto dto;

  /// Whether list reads return no payloads.
  final bool emptyResults;

  /// An optional exception injected into every operation.
  final Exception? exception;

  /// An optional programming error injected into every operation.
  final Error? error;

  /// The exact filters forwarded by the repository.
  final List<LessonListingFilter> filters = [];

  /// The exact identifiers forwarded by the repository.
  final List<String> ids = [];

  /// The exact new listings forwarded by the repository.
  final List<NewLessonListing> inserted = [];

  /// Records filters and returns the configured result or throws.
  @override
  Future<List<LessonListingDto>> fetchListings(
    LessonListingFilter filter,
  ) async {
    filters.add(filter);
    _throwIfConfigured();
    return emptyResults ? [] : [dto];
  }

  /// Records the identifier and returns the configured result or throws.
  @override
  Future<LessonListingDto> fetchListingById(String id) async {
    ids.add(id);
    _throwIfConfigured();
    return dto;
  }

  /// Records new data and returns the configured result or throws.
  @override
  Future<LessonListingDto> insertListing(NewLessonListing listing) async {
    inserted.add(listing);
    _throwIfConfigured();
    return dto;
  }

  void _throwIfConfigured() {
    final configuredException = exception;
    if (configuredException != null) {
      throw configuredException;
    }
    final configuredError = error;
    if (configuredError != null) {
      throw configuredError;
    }
  }
}
