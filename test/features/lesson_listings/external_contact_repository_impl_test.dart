import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/external_contact_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/platform_external_contact_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/repositories/external_contact_repository_impl.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/external_contact_repository.dart';

/// Verifies URI construction, platform delegation and domain failure mapping.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final openOperations =
      <String, Future<void> Function(ExternalContactRepository)>{
        'WhatsApp': (repository) => repository.openWhatsApp('+905550000001'),
        'email': (repository) =>
            repository.openEmail('contact@example.invalid'),
      };
  final exceptions = <Exception>[
    Exception('Provider failed'),
    PlatformException(code: 'unavailable'),
    MissingPluginException('No platform implementation'),
  ];

  group('ExternalContactRepositoryImpl', () {
    test('opens the WhatsApp HTTPS URL without the leading plus', () async {
      final source = _RecordingDataSource();
      final repository = ExternalContactRepositoryImpl(source);

      await repository.openWhatsApp('+905550000001');

      expect(source.uris, hasLength(1));
      final uri = source.uris.single;
      expect(uri.toString(), 'https://wa.me/905550000001');
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/905550000001');
      expect(uri.hasQuery, isFalse);
      expect(uri.hasFragment, isFalse);
      expect(source.copiedValues, isEmpty);
    });

    test('opens the exact mailto URI with the supplied address', () async {
      final source = _RecordingDataSource();
      final repository = ExternalContactRepositoryImpl(source);

      await repository.openEmail('Teacher+lesson@Example.invalid');

      expect(source.uris, hasLength(1));
      final uri = source.uris.single;
      expect(uri.toString(), 'mailto:Teacher+lesson@Example.invalid');
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'Teacher+lesson@Example.invalid');
      expect(uri.hasAuthority, isFalse);
      expect(uri.hasQuery, isFalse);
      expect(uri.hasFragment, isFalse);
      expect(source.copiedValues, isEmpty);
    });

    test('keeps email query and fragment characters inside the path', () async {
      final source = _RecordingDataSource();
      final repository = ExternalContactRepositoryImpl(source);
      const address = 'teacher?subject=private#lesson@example.invalid';

      await repository.openEmail(address);

      final uri = source.uris.single;
      expect(Uri.decodeComponent(uri.path), address);
      expect(uri.hasQuery, isFalse);
      expect(uri.hasFragment, isFalse);
    });

    for (final operation in openOperations.entries) {
      test('${operation.key} maps a false launch result', () async {
        final source = _RecordingDataSource(launchResult: false);
        final repository = ExternalContactRepositoryImpl(source);

        await expectLater(
          operation.value(repository),
          throwsA(
            _failureWithType(ExternalContactFailureType.cannotOpenExternalApp),
          ),
        );
        expect(source.uris, hasLength(1));
        expect(source.copiedValues, isEmpty);
      });

      for (final exception in exceptions) {
        test('${operation.key} maps ${exception.runtimeType}', () async {
          final source = _RecordingDataSource(exception: exception);
          final repository = ExternalContactRepositoryImpl(source);

          await expectLater(
            operation.value(repository),
            throwsA(
              _failureWithType(
                ExternalContactFailureType.cannotOpenExternalApp,
              ),
            ),
          );
          expect(source.uris, hasLength(1));
          expect(source.copiedValues, isEmpty);
        });
      }

      test('${operation.key} preserves programming errors', () async {
        final error = StateError('Programming error');
        final source = _RecordingDataSource(error: error);
        final repository = ExternalContactRepositoryImpl(source);

        await expectLater(operation.value(repository), throwsA(same(error)));
      });
    }

    test('copies the exact value without launching an application', () async {
      final source = _RecordingDataSource();
      final repository = ExternalContactRepositoryImpl(source);
      const value = '+90 (555) 000-00-01';

      await repository.copyContactValue(value);

      expect(source.copiedValues, [value]);
      expect(source.uris, isEmpty);
    });

    for (final exception in exceptions) {
      test('maps clipboard exception ${exception.runtimeType}', () async {
        final source = _RecordingDataSource(exception: exception);
        final repository = ExternalContactRepositoryImpl(source);

        await expectLater(
          repository.copyContactValue('contact@example.invalid'),
          throwsA(_failureWithType(ExternalContactFailureType.clipboardFailed)),
        );
        expect(source.copiedValues, ['contact@example.invalid']);
        expect(source.uris, isEmpty);
      });
    }

    test('preserves programming errors from the clipboard source', () async {
      final error = StateError('Programming error');
      final source = _RecordingDataSource(error: error);
      final repository = ExternalContactRepositoryImpl(source);

      await expectLater(
        repository.copyContactValue('contact@example.invalid'),
        throwsA(same(error)),
      );
    });
  });

  group('PlatformExternalContactDataSource', () {
    late List<MethodCall> platformCalls;

    setUp(() {
      platformCalls = [];
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          return null;
        },
      );
    });

    tearDown(() {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    test('returns false without a configured launcher', () async {
      const source = PlatformExternalContactDataSource();

      expect(
        await source.launchUri(Uri.https('wa.me', '905550000001')),
        isFalse,
      );
      expect(
        await source.launchUri(
          Uri(scheme: 'mailto', path: 'contact@example.invalid'),
        ),
        isFalse,
      );
      expect(platformCalls, isEmpty);
    });

    for (final result in [true, false]) {
      test('forwards the URI and preserves launcher result $result', () async {
        final launchedUris = <Uri>[];
        final uri = Uri.https('wa.me', '905550000001');
        final source = PlatformExternalContactDataSource(
          uriLauncher: (value) async {
            launchedUris.add(value);
            return result;
          },
        );

        expect(await source.launchUri(uri), result);
        expect(launchedUris, [same(uri)]);
        expect(platformCalls, isEmpty);
      });
    }

    test('writes text through Clipboard.setData by default', () async {
      const source = PlatformExternalContactDataSource();
      const text = '  Öğretmen +90 (555) 000-00-01  ';

      await source.copyToClipboard(text);

      expect(platformCalls, hasLength(1));
      expect(platformCalls.single.method, 'Clipboard.setData');
      expect(platformCalls.single.arguments, <String, Object>{'text': text});
    });

    test('uses the injected clipboard writer without platform calls', () async {
      final copiedValues = <String>[];
      final source = PlatformExternalContactDataSource(
        clipboardWriter: (text) async {
          copiedValues.add(text);
        },
      );

      await source.copyToClipboard('contact@example.invalid');

      expect(copiedValues, ['contact@example.invalid']);
      expect(platformCalls, isEmpty);
    });

    for (final asynchronous in [true, false]) {
      test('propagates callback failures (async: $asynchronous)', () async {
        final exception = Exception('Injected operation failed');
        final source = PlatformExternalContactDataSource(
          uriLauncher: (_) {
            if (asynchronous) {
              return Future<bool>.error(exception);
            }
            throw exception;
          },
          clipboardWriter: (_) {
            if (asynchronous) {
              return Future<void>.error(exception);
            }
            throw exception;
          },
        );

        await expectLater(
          source.launchUri(Uri.https('wa.me', '905550000001')),
          throwsA(same(exception)),
        );
        await expectLater(
          source.copyToClipboard('contact@example.invalid'),
          throwsA(same(exception)),
        );
        expect(platformCalls, isEmpty);
      });
    }

    for (final operation in openOperations.entries) {
      test('copies after ${operation.key} fails to open', () async {
        const repository = ExternalContactRepositoryImpl(
          PlatformExternalContactDataSource(),
        );

        await expectLater(
          operation.value(repository),
          throwsA(
            _failureWithType(ExternalContactFailureType.cannotOpenExternalApp),
          ),
        );
        expect(platformCalls, isEmpty);

        final value = operation.key == 'WhatsApp'
            ? '+905550000001'
            : 'contact@example.invalid';
        await repository.copyContactValue(value);

        expect(platformCalls, hasLength(1));
        expect(platformCalls.single.method, 'Clipboard.setData');
        expect(platformCalls.single.arguments, <String, Object>{'text': value});
      });
    }

    test('maps default platform clipboard exceptions', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          throw PlatformException(code: 'clipboard_unavailable');
        },
      );
      const repository = ExternalContactRepositoryImpl(
        PlatformExternalContactDataSource(),
      );

      await expectLater(
        repository.copyContactValue('contact@example.invalid'),
        throwsA(_failureWithType(ExternalContactFailureType.clipboardFailed)),
      );
      expect(platformCalls, hasLength(1));
      expect(platformCalls.single.method, 'Clipboard.setData');
      expect(platformCalls.single.arguments, <String, Object>{
        'text': 'contact@example.invalid',
      });
    });
  });
}

Matcher _failureWithType(ExternalContactFailureType type) =>
    isA<ExternalContactFailure>().having(
      (failure) => failure.type,
      'type',
      type,
    );

class _RecordingDataSource implements ExternalContactDataSource {
  _RecordingDataSource({this.launchResult = true, this.exception, this.error});

  final bool launchResult;
  final Exception? exception;
  final Error? error;
  final List<Uri> uris = [];
  final List<String> copiedValues = [];

  @override
  Future<bool> launchUri(Uri uri) async {
    uris.add(uri);
    _throwIfConfigured();
    return launchResult;
  }

  @override
  Future<void> copyToClipboard(String text) async {
    copiedValues.add(text);
    _throwIfConfigured();
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
