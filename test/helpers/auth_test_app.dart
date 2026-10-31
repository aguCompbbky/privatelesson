import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/constants/app_assets.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/di/app_dependencies.dart';
import 'package:privatelesson/core/di/backend_provider.dart';
import 'package:privatelesson/core/routing/app_router.dart';
import 'package:privatelesson/core/theme/theme.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';
import 'package:privatelesson/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:privatelesson/features/auth/data/repositories/user_profile_repository_impl.dart';
import 'package:privatelesson/features/auth/domain/repositories/auth_repository.dart';
import 'package:privatelesson/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:privatelesson/features/auth/domain/usecases/get_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/register_with_email_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/save_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_cubit.dart';

/// Identity used by page tests that exercise the real mock data sources.
const testAuthUser = AuthUserDto(userId: 'test-user', displayName: 'Test User');
const _preferencesChannel = MethodChannel(
  'plugins.flutter.io/shared_preferences',
);

/// Initializes localization and selects mock backends without native services.
void configureTestLocalization() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => AppDependencies.activeProvider = BackendProvider.mock);
  tearDown(() => AppDependencies.activeProvider = null);
  setUpAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _preferencesChannel,
      (call) async => <String, Object>{},
    );
    await EasyLocalization.ensureInitialized();
  });
  tearDownAll(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _preferencesChannel,
      null,
    );
  });
}

/// Creates a real cubit with isolated profile storage by default.
AuthCubit createTestAuthCubit({
  AuthRepository? authRepository,
  UserProfileRepository? profileRepository,
}) {
  final auth =
      authRepository ??
      AuthRepositoryImpl(MockAuthDataSource(user: testAuthUser));
  final profiles =
      profileRepository ??
      UserProfileRepositoryImpl(MockUserProfileDataSource());
  final cubit = AuthCubit(
    signInWithGoogleUseCase: SignInWithGoogleUseCase(auth),
    signInWithEmailUseCase: SignInWithEmailUseCase(auth),
    registerWithEmailUseCase: RegisterWithEmailUseCase(auth),
    signOutUseCase: SignOutUseCase(auth),
    getUserProfileUseCase: GetUserProfileUseCase(profiles),
    saveUserProfileUseCase: SaveUserProfileUseCase(profiles),
  );
  addTearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
  });
  return cubit;
}

/// Mounts the production router so page tests exercise its real redirects.
Future<GoRouter> pumpAuthApp(
  WidgetTester tester,
  AuthCubit cubit, {
  Locale locale = AppConstants.turkishLocale,
  CreateLessonListingCubit Function()? createCreateLessonListingCubit,
  LessonListingsCubit Function()? createLessonListingsCubit,
  LessonListingDetailCubit Function(String listingId)?
  createLessonListingDetailCubit,
}) async {
  final router = AppRouter.createRouter(
    cubit,
    createCreateLessonListingCubit: createCreateLessonListingCubit,
    createLessonListingsCubit: createLessonListingsCubit,
    createLessonListingDetailCubit: createLessonListingDetailCubit,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    localizedApp(
      locale: locale,
      child: BlocProvider.value(
        value: cubit,
        child: Builder(
          builder: (context) => MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Uses the real translation files without a built asset bundle.
Widget localizedApp({
  required Widget child,
  Locale locale = AppConstants.turkishLocale,
}) => EasyLocalization(
  supportedLocales: AppConstants.supportedLocales,
  path: AppAssets.translationsDir,
  fallbackLocale: AppConstants.fallbackLocale,
  startLocale: locale,
  saveLocale: false,
  assetLoader: const _FileAssetLoader(),
  child: child,
);

/// Returns the real translated section for independent UI assertions.
Map<String, dynamic> translationSection(Locale locale, String section) =>
    _readTranslations(AppAssets.translationsDir, locale)[section]
        as Map<String, dynamic>;

Map<String, dynamic> _readTranslations(String path, Locale locale) =>
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>;

class _FileAssetLoader extends AssetLoader {
  const _FileAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      _readTranslations(path, locale);
}
