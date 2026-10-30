import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/mock_lesson_listing_data_source.dart';
import 'package:privatelesson/features/lesson_listings/data/repositories/lesson_listing_repository_impl.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/certification_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing_filter.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/new_lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/external_contact_repository.dart';
import 'package:privatelesson/features/lesson_listings/domain/repositories/lesson_listing_repository.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/copy_contact_value_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/create_lesson_listing_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/get_lesson_listing_detail_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/get_lesson_listings_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/open_email_contact_use_case.dart';
import 'package:privatelesson/features/lesson_listings/domain/usecases/open_whatsapp_contact_use_case.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_cubit.dart';

import 'auth_test_app.dart';

/// Creates a lesson fixture with independently configurable contact choices.
LessonListing testListing({
  String id = 'lesson-test',
  TeacherContactInfo contact = const TeacherContactInfo(
    whatsAppNumber: '+905550000001',
    emailAddress: 'teacher@example.invalid',
  ),
  bool hasCertificate = true,
}) => LessonListing(
  id: id,
  teacherId: 'teacher-test',
  teacherName: 'İpek Yılmaz',
  subject: 'Matematik',
  description: 'Birebir matematik dersi.',
  deliveryMode: LessonDeliveryMode.inPerson,
  certification: CertificationInfo(
    hasCertificate: hasCertificate,
    certificateDescription: hasCertificate ? 'Öğretmenlik diploması' : null,
  ),
  contact: contact,
);

/// Provides controllable reads without bypassing the real domain use cases.
class TestLessonRepository implements LessonListingRepository {
  /// Creates independently configurable list and detail requests.
  TestLessonRepository({this.onList, this.onDetail, this.onCreate});

  /// Optional publication implementation, defaulting to the submitted values.
  Future<LessonListing> Function(NewLessonListing)? onCreate;

  /// Normalized publication inputs received by the repository.
  final List<NewLessonListing> created = [];

  /// Optional query implementation, defaulting to a single fixture.
  Future<List<LessonListing>> Function(LessonListingFilter)? onList;

  /// Optional detail implementation, defaulting to the requested fixture.
  Future<LessonListing> Function(String)? onDetail;

  /// The ordered criteria received through the query use case.
  final List<LessonListingFilter> filters = [];

  /// The identifiers received through the detail use case.
  final List<String> requestedIds = [];

  @override
  Future<List<LessonListing>> getListings(LessonListingFilter filter) async {
    filters.add(filter);
    return onList == null ? [testListing()] : onList!(filter);
  }

  @override
  Future<LessonListing> getListingById(String id) async {
    requestedIds.add(id);
    return onDetail == null ? testListing(id: id) : onDetail!(id);
  }

  @override
  Future<LessonListing> createListing(NewLessonListing listing) async {
    created.add(listing);
    if (onCreate != null) {
      return onCreate!(listing);
    }
    return LessonListing(
      id: 'created-lesson',
      teacherId: listing.teacherId,
      teacherName: listing.teacherName,
      subject: listing.subject,
      description: listing.description,
      deliveryMode: listing.deliveryMode,
      certification: listing.certification,
      contact: listing.contact,
    );
  }
}

/// Records contact actions while allowing delayed or failed operations.
class TestContactRepository implements ExternalContactRepository {
  /// Creates optional overrides for opening and copying contact values.
  TestContactRepository({this.onOpen, this.onCopy});

  /// Optional override for either external contact channel.
  Future<void> Function(String)? onOpen;

  /// Optional override for clipboard operations.
  Future<void> Function(String)? onCopy;

  /// WhatsApp values passed to the repository.
  final List<String> whatsAppValues = [];

  /// Email values passed to the repository.
  final List<String> emailValues = [];

  /// Values submitted to the clipboard operation.
  final List<String> copiedValues = [];

  @override
  Future<void> openWhatsApp(String value) async {
    whatsAppValues.add(value);
    await onOpen?.call(value);
  }

  @override
  Future<void> openEmail(String value) async {
    emailValues.add(value);
    await onOpen?.call(value);
  }

  @override
  Future<void> copyContactValue(String value) async {
    copiedValues.add(value);
    await onCopy?.call(value);
  }
}

/// Creates an isolated creation cubit using the real validation use case.
CreateLessonListingCubit testCreateListingCubit({
  LessonListingRepository? repository,
}) {
  final cubit = CreateLessonListingCubit(
    createLessonListingUseCase: CreateLessonListingUseCase(
      repository ?? TestLessonRepository(),
    ),
  );
  addTearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
  });
  return cubit;
}

/// Creates a query cubit with isolated seeded storage unless overridden.
LessonListingsCubit testListingsCubit({LessonListingRepository? repository}) {
  final cubit = LessonListingsCubit(
    getLessonListingsUseCase: GetLessonListingsUseCase(
      repository ??
          LessonListingRepositoryImpl(MockLessonListingDataSource.seeded()),
    ),
  );
  addTearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
  });
  return cubit;
}

/// Creates a detail cubit with real use cases over replaceable repositories.
LessonListingDetailCubit testDetailCubit({
  String listingId = 'lesson-test',
  LessonListingRepository? repository,
  ExternalContactRepository? contacts,
}) {
  final external = contacts ?? TestContactRepository();
  final cubit = LessonListingDetailCubit(
    listingId: listingId,
    getLessonListingDetailUseCase: GetLessonListingDetailUseCase(
      repository ?? TestLessonRepository(),
    ),
    openWhatsAppContactUseCase: OpenWhatsAppContactUseCase(external),
    openEmailContactUseCase: OpenEmailContactUseCase(external),
    copyContactValueUseCase: CopyContactValueUseCase(external),
  );
  addTearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
  });
  return cubit;
}

/// Mounts the production routes and completes authentication before listing UI.
Future<GoRouter> pumpListingsApp(
  WidgetTester tester, {
  CreateLessonListingCubit Function()? createCreateLessonListingCubit,
  LessonListingsCubit Function()? createListings,
  LessonListingDetailCubit Function(String)? createDetail,
  String? listingId,
  UserRole role = UserRole.student,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = createTestAuthCubit();
  final router = await pumpAuthApp(
    tester,
    auth,
    createCreateLessonListingCubit: createCreateLessonListingCubit,
    createLessonListingsCubit: createListings,
    createLessonListingDetailCubit: createDetail,
  );
  // Drive the mock auth work and redirects with FakeAsync's frame pumps.
  // Check the resulting states instead of waiting on an unpumped future.
  unawaited(auth.signInWithGoogle());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(auth.state, isA<AuthProfileIncomplete>());
  auth.selectRole(role);
  unawaited(auth.completeProfile());
  await tester.pump();
  expect(auth.state, isA<AuthAuthenticated>());
  if (listingId != null) {
    // Finish the home route transition without waiting for its data to settle.
    await tester.pump(const Duration(milliseconds: 500));
    router.go(AppRoutes.listingDetailPath(listingId));
  }
  if (settle) {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
  } else {
    // At t=0 the incoming route is transparent and suppresses child semantics.
    // Advance only the transition while leaving controlled requests pending.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
  return router;
}

/// Reads expected copy independently from the production text accessor.
String listingCopy(String key, {Locale locale = AppConstants.turkishLocale}) {
  Object? value = translationSection(locale, 'listings');
  for (final part in key.split('.')) {
    value = (value! as Map<String, dynamic>)[part];
  }
  return value! as String;
}
