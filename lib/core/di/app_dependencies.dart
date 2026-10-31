import 'package:privatelesson/core/config/google_sign_in_config.dart';
import 'package:privatelesson/core/di/backend_provider.dart';
import 'package:privatelesson/features/auth/data/datasources/auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/firestore_user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';
import 'package:privatelesson/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:privatelesson/features/auth/data/repositories/user_profile_repository_impl.dart';
import 'package:privatelesson/features/auth/domain/usecases/get_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/register_with_email_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/save_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/firestore_lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/mock_lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/platform_external_contact_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/repositories/external_contact_repository_impl.dart';
import 'package:privatelesson/features/lesson_listings/data/repositories/lesson_listing_repository_impl.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/copy_contact_value_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/create_lesson_listing_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/get_lesson_listing_detail_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/get_lesson_listings_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/open_email_contact_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/open_whatsapp_contact_use_case.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_cubit.dart';

/// Constructs Firebase authentication without exposing provider SDK types.
typedef FirebaseAuthDataSourceFactory =
    FirebaseAuthDataSource Function({
      String? googleClientId,
      String? googleServerClientId,
    });

/// The single composition point for concrete application dependencies.
///
/// Selecting [BackendProvider.mock] or [BackendProvider.firebase] swaps only
/// the underlying data sources while leaving domain and presentation untouched.
abstract final class AppDependencies {
  static BackendProvider? _overrideProvider;

  static final MockLessonListingDataSource _mockListingDataSource =
      MockLessonListingDataSource.seeded();
  static final FirestoreLessonListingDataSource _firebaseListingDataSource =
      FirestoreLessonListingDataSource();
  static const PlatformExternalContactDataSource _externalContactDataSource =
      PlatformExternalContactDataSource();
  static final MockUserProfileDataSource _mockProfileDataSource =
      MockUserProfileDataSource();
  static final FirestoreUserProfileDataSource _firebaseProfileDataSource =
      FirestoreUserProfileDataSource();
  static final MockAuthDataSource _mockAuthDataSource = MockAuthDataSource(
    user: const AuthUserDto(userId: 'mock-user', displayName: 'Mock User'),
  );
  static final FirebaseAuthDataSource _firebaseAuthDataSource =
      createFirebaseAuthDataSource();

  /// Currently active backend provider (`firebase` unless overridden).
  static BackendProvider get activeProvider =>
      _overrideProvider ?? BackendProvider.fromEnvironment;

  /// Overrides or resets (`null`) the active provider at composition root.
  static set activeProvider(BackendProvider? provider) {
    _overrideProvider = provider;
  }

  /// Builds Firebase authentication with the configured Google client IDs.
  ///
  /// The factory can be replaced to verify wiring without invoking SDKs.
  static FirebaseAuthDataSource createFirebaseAuthDataSource({
    GoogleSignInConfig googleSignInConfig =
        const GoogleSignInConfig.fromEnvironment(),
    FirebaseAuthDataSourceFactory createDataSource = FirebaseAuthDataSource.new,
  }) => createDataSource(
    googleServerClientId: googleSignInConfig.serverClientId,
    googleClientId: googleSignInConfig.iosClientId,
  );

  /// Resolves the authentication data source for [provider].
  static AuthDataSource resolveAuthDataSource([BackendProvider? provider]) =>
      switch (provider ?? activeProvider) {
        BackendProvider.mock => _mockAuthDataSource,
        BackendProvider.firebase => _firebaseAuthDataSource,
      };

  /// Resolves the profile data source for [provider].
  static UserProfileDataSource resolveUserProfileDataSource([
    BackendProvider? provider,
  ]) => switch (provider ?? activeProvider) {
    BackendProvider.mock => _mockProfileDataSource,
    BackendProvider.firebase => _firebaseProfileDataSource,
  };

  /// Resolves the lesson listing data source for [provider].
  static LessonListingDataSource resolveLessonListingDataSource([
    BackendProvider? provider,
  ]) => switch (provider ?? activeProvider) {
    BackendProvider.mock => _mockListingDataSource,
    BackendProvider.firebase => _firebaseListingDataSource,
  };

  /// Builds publication using the same storage as listing search and detail.
  static CreateLessonListingCubit createCreateLessonListingCubit({
    BackendProvider? provider,
  }) => CreateLessonListingCubit(
    createLessonListingUseCase: CreateLessonListingUseCase(
      LessonListingRepositoryImpl(resolveLessonListingDataSource(provider)),
    ),
  );

  /// Builds listing search with storage shared for this process's lifetime.
  static LessonListingsCubit createLessonListingsCubit({
    BackendProvider? provider,
  }) => LessonListingsCubit(
    getLessonListingsUseCase: GetLessonListingsUseCase(
      LessonListingRepositoryImpl(resolveLessonListingDataSource(provider)),
    ),
  );

  /// Builds detail and contact actions for the requested listing.
  static LessonListingDetailCubit createLessonListingDetailCubit(
    String listingId, {
    BackendProvider? provider,
  }) {
    final listings = LessonListingRepositoryImpl(
      resolveLessonListingDataSource(provider),
    );
    const contacts = ExternalContactRepositoryImpl(_externalContactDataSource);
    return LessonListingDetailCubit(
      listingId: listingId,
      getLessonListingDetailUseCase: GetLessonListingDetailUseCase(listings),
      openWhatsAppContactUseCase: const OpenWhatsAppContactUseCase(contacts),
      openEmailContactUseCase: const OpenEmailContactUseCase(contacts),
      copyContactValueUseCase: const CopyContactValueUseCase(contacts),
    );
  }

  /// Builds authentication using the active provider (`firebase` by default).
  ///
  /// The caller closes the cubit; mock accounts/profiles live for this process.
  static AuthCubit createAuthCubit({BackendProvider? provider}) {
    final repository = AuthRepositoryImpl(resolveAuthDataSource(provider));
    final profileRepository = UserProfileRepositoryImpl(
      resolveUserProfileDataSource(provider),
    );

    return AuthCubit(
      signInWithGoogleUseCase: SignInWithGoogleUseCase(repository),
      signInWithEmailUseCase: SignInWithEmailUseCase(repository),
      registerWithEmailUseCase: RegisterWithEmailUseCase(repository),
      signOutUseCase: SignOutUseCase(repository),
      getUserProfileUseCase: GetUserProfileUseCase(profileRepository),
      saveUserProfileUseCase: SaveUserProfileUseCase(profileRepository),
    );
  }
}
