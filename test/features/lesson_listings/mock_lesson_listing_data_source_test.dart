import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source_exception.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/mock_lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/dtos/lesson_listing_dto.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/certification_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';

const _filter = LessonListingFilter();
const _newListing = NewLessonListing(
  teacherId: 'new-teacher',
  teacherName: 'Yeni Öğretmen',
  subject: 'Kimya',
  description: 'Kimya konu anlatımı.',
  deliveryMode: LessonDeliveryMode.online,
  certification: CertificationInfo(hasCertificate: false),
  contact: TeacherContactInfo(emailAddress: 'new@example.invalid'),
);

/// Verifies seeded data, Turkish search, combined filters and mock failures.
void main() {
  group('MockLessonListingDataSource', () {
    test('starts empty by default and reports an absent listing', () async {
      final source = MockLessonListingDataSource();

      expect(await source.fetchListings(_filter), isEmpty);
      await expectLater(
        source.fetchListingById('absent'),
        throwsA(
          isA<LessonListingDataSourceException>().having(
            (exception) => exception.type,
            'type',
            LessonListingDataSourceError.notFound,
          ),
        ),
      );
    });

    test('seeds four valid listings covering all supported choices', () async {
      final source = MockLessonListingDataSource.seeded();
      final listings = await source.fetchListings(_filter);
      final entities = listings.map((dto) => dto.toEntity()).toList();

      expect(listings, hasLength(4));
      expect(listings.map((dto) => dto.id).toSet(), hasLength(4));
      expect(
        entities.map((listing) => listing.deliveryMode).toSet(),
        LessonDeliveryMode.values.toSet(),
      );
      expect(
        entities.map((listing) => listing.certification.hasCertificate).toSet(),
        {true, false},
      );
      final contactChoices = entities.map((listing) {
        return (listing.contact.hasWhatsApp, listing.contact.hasEmail);
      });
      expect(contactChoices.toSet(), {
        (true, false),
        (false, true),
        (true, true),
      });
      for (final listing in listings) {
        expect(await source.fetchListingById(listing.id), same(listing));
      }
    });

    final searches = <String, List<String>>{
      'İPEK': ['mock-lesson-1'],
      'ipek': ['mock-lesson-1'],
      '  matematik  ': ['mock-lesson-1'],
      'YILMAZ': ['mock-lesson-1'],
      'IŞIL': ['mock-lesson-2'],
      'ışıl': ['mock-lesson-2'],
      'İNGİLİZCE': ['mock-lesson-2'],
      'ingilizce': ['mock-lesson-2'],
      'FİZİK': ['mock-lesson-3'],
      'fizik': ['mock-lesson-3'],
      'aksoy': ['mock-lesson-3'],
      'IPEK': [],
      'işıl': [],
      'kavramlardan': [],
      'unknown': [],
    };
    for (final entry in searches.entries) {
      test('searches subject or teacher with query ${entry.key}', () async {
        final source = MockLessonListingDataSource.seeded();
        final listings = await source.fetchListings(
          LessonListingFilter(searchQuery: entry.key),
        );

        expect(listings.map((listing) => listing.id), entry.value);
      });
    }

    test('ignores blank search text', () async {
      final source = MockLessonListingDataSource.seeded();

      expect(
        await source.fetchListings(
          const LessonListingFilter(searchQuery: ' \t\n '),
        ),
        hasLength(4),
      );
    });

    final modeIds = <LessonDeliveryMode, List<String>>{
      LessonDeliveryMode.inPerson: ['mock-lesson-1'],
      LessonDeliveryMode.online: ['mock-lesson-2', 'mock-lesson-4'],
      LessonDeliveryMode.recordedVideo: ['mock-lesson-3'],
    };
    for (final entry in modeIds.entries) {
      test('filters delivery mode ${entry.key.name}', () async {
        final source = MockLessonListingDataSource.seeded();
        final listings = await source.fetchListings(
          LessonListingFilter(deliveryMode: entry.key),
        );

        expect(listings.map((listing) => listing.id), entry.value);
      });
    }

    test('filters declared certificates', () async {
      final source = MockLessonListingDataSource.seeded();
      final listings = await source.fetchListings(
        const LessonListingFilter(hasCertificateOnly: true),
      );

      expect(listings.map((listing) => listing.id), [
        'mock-lesson-1',
        'mock-lesson-3',
      ]);
    });

    test('combines every criterion and supports empty results', () async {
      final source = MockLessonListingDataSource.seeded();
      final matching = await source.fetchListings(
        const LessonListingFilter(
          searchQuery: 'DENİZ',
          deliveryMode: LessonDeliveryMode.recordedVideo,
          hasCertificateOnly: true,
        ),
      );
      final excluded = await source.fetchListings(
        const LessonListingFilter(
          searchQuery: 'İngilizce',
          deliveryMode: LessonDeliveryMode.online,
          hasCertificateOnly: true,
        ),
      );

      expect(matching.map((listing) => listing.id), ['mock-lesson-3']);
      expect(excluded, isEmpty);
      expect(await source.fetchListings(_filter), hasLength(4));
    });

    test('copies initial data and returns immutable snapshots', () async {
      final initial = <LessonListingDto>[
        LessonListingDto.fromNewListing(_newListing, id: 'existing'),
      ];
      final source = MockLessonListingDataSource(initialListings: initial);
      initial.clear();
      final snapshot = await source.fetchListings(_filter);

      expect(snapshot, hasLength(1));
      expect(snapshot.clear, throwsUnsupportedError);
      await source.insertListing(_newListing);
      expect(snapshot, hasLength(1));
      expect(await source.fetchListings(_filter), hasLength(2));
    });

    test('prepends new listings with ids distinct from seeded ids', () async {
      final source = MockLessonListingDataSource.seeded();
      final first = await source.insertListing(_newListing);
      final second = await source.insertListing(_newListing);
      final listings = await source.fetchListings(_filter);

      expect(first.id, isNotEmpty);
      expect(second.id, isNot(first.id));
      expect(listings.map((listing) => listing.id).toSet(), hasLength(6));
      expect(listings.first, same(second));
      expect(listings[1], same(first));
      expect(await source.fetchListingById(first.id), same(first));
      expect(first.teacherId, _newListing.teacherId);
      expect(first.subject, _newListing.subject);
      expect(first.emailAddress, _newListing.contact.emailAddress);
      expect(first.whatsAppNumber, isNull);
    });

    test('skips custom id collisions across successive inserts', () async {
      final source = MockLessonListingDataSource(
        initialListings: [
          LessonListingDto.fromNewListing(_newListing, id: 'mock-lesson-1'),
          LessonListingDto.fromNewListing(_newListing, id: 'mock-lesson-3'),
        ],
      );
      await source.insertListing(_newListing);
      await source.insertListing(_newListing);
      final listings = await source.fetchListings(_filter);

      expect(listings.map((listing) => listing.id).toSet(), hasLength(4));
    });

    test('keeps seeded instances independent', () async {
      final first = MockLessonListingDataSource.seeded();
      final second = MockLessonListingDataSource.seeded();
      await first.insertListing(_newListing);

      expect(await first.fetchListings(_filter), hasLength(5));
      expect(await second.fetchListings(_filter), hasLength(4));
    });

    for (final type in LessonListingDataSourceError.values) {
      test('injects and resets ${type.name} read/write failures', () async {
        final exception = LessonListingDataSourceException(type);
        final source = MockLessonListingDataSource(
          readException: exception,
          writeException: exception,
        );

        await expectLater(
          source.fetchListings(_filter),
          throwsA(same(exception)),
        );
        await expectLater(
          source.fetchListingById('absent'),
          throwsA(same(exception)),
        );
        await expectLater(
          source.insertListing(_newListing),
          throwsA(same(exception)),
        );
        source.readException = null;
        expect(await source.fetchListings(_filter), isEmpty);
        source.writeException = null;
        final inserted = await source.insertListing(_newListing);
        expect(await source.fetchListingById(inserted.id), same(inserted));
      });
    }

    test('read and write failures are independent', () async {
      const exception = FormatException('Injected malformed payload');
      final source = MockLessonListingDataSource(readException: exception);
      final inserted = await source.insertListing(_newListing);
      source.readException = null;
      source.writeException = exception;

      expect(await source.fetchListingById(inserted.id), same(inserted));
      await expectLater(
        source.insertListing(_newListing),
        throwsA(same(exception)),
      );
      expect(await source.fetchListings(_filter), hasLength(1));
    });
  });
}
