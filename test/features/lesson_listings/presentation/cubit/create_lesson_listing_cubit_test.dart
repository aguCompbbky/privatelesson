import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_state.dart';

import '../../../../helpers/lesson_listings_test_support.dart';

const _teacher = UserProfile(
  userId: 'teacher-test',
  displayName: 'İpek Yılmaz',
  role: UserRole.teacher,
);
const _student = UserProfile(
  userId: 'student-test',
  displayName: 'Student',
  role: UserRole.student,
);

void main() {
  test('starts empty with online mode and no contact sharing', () {
    final state = testCreateListingCubit().state;
    expect(state.subject, isEmpty);
    expect(state.description, isEmpty);
    expect(state.deliveryMode, LessonDeliveryMode.online);
    expect(state.hasCertificate, isFalse);
    expect(state.certificateDescription, isEmpty);
    expect(state.shareWhatsApp, isFalse);
    expect(state.whatsAppNumber, isEmpty);
    expect(state.shareEmail, isFalse);
    expect(state.emailAddress, isEmpty);
    expect(state.isSubmitting, isFalse);
    expect(state.failureType, isNull);
    expect(state.createdListing, isNull);
  });

  for (final channels in [(true, false), (false, true), (true, true)]) {
    test('publishes only selected channels $channels', () async {
      final repository = TestLessonRepository();
      final cubit = testCreateListingCubit(repository: repository);
      _fillLesson(cubit);
      cubit.updateWhatsAppNumber(' +90 (555) 000-00-01 ');
      cubit.updateEmailAddress(' contact@example.invalid ');
      cubit.setShareWhatsApp(value: channels.$1);
      cubit.setShareEmail(value: channels.$2);
      final states = <CreateLessonListingState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.submit(_teacher);
      await pumpEventQueue();

      expect(states.map((state) => state.isSubmitting), [true, false]);
      expect(cubit.state.failureType, isNull);
      final listing = cubit.state.createdListing!;
      expect(repository.created, hasLength(1));
      expect(listing.teacherId, _teacher.userId);
      expect(listing.teacherName, _teacher.displayName);
      expect(listing.subject, 'Matematik');
      expect(listing.description, 'Birebir ders.');
      expect(
        listing.contact.whatsAppNumber,
        channels.$1 ? '+905550000001' : null,
      );
      expect(
        listing.contact.emailAddress,
        channels.$2 ? 'contact@example.invalid' : null,
      );
    });
  }

  test('toggles preserve edits but omit unselected values', () async {
    final repository = TestLessonRepository();
    final cubit = testCreateListingCubit(repository: repository);
    _fillValid(cubit);
    cubit.setHasCertificate(value: true);
    cubit.updateCertificateDescription(' Öğretmenlik diploması ');
    cubit.selectDeliveryMode(LessonDeliveryMode.recordedVideo);
    cubit.setShareWhatsApp(value: true);
    cubit.updateWhatsAppNumber('+905550000001');
    await cubit.submit(_teacher);
    expect(cubit.state.createdListing!.certification.hasCertificate, isTrue);
    expect(
      cubit.state.createdListing!.certification.certificateDescription,
      'Öğretmenlik diploması',
    );
    expect(
      cubit.state.createdListing!.deliveryMode,
      LessonDeliveryMode.recordedVideo,
    );
    cubit.setHasCertificate(value: false);
    cubit.setShareWhatsApp(value: false);
    expect(cubit.state.certificateDescription, ' Öğretmenlik diploması ');
    expect(cubit.state.whatsAppNumber, '+905550000001');
    await cubit.submit(_teacher);
    final saved = cubit.state.createdListing!;
    expect(saved.certification.hasCertificate, isFalse);
    expect(saved.certification.certificateDescription, isNull);
    expect(saved.contact.whatsAppNumber, isNull);
    expect(saved.contact.emailAddress, 'contact@example.invalid');
  });

  test('rejects students before all input validation and storage', () async {
    final repository = TestLessonRepository();
    final cubit = testCreateListingCubit(repository: repository);
    await cubit.submit(_student);
    expect(cubit.state.failureType, LessonListingFailureType.unauthorizedRole);
    expect(repository.created, isEmpty);
  });

  test('rejects incomplete teacher identity', () async {
    final repository = TestLessonRepository();
    final cubit = testCreateListingCubit(repository: repository);
    _fillValid(cubit);
    await cubit.submit(
      const UserProfile(userId: '', displayName: '', role: UserRole.teacher),
    );
    expect(
      cubit.state.failureType,
      LessonListingFailureType.invalidTeacherInfo,
    );
    expect(repository.created, isEmpty);
  });

  test('validates lesson and certificate before contacts', () async {
    final repository = TestLessonRepository();
    final cubit = testCreateListingCubit(repository: repository);
    cubit.setHasCertificate(value: true);
    cubit.setShareWhatsApp(value: true);
    cubit.setShareEmail(value: true);
    await cubit.submit(_teacher);
    expect(cubit.state.failureType, LessonListingFailureType.invalidSubject);
    cubit.updateSubject('Matematik');
    await cubit.submit(_teacher);
    expect(
      cubit.state.failureType,
      LessonListingFailureType.invalidDescription,
    );
    cubit.updateDescription('Birebir ders.');
    await cubit.submit(_teacher);
    expect(
      cubit.state.failureType,
      LessonListingFailureType.missingCertificateDescription,
    );
    cubit.updateCertificateDescription('Diploma');
    await cubit.submit(_teacher);
    expect(
      cubit.state.failureType,
      LessonListingFailureType.invalidWhatsAppNumber,
    );
    cubit.updateWhatsAppNumber('+905550000001');
    await cubit.submit(_teacher);
    expect(
      cubit.state.failureType,
      LessonListingFailureType.invalidEmailAddress,
    );
    expect(repository.created, isEmpty);
  });

  for (final blank in ['', ' \t\n ']) {
    for (final otherSelected in [false, true]) {
      test('selected blank WhatsApp $blank, other $otherSelected', () async {
        final repository = TestLessonRepository();
        final cubit = testCreateListingCubit(repository: repository);
        _fillLesson(cubit);
        cubit.setShareWhatsApp(value: true);
        cubit.updateWhatsAppNumber(blank);
        cubit.setShareEmail(value: otherSelected);
        cubit.updateEmailAddress('contact@example.invalid');
        await cubit.submit(_teacher);
        expect(
          cubit.state.failureType,
          LessonListingFailureType.invalidWhatsAppNumber,
        );
        expect(repository.created, isEmpty);
      });
      test('selected blank email $blank, other $otherSelected', () async {
        final repository = TestLessonRepository();
        final cubit = testCreateListingCubit(repository: repository);
        _fillLesson(cubit);
        cubit.setShareEmail(value: true);
        cubit.updateEmailAddress(blank);
        cubit.setShareWhatsApp(value: otherSelected);
        cubit.updateWhatsAppNumber('+905550000001');
        await cubit.submit(_teacher);
        expect(
          cubit.state.failureType,
          LessonListingFailureType.invalidEmailAddress,
        );
        expect(repository.created, isEmpty);
      });
    }
  }

  test('requires explicit sharing of filled contact values', () async {
    final repository = TestLessonRepository();
    final cubit = testCreateListingCubit(repository: repository);
    _fillLesson(cubit);
    cubit.updateEmailAddress('contact@example.invalid');
    cubit.updateWhatsAppNumber('+905550000001');
    await cubit.submit(_teacher);
    expect(
      cubit.state.failureType,
      LessonListingFailureType.missingContactMethod,
    );
    expect(repository.created, isEmpty);
  });

  test('rejects malformed contacts alongside valid ones', () async {
    final repository = TestLessonRepository();
    final cubit = testCreateListingCubit(repository: repository);
    _fillValid(cubit);
    cubit.setShareWhatsApp(value: true);
    cubit.updateWhatsAppNumber('05550000001');
    await cubit.submit(_teacher);
    expect(
      cubit.state.failureType,
      LessonListingFailureType.invalidWhatsAppNumber,
    );
    cubit.updateWhatsAppNumber('+905550000001');
    cubit.updateEmailAddress('invalid-email');
    await cubit.submit(_teacher);
    expect(
      cubit.state.failureType,
      LessonListingFailureType.invalidEmailAddress,
    );
    expect(repository.created, isEmpty);
  });

  for (final type in LessonListingFailureType.values) {
    test('preserves domain failure ${type.name} and allows retry', () async {
      final repository = TestLessonRepository(
        onCreate: (_) => Future.error(LessonListingFailure(type)),
      );
      final cubit = testCreateListingCubit(repository: repository);
      _fillValid(cubit);
      await cubit.submit(_teacher);
      expect(cubit.state.failureType, type);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.createdListing, isNull);
      expect(cubit.state.subject, ' Matematik ');
      repository.onCreate = null;
      await cubit.submit(_teacher);
      expect(cubit.state.createdListing, isNotNull);
      expect(cubit.state.failureType, isNull);
    });
  }

  for (final edit in _edits.entries) {
    test('${edit.key} clears failure feedback', () async {
      final cubit = testCreateListingCubit();
      await cubit.submit(_teacher);
      expect(cubit.state.failureType, isNotNull);
      edit.value(cubit);
      expect(cubit.state.failureType, isNull);
    });
  }

  test('locks edits and duplicate submission while pending', () async {
    final completion = Completer<LessonListing>();
    final repository = TestLessonRepository(onCreate: (_) => completion.future);
    final cubit = testCreateListingCubit(repository: repository);
    _fillValid(cubit);
    final request = cubit.submit(_teacher);
    final pending = cubit.state;
    expect(pending.isSubmitting, isTrue);
    for (final edit in _edits.values) {
      edit(cubit);
      expect(cubit.state, same(pending));
    }
    await cubit.submit(_teacher);
    expect(repository.created, hasLength(1));
    final listing = testListing();
    completion.complete(listing);
    await request;
    expect(cubit.state.createdListing, same(listing));
    expect(cubit.state.isSubmitting, isFalse);
  });

  test('restores editable values and rethrows unexpected errors', () async {
    final error = StateError('unexpected storage bug');
    final repository = TestLessonRepository(
      onCreate: (_) => Future.error(error),
    );
    final cubit = testCreateListingCubit(repository: repository);
    _fillValid(cubit);
    await expectLater(cubit.submit(_teacher), throwsA(same(error)));
    expect(cubit.state.isSubmitting, isFalse);
    expect(cubit.state.failureType, isNull);
    expect(cubit.state.createdListing, isNull);
    expect(cubit.state.emailAddress, 'contact@example.invalid');
    cubit.updateSubject('Fizik');
    expect(cubit.state.subject, 'Fizik');
    repository.onCreate = null;
    await cubit.submit(_teacher);
    expect(cubit.state.createdListing!.subject, 'Fizik');
  });

  test('ignores all edits and submission after close', () async {
    final repository = TestLessonRepository();
    final cubit = testCreateListingCubit(repository: repository);
    await cubit.close();
    final closed = cubit.state;
    for (final edit in _edits.values) {
      edit(cubit);
    }
    await cubit.submit(_teacher);
    expect(cubit.state, same(closed));
    expect(repository.created, isEmpty);
  });

  for (final outcome in ['success', 'failure', 'unexpected']) {
    test('does not emit after close during pending $outcome', () async {
      final completion = Completer<LessonListing>();
      final cubit = testCreateListingCubit(
        repository: TestLessonRepository(onCreate: (_) => completion.future),
      );
      _fillValid(cubit);
      final request = cubit.submit(_teacher);
      final error = StateError('late storage bug');
      final expectation = outcome == 'unexpected'
          ? expectLater(request, throwsA(same(error)))
          : expectLater(request, completes);
      await cubit.close();
      final closed = cubit.state;
      switch (outcome) {
        case 'success':
          completion.complete(testListing());
        case 'failure':
          completion.completeError(
            const LessonListingFailure(LessonListingFailureType.connection),
          );
        case 'unexpected':
          completion.completeError(error);
      }
      await expectation;
      expect(cubit.state, same(closed));
    });
  }
}

void _fillLesson(CreateLessonListingCubit cubit) {
  cubit.updateSubject(' Matematik ');
  cubit.updateDescription(' Birebir ders. ');
}

void _fillValid(CreateLessonListingCubit cubit) {
  _fillLesson(cubit);
  cubit.setShareEmail(value: true);
  cubit.updateEmailAddress('contact@example.invalid');
}

final _edits = <String, void Function(CreateLessonListingCubit)>{
  'subject': (cubit) => cubit.updateSubject('Fizik'),
  'description': (cubit) => cubit.updateDescription('Yeni açıklama'),
  'delivery mode': (cubit) =>
      cubit.selectDeliveryMode(LessonDeliveryMode.inPerson),
  'certificate': (cubit) => cubit.setHasCertificate(value: true),
  'certificate description': (cubit) =>
      cubit.updateCertificateDescription('Diploma'),
  'WhatsApp sharing': (cubit) => cubit.setShareWhatsApp(value: true),
  'WhatsApp number': (cubit) => cubit.updateWhatsAppNumber('+905550000002'),
  'email sharing': (cubit) => cubit.setShareEmail(value: false),
  'email address': (cubit) => cubit.updateEmailAddress('new@example.invalid'),
};
