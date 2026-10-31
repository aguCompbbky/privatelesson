import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/config/google_sign_in_config.dart';
import 'package:privatelesson/core/di/app_dependencies.dart';
import 'package:privatelesson/core/di/backend_provider.dart';
import 'package:privatelesson/core/firebase/firebase_bootstrap.dart';
import 'package:privatelesson/core/firebase/firebase_options.dart';
import 'package:privatelesson/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/firestore_user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_user_profile_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/firestore_lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/mock_lesson_listing_data_source.dart';

void main() {
  setUp(() => AppDependencies.activeProvider = BackendProvider.mock);
  tearDown(() {
    AppDependencies.activeProvider = null;
    debugDefaultTargetPlatformOverride = null;
  });

  group('BackendProvider', () {
    test('defaults to firebase without a compile-time override', () {
      expect(BackendProvider.fromEnvironment, BackendProvider.firebase);
    });

    test('only explicit mock selects mock, ignoring case and whitespace', () {
      expect(BackendProvider.fromName('firebase'), BackendProvider.firebase);
      expect(
        BackendProvider.fromName('  FIREBASE  '),
        BackendProvider.firebase,
      );
      expect(BackendProvider.fromName('mock'), BackendProvider.mock);
      expect(BackendProvider.fromName('  MOCK  '), BackendProvider.mock);
      expect(BackendProvider.fromName(''), BackendProvider.firebase);
      expect(BackendProvider.fromName('  '), BackendProvider.firebase);
      expect(BackendProvider.fromName('custom'), BackendProvider.firebase);
    });
  });

  group('FirebaseBootstrap', () {
    test(
      'skips initialization completely when mock provider is active',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        var checkedApps = false;
        var initialized = false;

        final result = await FirebaseBootstrap.ensureInitialized(
          provider: BackendProvider.mock,
          hasInitializedApps: () {
            checkedApps = true;
            return false;
          },
          initializeApp: ({options}) async {
            initialized = true;
            throw UnimplementedError();
          },
        );

        expect(result, isFalse);
        expect(checkedApps, isFalse);
        expect(initialized, isFalse);
      },
    );

    test(
      'returns true without re-initializing when app already exists',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        var initialized = false;

        final result = await FirebaseBootstrap.ensureInitialized(
          provider: BackendProvider.firebase,
          hasInitializedApps: () => true,
          initializeApp: ({options}) async {
            initialized = true;
            throw UnimplementedError();
          },
        );

        expect(result, isTrue);
        expect(initialized, isFalse);
      },
    );

    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      test(
        'uses generated $platform options and the default provider',
        () async {
          debugDefaultTargetPlatformOverride = platform;
          FirebaseOptions? capturedOptions;
          var initializationCount = 0;

          final result = await FirebaseBootstrap.ensureInitialized(
            hasInitializedApps: () => false,
            initializeApp: ({options}) async {
              capturedOptions = options;
              initializationCount++;
              return _FakeFirebaseApp();
            },
          );

          expect(result, isTrue);
          expect(initializationCount, 1);
          expect(capturedOptions, same(DefaultFirebaseOptions.currentPlatform));
          expect(capturedOptions?.projectId, 'privatelesson-c2aea');
        },
      );
    }

    test(
      'initializes Firebase with supplied options when uninitialized',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        const expectedOptions = FirebaseOptions(
          apiKey: 'demo-key',
          appId: 'demo-app-id',
          messagingSenderId: 'demo-sender',
          projectId: 'demo-project',
        );
        FirebaseOptions? capturedOptions;

        final result = await FirebaseBootstrap.ensureInitialized(
          provider: BackendProvider.firebase,
          options: expectedOptions,
          hasInitializedApps: () => false,
          initializeApp: ({options}) async {
            capturedOptions = options;
            return _FakeFirebaseApp();
          },
        );

        expect(result, isTrue);
        expect(capturedOptions, same(expectedOptions));
      },
    );

    test('propagates initialization failures', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final failure = StateError('Initialization failed');

      await expectLater(
        FirebaseBootstrap.ensureInitialized(
          provider: BackendProvider.firebase,
          hasInitializedApps: () => false,
          initializeApp: ({options}) async => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });

  group('AppDependencies', () {
    test(
      'uses firebase by default and supports an explicit mock override',
      () {
        AppDependencies.activeProvider = null;
        expect(AppDependencies.activeProvider, BackendProvider.firebase);
        expect(
          AppDependencies.resolveAuthDataSource(),
          isA<FirebaseAuthDataSource>(),
        );
        expect(
          AppDependencies.resolveUserProfileDataSource(),
          isA<FirestoreUserProfileDataSource>(),
        );
        expect(
          AppDependencies.resolveLessonListingDataSource(),
          isA<FirestoreLessonListingDataSource>(),
        );

        AppDependencies.activeProvider = BackendProvider.mock;
        expect(AppDependencies.activeProvider, BackendProvider.mock);
        expect(
          AppDependencies.resolveAuthDataSource(),
          isA<MockAuthDataSource>(),
        );
        expect(
          AppDependencies.resolveUserProfileDataSource(),
          isA<MockUserProfileDataSource>(),
        );
        expect(
          AppDependencies.resolveLessonListingDataSource(),
          isA<MockLessonListingDataSource>(),
        );

        AppDependencies.activeProvider = null;
        expect(AppDependencies.activeProvider, BackendProvider.firebase);
        expect(
          AppDependencies.resolveAuthDataSource(),
          isA<FirebaseAuthDataSource>(),
        );
        expect(
          AppDependencies.resolveUserProfileDataSource(),
          isA<FirestoreUserProfileDataSource>(),
        );
        expect(
          AppDependencies.resolveLessonListingDataSource(),
          isA<FirestoreLessonListingDataSource>(),
        );
      },
    );

    test('passes distinct Google client IDs to the auth data source', () {
      const config = GoogleSignInConfig(
        serverClientId: 'test-web-client-id',
        iosClientId: 'test-ios-client-id',
      );
      final expectedSource = FirebaseAuthDataSource();
      String? capturedServerClientId;
      String? capturedClientId;

      final source = AppDependencies.createFirebaseAuthDataSource(
        googleSignInConfig: config,
        createDataSource: ({googleClientId, googleServerClientId}) {
          capturedServerClientId = googleServerClientId;
          capturedClientId = googleClientId;
          return expectedSource;
        },
      );

      expect(source, same(expectedSource));
      expect(capturedServerClientId, 'test-web-client-id');
      expect(capturedClientId, 'test-ios-client-id');
    });

    test('passes null for blank Google client IDs', () {
      String? capturedServerClientId = 'not called';
      String? capturedClientId = 'not called';

      AppDependencies.createFirebaseAuthDataSource(
        googleSignInConfig: const GoogleSignInConfig(
          serverClientId: ' ',
          iosClientId: ' ',
        ),
        createDataSource: ({googleClientId, googleServerClientId}) {
          capturedServerClientId = googleServerClientId;
          capturedClientId = googleClientId;
          return FirebaseAuthDataSource();
        },
      );

      expect(capturedServerClientId, isNull);
      expect(capturedClientId, isNull);
    });

    test('uses compile-time Google client IDs by default', () {
      const config = GoogleSignInConfig.fromEnvironment();
      String? capturedServerClientId = 'not called';
      String? capturedClientId = 'not called';

      AppDependencies.createFirebaseAuthDataSource(
        createDataSource: ({googleClientId, googleServerClientId}) {
          capturedServerClientId = googleServerClientId;
          capturedClientId = googleClientId;
          return FirebaseAuthDataSource();
        },
      );

      expect(capturedServerClientId, config.serverClientId);
      expect(capturedClientId, config.iosClientId);
    });

    test(
      'constructs all cubits with firebase provider lazily without crash',
      () async {
        final authCubit = AppDependencies.createAuthCubit(
          provider: BackendProvider.firebase,
        );
        final listingsCubit = AppDependencies.createLessonListingsCubit(
          provider: BackendProvider.firebase,
        );
        final detailCubit = AppDependencies.createLessonListingDetailCubit(
          'lesson-1',
          provider: BackendProvider.firebase,
        );
        final createCubit = AppDependencies.createCreateLessonListingCubit(
          provider: BackendProvider.firebase,
        );

        await authCubit.close();
        await listingsCubit.close();
        await detailCubit.close();
        await createCubit.close();
      },
    );
  });
}

class _FakeFirebaseApp extends Fake implements FirebaseApp {}
