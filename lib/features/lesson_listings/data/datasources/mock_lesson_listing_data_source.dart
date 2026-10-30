import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source_exception.dart';
import 'package:privatelesson/features/lesson_listings/data/dtos/lesson_listing_dto.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';

/// Stores listings in memory for one instance's lifetime.
final class MockLessonListingDataSource implements LessonListingDataSource {
  /// Copies optional initial data and supports independent failure injection.
  MockLessonListingDataSource({
    List<LessonListingDto> initialListings = const [],
    this.readException,
    this.writeException,
  }) : _listings = List<LessonListingDto>.of(initialListings);

  /// Creates four fictional examples covering every delivery/contact option.
  factory MockLessonListingDataSource.seeded() => MockLessonListingDataSource(
    initialListings: const [
      LessonListingDto(
        id: 'mock-lesson-1',
        teacherId: 'mock-teacher-1',
        teacherName: 'İpek Yılmaz',
        subject: 'Matematik',
        description: 'Temel kavramlardan problem çözümüne birebir matematik.',
        deliveryMode: 'inPerson',
        hasCertificate: true,
        certificateDescription: 'Matematik öğretmenliği diploması',
        whatsAppNumber: '+905550000001',
      ),
      LessonListingDto(
        id: 'mock-lesson-2',
        teacherId: 'mock-teacher-2',
        teacherName: 'Işıl Kaya',
        subject: 'İngilizce',
        description: 'Günlük konuşma ve okuma becerileri için çevrim içi ders.',
        deliveryMode: 'online',
        hasCertificate: false,
        emailAddress: 'isil@example.invalid',
      ),
      LessonListingDto(
        id: 'mock-lesson-3',
        teacherId: 'mock-teacher-3',
        teacherName: 'Deniz Aksoy',
        subject: 'Fizik',
        description: 'Önceden kaydedilmiş konu anlatımı ve örnek çözümler.',
        deliveryMode: 'recordedVideo',
        hasCertificate: true,
        certificateDescription: 'Fizik öğretmenliği diploması',
        whatsAppNumber: '+905550000003',
        emailAddress: 'deniz@example.invalid',
      ),
      LessonListingDto(
        id: 'mock-lesson-4',
        teacherId: 'mock-teacher-4',
        teacherName: 'Ece Demir',
        subject: 'Gitar',
        description: 'Akorlar ve ritim çalışmalarıyla çevrim içi gitar dersi.',
        deliveryMode: 'online',
        hasCertificate: false,
        whatsAppNumber: '+905550000004',
      ),
    ],
  );

  final List<LessonListingDto> _listings;
  int _nextId = 1;

  /// An exception thrown on either read operation until reset to null.
  Exception? readException;

  /// An exception thrown before insertion until reset to null.
  Exception? writeException;

  /// Returns an immutable snapshot filtered using Turkish case folding.
  @override
  Future<List<LessonListingDto>> fetchListings(
    LessonListingFilter filter,
  ) async {
    _checkReadException();
    final query = _foldTurkish(filter.searchQuery.trim());
    return List<LessonListingDto>.unmodifiable(
      _listings.where((listing) {
        final matchesText =
            query.isEmpty ||
            _foldTurkish(listing.subject).contains(query) ||
            _foldTurkish(listing.teacherName).contains(query);
        final matchesMode =
            filter.deliveryMode == null ||
            listing.deliveryMode == filter.deliveryMode?.name;
        final matchesCertificate =
            !filter.hasCertificateOnly || listing.hasCertificate;
        return matchesText && matchesMode && matchesCertificate;
      }),
    );
  }

  /// Returns the matching payload or reports that the listing is absent.
  @override
  Future<LessonListingDto> fetchListingById(String id) async {
    _checkReadException();
    for (final listing in _listings) {
      if (listing.id == id) {
        return listing;
      }
    }
    throw const LessonListingDataSourceException(
      LessonListingDataSourceError.notFound,
    );
  }

  /// Assigns an unused identifier and prepends the validated new listing.
  @override
  Future<LessonListingDto> insertListing(NewLessonListing listing) async {
    final exception = writeException;
    if (exception != null) {
      throw exception;
    }
    var candidate = _nextId;
    while (_listings.any((item) => item.id == 'mock-lesson-$candidate')) {
      candidate += 1;
    }
    final dto = LessonListingDto.fromNewListing(
      listing,
      id: 'mock-lesson-$candidate',
    );
    _nextId = candidate + 1;
    _listings.insert(0, dto);
    return dto;
  }

  void _checkReadException() {
    final exception = readException;
    if (exception != null) {
      throw exception;
    }
  }

  static String _foldTurkish(String value) =>
      value.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
}
