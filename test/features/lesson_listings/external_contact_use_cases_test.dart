import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/external_contact_repository.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/copy_contact_value_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/open_email_contact_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/open_whatsapp_contact_use_case.dart';

const _blankValues = ['', '   ', ' \t\n\r '];

/// Verifies contact validation, normalization and failure forwarding.
void main() {
  group('OpenWhatsAppContactUseCase', () {
    const validNumbers = {
      '+12345678': '+12345678',
      '+123456789012345': '+123456789012345',
      '+905550000001': '+905550000001',
      '  +90 (555) 000-00-01  ': '+905550000001',
      ' \t+90\t(555)\n000-00-01\r ': '+905550000001',
    };
    for (final entry in validNumbers.entries) {
      test('normalizes and opens ${entry.key}', () async {
        final repository = _RecordingRepository();

        await OpenWhatsAppContactUseCase(repository)(entry.key);

        expect(repository.numbers, [entry.value]);
        expect(repository.addresses, isEmpty);
        expect(repository.copiedValues, isEmpty);
      });
    }

    for (final value in [
      ..._blankValues,
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
      test('rejects invalid number "$value" before delegation', () async {
        final repository = _RecordingRepository();

        await expectLater(
          OpenWhatsAppContactUseCase(repository)(value),
          throwsA(_invalidContactValue),
        );
        _expectNoRepositoryCalls(repository);
      });
    }
  });

  group('OpenEmailContactUseCase', () {
    const validAddresses = {
      'contact@example.invalid': 'contact@example.invalid',
      ' \tTeacher+lesson@Example.invalid\n ': 'Teacher+lesson@Example.invalid',
      'teacher.name@school.example.invalid':
          'teacher.name@school.example.invalid',
    };
    for (final entry in validAddresses.entries) {
      test('trims and opens ${entry.key} without changing case', () async {
        final repository = _RecordingRepository();

        await OpenEmailContactUseCase(repository)(entry.key);

        expect(repository.addresses, [entry.value]);
        expect(repository.numbers, isEmpty);
        expect(repository.copiedValues, isEmpty);
      });
    }

    for (final value in [
      ..._blankValues,
      'missing-at.example.invalid',
      '@example.invalid',
      'name@',
      'name@example',
      'name@example.',
      'name@@example.invalid',
      'name @example.invalid',
      'name@example. invalid',
      'name\n@example.invalid',
      'name\t@example.invalid',
    ]) {
      test('rejects invalid email "$value" before repository access', () async {
        final repository = _RecordingRepository();

        await expectLater(
          OpenEmailContactUseCase(repository)(value),
          throwsA(_invalidContactValue),
        );
        _expectNoRepositoryCalls(repository);
      });
    }
  });

  group('CopyContactValueUseCase', () {
    const values = {
      ' \t+90 (555) 000-00-01\n ': '+90 (555) 000-00-01',
      '  Teacher+lesson@Example.invalid  ': 'Teacher+lesson@Example.invalid',
      '  Teacher contact  ': 'Teacher contact',
    };
    for (final entry in values.entries) {
      test('trims "${entry.key}" while preserving inner text', () async {
        final repository = _RecordingRepository();

        await CopyContactValueUseCase(repository)(entry.key);

        expect(repository.copiedValues, [entry.value]);
        expect(repository.numbers, isEmpty);
        expect(repository.addresses, isEmpty);
      });
    }

    for (final value in _blankValues) {
      test('rejects blank copy "$value" before repository access', () async {
        final repository = _RecordingRepository();

        await expectLater(
          CopyContactValueUseCase(repository)(value),
          throwsA(_invalidContactValue),
        );
        _expectNoRepositoryCalls(repository);
      });
    }
  });

  for (final type in ExternalContactFailureType.values) {
    test('all use cases preserve repository failure ${type.name}', () async {
      final failure = ExternalContactFailure(type);
      final repository = _RecordingRepository(failure: failure);

      await expectLater(
        OpenWhatsAppContactUseCase(repository)('  +90 (555) 000-00-01  '),
        throwsA(same(failure)),
      );
      await expectLater(
        OpenEmailContactUseCase(repository)('  contact@example.invalid  '),
        throwsA(same(failure)),
      );
      await expectLater(
        CopyContactValueUseCase(repository)('  +905550000001  '),
        throwsA(same(failure)),
      );
      expect(repository.numbers, ['+905550000001']);
      expect(repository.addresses, ['contact@example.invalid']);
      expect(repository.copiedValues, ['+905550000001']);
    });
  }
}

final Matcher _invalidContactValue = isA<ExternalContactFailure>().having(
  (failure) => failure.type,
  'type',
  ExternalContactFailureType.invalidContactValue,
);

void _expectNoRepositoryCalls(_RecordingRepository repository) {
  expect(repository.numbers, isEmpty);
  expect(repository.addresses, isEmpty);
  expect(repository.copiedValues, isEmpty);
}

class _RecordingRepository implements ExternalContactRepository {
  _RecordingRepository({this.failure});

  final ExternalContactFailure? failure;
  final List<String> numbers = [];
  final List<String> addresses = [];
  final List<String> copiedValues = [];

  @override
  Future<void> openWhatsApp(String whatsAppNumber) async {
    numbers.add(whatsAppNumber);
    _throwIfConfigured();
  }

  @override
  Future<void> openEmail(String emailAddress) async {
    addresses.add(emailAddress);
    _throwIfConfigured();
  }

  @override
  Future<void> copyContactValue(String value) async {
    copiedValues.add(value);
    _throwIfConfigured();
  }

  void _throwIfConfigured() {
    final configuredFailure = failure;
    if (configuredFailure != null) {
      throw configuredFailure;
    }
  }
}
