import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/lesson_listings/data/dtos/lesson_listing_dto.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/certification_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';

const _validMap = <String, Object?>{
  'id': 'listing-1',
  'teacherId': 'teacher-1',
  'teacherName': 'İpek Yılmaz',
  'subject': 'Matematik',
  'description': 'Problem çözümü ve konu anlatımı.',
  'deliveryMode': 'online',
  'hasCertificate': true,
  'certificateDescription': 'Öğretmenlik diploması',
  'whatsAppNumber': '+905550000001',
  'emailAddress': 'contact@example.invalid',
};
const _newListing = NewLessonListing(
  teacherId: 'teacher-1',
  teacherName: 'İpek Yılmaz',
  subject: 'Matematik',
  description: 'Problem çözümü ve konu anlatımı.',
  deliveryMode: LessonDeliveryMode.online,
  certification: CertificationInfo(
    hasCertificate: true,
    certificateDescription: 'Öğretmenlik diploması',
  ),
  contact: TeacherContactInfo(
    whatsAppNumber: '+905550000001',
    emailAddress: 'contact@example.invalid',
  ),
);

/// Verifies storage types, all conversions and invalid payload rejection.
void main() {
  group('LessonListingDto', () {
    for (final mode in LessonDeliveryMode.values) {
      test('round trips every field for ${mode.name}', () {
        final map = Map<String, Object?>.of(_validMap);
        map['deliveryMode'] = mode.name;

        final dto = LessonListingDto.fromMap(map);
        final entity = dto.toEntity();

        expect(dto.toMap(), map);
        _expectListing(entity, mode);
        expect(LessonListingDto.fromEntity(entity).toMap(), map);
      });
    }

    test('assigns an id while retaining every new listing field', () {
      final dto = LessonListingDto.fromNewListing(_newListing, id: 'listing-1');

      expect(dto.toMap(), _validMap);
      _expectListing(dto.toEntity(), LessonDeliveryMode.online);
    });

    test('rejects a blank assigned identifier', () {
      expect(
        () => LessonListingDto.fromNewListing(_newListing, id: ' \t '),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid domain contact information on conversion', () {
      const listing = LessonListing(
        id: 'listing-1',
        teacherId: 'teacher-1',
        teacherName: 'İpek Yılmaz',
        subject: 'Matematik',
        description: 'Konu anlatımı.',
        deliveryMode: LessonDeliveryMode.online,
        certification: CertificationInfo(hasCertificate: false),
        contact: TeacherContactInfo(),
      );

      expect(
        () => LessonListingDto.fromEntity(listing),
        throwsA(isA<FormatException>()),
      );
    });

    for (final contacts in <(String?, String?)>[
      ('+905550000001', null),
      (null, 'contact@example.invalid'),
      ('+905550000001', 'contact@example.invalid'),
    ]) {
      test('preserves selected contact methods $contacts', () {
        final map = Map<String, Object?>.of(_validMap);
        map['whatsAppNumber'] = contacts.$1;
        map['emailAddress'] = contacts.$2;
        final dto = LessonListingDto.fromMap(map);
        final contact = dto.toEntity().contact;

        expect(contact.whatsAppNumber, contacts.$1);
        expect(contact.emailAddress, contacts.$2);
        expect(contact.hasWhatsApp, contacts.$1 != null);
        expect(contact.hasEmail, contacts.$2 != null);
        expect(dto.toMap(), map);
      });
    }

    test('accepts omitted optional fields when remaining data is valid', () {
      final map = Map<String, Object?>.of(_validMap);
      map['hasCertificate'] = false;
      map.remove('certificateDescription');
      map.remove('emailAddress');
      final entity = LessonListingDto.fromMap(map).toEntity();

      expect(entity.certification.hasCertificate, isFalse);
      expect(entity.certification.certificateDescription, isNull);
      expect(entity.contact.hasWhatsApp, isTrue);
      expect(entity.contact.hasEmail, isFalse);
    });

    test('discards extra fields and returns independent maps', () {
      final map = Map<String, Object?>.of(_validMap);
      map['email'] = 'authentication@example.invalid';
      map['isVerified'] = true;
      final dto = LessonListingDto.fromMap(map);
      map['subject'] = 'Changed input';
      final output = dto.toMap();
      output['subject'] = 'Changed output';

      expect(dto.toMap(), _validMap);
    });

    test('does not publish authentication email as a contact fallback', () {
      final map = Map<String, Object?>.of(_validMap);
      map.remove('whatsAppNumber');
      map.remove('emailAddress');
      map['email'] = 'authentication@example.invalid';

      expect(
        () => LessonListingDto.fromMap(map),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an empty map', () {
      expect(
        () => LessonListingDto.fromMap({}),
        throwsA(isA<FormatException>()),
      );
    });

    for (final field in [
      'id',
      'teacherId',
      'teacherName',
      'subject',
      'description',
      'deliveryMode',
      'hasCertificate',
    ]) {
      test('rejects missing required field $field', () {
        final map = Map<String, Object?>.of(_validMap);
        map.remove(field);

        expect(
          () => LessonListingDto.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      });

      for (final value in <Object?>[null, 42, '', ' \t\n ', <String>[]]) {
        test('rejects $field containing $value', () {
          final map = Map<String, Object?>.of(_validMap);
          map[field] = value;

          expect(
            () => LessonListingDto.fromMap(map),
            throwsA(isA<FormatException>()),
          );
        });
      }
    }

    final invalidOverrides = <Map<String, Object?>>[
      {'deliveryMode': 'live'},
      {'deliveryMode': 'Online'},
      {'deliveryMode': ' online '},
      {'deliveryMode': true},
      {
        'deliveryMode': ['online', 'inPerson'],
      },
      {'hasCertificate': 'true'},
      {'certificateDescription': null},
      {'certificateDescription': ''},
      {'certificateDescription': ' \n '},
      {'certificateDescription': 42},
      {'hasCertificate': false},
      {'hasCertificate': false, 'certificateDescription': ''},
      {'whatsAppNumber': null, 'emailAddress': null},
      {'whatsAppNumber': ''},
      {'whatsAppNumber': '  '},
      {'whatsAppNumber': 42},
      {'whatsAppNumber': '905550000001'},
      {'whatsAppNumber': '+05550000001'},
      {'whatsAppNumber': '+1234567'},
      {'whatsAppNumber': '+1234567890123456'},
      {'whatsAppNumber': '+90 (555) 000-00-01'},
      {'emailAddress': ''},
      {'emailAddress': ' \t '},
      {'emailAddress': false},
      {'emailAddress': 'missing-domain'},
      {'emailAddress': 'name@@example.invalid'},
      {'emailAddress': 'name@example'},
      {'emailAddress': 'contact @example.invalid'},
      {'emailAddress': ' contact@example.invalid '},
    ];
    for (final overrides in invalidOverrides) {
      test('rejects malformed payload $overrides', () {
        final map = Map<String, Object?>.of(_validMap);
        map.addAll(overrides);

        expect(
          () => LessonListingDto.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      });
    }

    for (final mode in ['unknown', 'online']) {
      test('validates directly constructed $mode payloads on output', () {
        final dto = LessonListingDto(
          id: 'listing-1',
          teacherId: 'teacher-1',
          teacherName: 'İpek Yılmaz',
          subject: 'Matematik',
          description: 'Konu anlatımı.',
          deliveryMode: mode,
          hasCertificate: false,
          emailAddress: mode == 'online' ? null : 'contact@example.invalid',
        );

        expect(dto.toEntity, throwsA(isA<FormatException>()));
        expect(dto.toMap, throwsA(isA<FormatException>()));
      });
    }
  });
}

void _expectListing(LessonListing listing, LessonDeliveryMode mode) {
  expect(listing.id, 'listing-1');
  expect(listing.teacherId, 'teacher-1');
  expect(listing.teacherName, 'İpek Yılmaz');
  expect(listing.subject, 'Matematik');
  expect(listing.description, 'Problem çözümü ve konu anlatımı.');
  expect(listing.deliveryMode, mode);
  expect(listing.certification.hasCertificate, isTrue);
  expect(listing.certification.certificateDescription, 'Öğretmenlik diploması');
  expect(listing.contact.whatsAppNumber, '+905550000001');
  expect(listing.contact.emailAddress, 'contact@example.invalid');
}
