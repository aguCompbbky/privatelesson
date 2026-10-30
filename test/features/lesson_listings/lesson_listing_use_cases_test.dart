import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/mock_lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/repositories/lesson_listing_repository_impl.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/certification_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/create_lesson_listing_input.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/lesson_listing_repository.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/create_lesson_listing_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/get_lesson_listing_detail_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/get_lesson_listings_use_case.dart';

const _listing = LessonListing(
  id: 'stored-id',
  teacherId: 'teacher-1',
  teacherName: 'İpek Yılmaz',
  subject: 'Matematik',
  description: 'Konu anlatımı.',
  deliveryMode: LessonDeliveryMode.online,
  certification: CertificationInfo(hasCertificate: false),
  contact: TeacherContactInfo(emailAddress: 'contact@example.invalid'),
);
const _blankValues = ['', '   ', ' \t\n\r '];

/// Verifies authorization, validation, normalization and repository delegation.
void main() {
  group('CreateLessonListingUseCase', () {
    test('rejects students before validation or storage access', () async {
      final repository = _RecordingRepository();
      final useCase = CreateLessonListingUseCase(repository);

      await expectLater(
        useCase(
          actorRole: UserRole.student,
          input: _input(teacherId: '', emailAddress: null),
        ),
        throwsA(_failureWithType(LessonListingFailureType.unauthorizedRole)),
      );
      expect(repository.created, isEmpty);
      expect(repository.filters, isEmpty);
      expect(repository.ids, isEmpty);
    });

    for (final mode in LessonDeliveryMode.values) {
      test('accepts a teacher publishing ${mode.name}', () async {
        final repository = _RecordingRepository();
        final useCase = CreateLessonListingUseCase(repository);

        final result = await useCase(
          actorRole: UserRole.teacher,
          input: _input(deliveryMode: mode),
        );

        expect(result, same(_listing));
        expect(repository.created, hasLength(1));
        expect(repository.created.single.deliveryMode, mode);
        expect(repository.filters, isEmpty);
        expect(repository.ids, isEmpty);
      });
    }

    test('trims text, preserving inner spaces and email case', () async {
      final repository = _RecordingRepository();
      final useCase = CreateLessonListingUseCase(repository);

      await useCase(
        actorRole: UserRole.teacher,
        input: _input(
          teacherId: ' \tteacher-1\n ',
          teacherName: '  İpek Yılmaz  ',
          subject: '  İleri Matematik  ',
          description: ' \nKonu anlatımı.\t ',
          hasCertificate: true,
          certificateDescription: '  Öğretmenlik diploması  ',
          whatsAppNumber: ' \t+90 (555) 000-00-01\n ',
          emailAddress: '  Ipek+lesson@Example.invalid  ',
        ),
      );

      expect(repository.created, hasLength(1));
      final saved = repository.created.single;
      expect(saved.teacherId, 'teacher-1');
      expect(saved.teacherName, 'İpek Yılmaz');
      expect(saved.subject, 'İleri Matematik');
      expect(saved.description, 'Konu anlatımı.');
      expect(saved.deliveryMode, LessonDeliveryMode.online);
      expect(saved.certification.hasCertificate, isTrue);
      expect(
        saved.certification.certificateDescription,
        'Öğretmenlik diploması',
      );
      expect(saved.contact.whatsAppNumber, '+905550000001');
      expect(saved.contact.emailAddress, 'Ipek+lesson@Example.invalid');
    });

    for (final blank in _blankValues) {
      final cases =
          <(String, CreateLessonListingInput, LessonListingFailureType)>[
            (
              'teacherId',
              _input(teacherId: blank),
              LessonListingFailureType.invalidTeacherInfo,
            ),
            (
              'teacherName',
              _input(teacherName: blank),
              LessonListingFailureType.invalidTeacherInfo,
            ),
            (
              'subject',
              _input(subject: blank),
              LessonListingFailureType.invalidSubject,
            ),
            (
              'description',
              _input(description: blank),
              LessonListingFailureType.invalidDescription,
            ),
          ];
      for (final entry in cases) {
        test('rejects blank ${entry.$1}: "$blank"', () async {
          await _expectRejected(entry.$2, entry.$3);
        });
      }
    }

    for (final description in <String?>[null, ..._blankValues]) {
      test('rejects missing certificate details: "$description"', () async {
        await _expectRejected(
          _input(hasCertificate: true, certificateDescription: description),
          LessonListingFailureType.missingCertificateDescription,
        );
      });
    }

    for (final description in <String?>[null, '', '  ', 'Unused certificate']) {
      test('clears undeclared certificate details: "$description"', () async {
        final repository = _RecordingRepository();
        await CreateLessonListingUseCase(repository)(
          actorRole: UserRole.teacher,
          input: _input(certificateDescription: description),
        );

        expect(repository.created.single.certification.hasCertificate, isFalse);
        expect(
          repository.created.single.certification.certificateDescription,
          isNull,
        );
      });
    }

    for (final contacts in <(String?, String?)>[
      ('+905550000001', null),
      (null, 'contact@example.invalid'),
      ('+905550000001', 'contact@example.invalid'),
    ]) {
      test('publishes only selected contact methods $contacts', () async {
        final repository = _RecordingRepository();
        await CreateLessonListingUseCase(repository)(
          actorRole: UserRole.teacher,
          input: _input(whatsAppNumber: contacts.$1, emailAddress: contacts.$2),
        );
        final contact = repository.created.single.contact;

        expect(contact.whatsAppNumber, contacts.$1);
        expect(contact.emailAddress, contacts.$2);
        expect(contact.hasWhatsApp, contacts.$1 != null);
        expect(contact.hasEmail, contacts.$2 != null);
      });
    }

    test('rejects absent contacts', () async {
      await _expectRejected(
        _input(emailAddress: null),
        LessonListingFailureType.missingContactMethod,
      );
    });

    for (final blank in _blankValues) {
      test('rejects a selected blank WhatsApp input: "$blank"', () async {
        await _expectRejected(
          _input(whatsAppNumber: blank),
          LessonListingFailureType.invalidWhatsAppNumber,
        );
      });
      test('rejects a selected blank email input: "$blank"', () async {
        await _expectRejected(
          _input(whatsAppNumber: '+905550000001', emailAddress: blank),
          LessonListingFailureType.invalidEmailAddress,
        );
      });
    }

    const validPhones = <String, String>{
      '+12345678': '+12345678',
      '+123456789012345': '+123456789012345',
      '+90 (555) 000-00-01': '+905550000001',
      ' \t+90\t(555)\n000-00-01 ': '+905550000001',
    };
    for (final entry in validPhones.entries) {
      test('normalizes valid country-code phone ${entry.key}', () async {
        final repository = _RecordingRepository();
        await CreateLessonListingUseCase(repository)(
          actorRole: UserRole.teacher,
          input: _input(whatsAppNumber: entry.key, emailAddress: null),
        );

        expect(repository.created.single.contact.whatsAppNumber, entry.value);
      });
    }

    for (final phone in [
      '905550000001',
      '00905550000001',
      '+05550000001',
      '+1234567',
      '+1234567890123456',
      '++905550000001',
      '+90abc0000001',
      '+90/5550000001',
      '+90.5550000001',
      '()-',
      '+',
    ]) {
      test('rejects invalid phone even with a valid email: $phone', () async {
        await _expectRejected(
          _input(whatsAppNumber: phone),
          LessonListingFailureType.invalidWhatsAppNumber,
        );
      });
    }

    for (final email in [
      'missing-at.example.invalid',
      '@example.invalid',
      'name@',
      'name@example',
      'name@@example.invalid',
      'name @example.invalid',
      'name@example. invalid',
      'name\n@example.invalid',
      'name\t@example.invalid',
    ]) {
      test('rejects invalid email even with a valid phone: $email', () async {
        await _expectRejected(
          _input(whatsAppNumber: '+905550000001', emailAddress: email),
          LessonListingFailureType.invalidEmailAddress,
        );
      });
    }
  });

  group('GetLessonListingsUseCase', () {
    test('defaults to an unrestricted filter and preserves results', () async {
      final repository = _RecordingRepository();
      final result = await GetLessonListingsUseCase(repository)();

      expect(result, same(repository.listings));
      expect(repository.filters, hasLength(1));
      expect(repository.filters.single.searchQuery, isEmpty);
      expect(repository.filters.single.deliveryMode, isNull);
      expect(repository.filters.single.hasCertificateOnly, isFalse);
      expect(repository.filters.single.hasActiveFilters, isFalse);
      expect(repository.created, isEmpty);
      expect(repository.ids, isEmpty);
    });

    test('forwards the exact requested filter', () async {
      final repository = _RecordingRepository();
      const filter = LessonListingFilter(
        searchQuery: 'İpek',
        deliveryMode: LessonDeliveryMode.online,
        hasCertificateOnly: true,
      );

      await GetLessonListingsUseCase(repository)(filter);

      expect(repository.filters, [same(filter)]);
    });

    test('preserves an empty result', () async {
      final repository = _RecordingRepository();
      repository.listings.clear();

      expect(await GetLessonListingsUseCase(repository)(), isEmpty);
    });
  });

  group('GetLessonListingDetailUseCase', () {
    test('trims the id and returns the repository result', () async {
      final repository = _RecordingRepository();
      final result = await GetLessonListingDetailUseCase(repository)(
        ' \tstored-id\n ',
      );

      expect(result, same(_listing));
      expect(repository.ids, ['stored-id']);
      expect(repository.filters, isEmpty);
      expect(repository.created, isEmpty);
    });

    for (final blank in _blankValues) {
      test('rejects blank identifier "$blank" before reading', () async {
        final repository = _RecordingRepository();

        await expectLater(
          GetLessonListingDetailUseCase(repository)(blank),
          throwsA(_failureWithType(LessonListingFailureType.notFound)),
        );
        expect(repository.ids, isEmpty);
      });
    }
  });

  group('Domain value objects', () {
    test('reports no active filters for default or blank search', () {
      const defaultFilter = LessonListingFilter();
      const blankFilter = LessonListingFilter(searchQuery: ' \t\n ');

      expect(defaultFilter.hasActiveFilters, isFalse);
      expect(blankFilter.hasActiveFilters, isFalse);
    });

    const activeFilters = [
      LessonListingFilter(searchQuery: 'mat'),
      LessonListingFilter(deliveryMode: LessonDeliveryMode.inPerson),
      LessonListingFilter(hasCertificateOnly: true),
    ];
    for (final entry in activeFilters.indexed) {
      test('reports active criteria ${entry.$1}', () {
        expect(entry.$2.hasActiveFilters, isTrue);
      });
    }

    test('does not infer contact methods when no values were shared', () {
      const contact = TeacherContactInfo();

      expect(contact.hasWhatsApp, isFalse);
      expect(contact.hasEmail, isFalse);
    });
  });

  for (final type in LessonListingFailureType.values) {
    test('all use cases preserve repository failure ${type.name}', () async {
      final failure = LessonListingFailure(type);
      final repository = _RecordingRepository(failure: failure);

      await expectLater(
        GetLessonListingsUseCase(repository)(),
        throwsA(same(failure)),
      );
      await expectLater(
        GetLessonListingDetailUseCase(repository)('stored-id'),
        throwsA(same(failure)),
      );
      await expectLater(
        CreateLessonListingUseCase(repository)(
          actorRole: UserRole.teacher,
          input: _input(),
        ),
        throwsA(same(failure)),
      );
      expect(repository.filters, hasLength(1));
      expect(repository.ids, ['stored-id']);
      expect(repository.created, hasLength(1));
    });
  }

  test('creates, searches and loads a listing via the mock stack', () async {
    final repository = LessonListingRepositoryImpl(
      MockLessonListingDataSource(),
    );
    final created = await CreateLessonListingUseCase(repository)(
      actorRole: UserRole.teacher,
      input: _input(whatsAppNumber: '+90 (555) 000-00-01', emailAddress: null),
    );
    final found = await GetLessonListingsUseCase(repository)(
      const LessonListingFilter(
        searchQuery: 'İPEK',
        deliveryMode: LessonDeliveryMode.online,
      ),
    );
    final detail = await GetLessonListingDetailUseCase(repository)(created.id);

    expect(found.single.id, created.id);
    expect(detail.teacherName, 'İpek Yılmaz');
    expect(detail.contact.whatsAppNumber, '+905550000001');
    expect(detail.contact.emailAddress, isNull);
  });
}

CreateLessonListingInput _input({
  String teacherId = 'teacher-1',
  String teacherName = 'İpek Yılmaz',
  String subject = 'Matematik',
  String description = 'Konu anlatımı.',
  LessonDeliveryMode deliveryMode = LessonDeliveryMode.online,
  bool hasCertificate = false,
  String? certificateDescription,
  String? whatsAppNumber,
  String? emailAddress = 'contact@example.invalid',
}) => CreateLessonListingInput(
  teacherId: teacherId,
  teacherName: teacherName,
  subject: subject,
  description: description,
  deliveryMode: deliveryMode,
  hasCertificate: hasCertificate,
  certificateDescription: certificateDescription,
  whatsAppNumber: whatsAppNumber,
  emailAddress: emailAddress,
);

Future<void> _expectRejected(
  CreateLessonListingInput input,
  LessonListingFailureType type,
) async {
  final repository = _RecordingRepository();
  await expectLater(
    CreateLessonListingUseCase(repository)(
      actorRole: UserRole.teacher,
      input: input,
    ),
    throwsA(_failureWithType(type)),
  );
  expect(repository.created, isEmpty);
  expect(repository.filters, isEmpty);
  expect(repository.ids, isEmpty);
}

Matcher _failureWithType(LessonListingFailureType type) =>
    isA<LessonListingFailure>().having((failure) => failure.type, 'type', type);

class _RecordingRepository implements LessonListingRepository {
  _RecordingRepository({this.failure});

  /// The optional domain failure propagated by every method.
  final LessonListingFailure? failure;

  /// The collection returned by listing reads.
  final List<LessonListing> listings = [_listing];

  /// The filters submitted by the listing use case.
  final List<LessonListingFilter> filters = [];

  /// The identifiers submitted by the detail use case.
  final List<String> ids = [];

  /// The normalized inputs submitted by the create use case.
  final List<NewLessonListing> created = [];

  /// Records the filter and returns the configured listings or failure.
  @override
  Future<List<LessonListing>> getListings(LessonListingFilter filter) async {
    filters.add(filter);
    _throwIfConfigured();
    return listings;
  }

  /// Records the identifier and returns the stored listing or failure.
  @override
  Future<LessonListing> getListingById(String id) async {
    ids.add(id);
    _throwIfConfigured();
    return _listing;
  }

  /// Records validated data and returns the stored listing or failure.
  @override
  Future<LessonListing> createListing(NewLessonListing listing) async {
    created.add(listing);
    _throwIfConfigured();
    return _listing;
  }

  void _throwIfConfigured() {
    final configuredFailure = failure;
    if (configuredFailure != null) {
      throw configuredFailure;
    }
  }
}
