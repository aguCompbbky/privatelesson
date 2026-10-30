import 'package:privatelesson/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:privatelesson/features/auth/data/datasources/mock_user_profile_data_source.dart';
import 'package:privatelesson/features/auth/data/dtos/auth_user_dto.dart';
import 'package:privatelesson/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:privatelesson/features/auth/data/repositories/user_profile_repository_impl.dart';
import 'package:privatelesson/features/auth/domain/usecases/get_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/save_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
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

/// The single composition point for concrete application dependencies.
abstract final class AppDependencies {
  static final MockLessonListingDataSource _listingDataSource =
      MockLessonListingDataSource.seeded();
  static const PlatformExternalContactDataSource _externalContactDataSource =
      PlatformExternalContactDataSource();

  /// Builds publication using the same storage as listing search and detail.
  static CreateLessonListingCubit createCreateLessonListingCubit() =>
      CreateLessonListingCubit(
        createLessonListingUseCase: CreateLessonListingUseCase(
          LessonListingRepositoryImpl(_listingDataSource),
        ),
      );

  /// Builds listing search with storage shared for this process's lifetime.
  static LessonListingsCubit createLessonListingsCubit() => LessonListingsCubit(
    getLessonListingsUseCase: GetLessonListingsUseCase(
      LessonListingRepositoryImpl(_listingDataSource),
    ),
  );

  /// Builds detail and contact actions for the requested listing.
  static LessonListingDetailCubit createLessonListingDetailCubit(
    String listingId,
  ) {
    final listings = LessonListingRepositoryImpl(_listingDataSource);
    const contacts = ExternalContactRepositoryImpl(_externalContactDataSource);
    return LessonListingDetailCubit(
      listingId: listingId,
      getLessonListingDetailUseCase: GetLessonListingDetailUseCase(listings),
      openWhatsAppContactUseCase: const OpenWhatsAppContactUseCase(contacts),
      openEmailContactUseCase: const OpenEmailContactUseCase(contacts),
      copyContactValueUseCase: const CopyContactValueUseCase(contacts),
    );
  }

  static final MockUserProfileDataSource _profileDataSource =
      MockUserProfileDataSource();

  /// Builds authentication with a successful in-memory provider by default.
  ///
  /// The caller closes the cubit; profiles survive for this process's lifetime.
  static AuthCubit createAuthCubit() {
    final dataSource = MockAuthDataSource(
      user: const AuthUserDto(userId: 'mock-user', displayName: 'Mock User'),
    );
    final repository = AuthRepositoryImpl(dataSource);
    final profileRepository = UserProfileRepositoryImpl(_profileDataSource);

    return AuthCubit(
      signInWithGoogleUseCase: SignInWithGoogleUseCase(repository),
      signOutUseCase: SignOutUseCase(repository),
      getUserProfileUseCase: GetUserProfileUseCase(profileRepository),
      saveUserProfileUseCase: SaveUserProfileUseCase(profileRepository),
    );
  }
}
