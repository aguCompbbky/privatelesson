import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/teacher_contact_info.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/external_contact_failure.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_state.dart';

import '../../../../helpers/lesson_listings_test_support.dart';

void main() {
  test('loads requested detail through loading and success', () async {
    final completion = Completer<LessonListing>();
    final repository = TestLessonRepository(onDetail: (_) => completion.future);
    final cubit = testDetailCubit(repository: repository);
    expect(cubit.state.listing, isNull);
    final states = cubit.stream.toList();
    final request = cubit.loadDetail();
    expect(cubit.state.isLoading, isTrue);
    final listing = testListing();
    completion.complete(listing);
    await request;
    expect(repository.requestedIds, [cubit.listingId]);
    expect(cubit.state.listing, same(listing));
    expect(cubit.state.failureType, isNull);
    await cubit.close();
    expect((await states).map((state) => state.isLoading), [true, false]);
  });

  for (final type in LessonListingFailureType.values) {
    test('preserves $type and retries', () async {
      final repository = TestLessonRepository(
        onDetail: (_) => Future.error(LessonListingFailure(type)),
      );
      final cubit = testDetailCubit(repository: repository);
      await cubit.loadDetail();
      expect(cubit.state.failureType, type);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.contactState, isNull);
      repository.onDetail = null;
      await cubit.retry();
      expect(repository.requestedIds, [cubit.listingId, cubit.listingId]);
      expect(cubit.state.failureType, isNull);
      expect(cubit.state.listing, isNotNull);
    });
  }

  for (final type in ExternalContactFailureType.values) {
    for (final channel in ContactChannel.values) {
      test('$channel retains $type and its published value', () async {
        final contacts = TestContactRepository(
          onOpen: (_) => Future.error(ExternalContactFailure(type)),
        );
        final cubit = testDetailCubit(contacts: contacts);
        await cubit.loadDetail();
        final value = channel == ContactChannel.whatsApp
            ? cubit.state.listing!.contact.whatsAppNumber
            : cubit.state.listing!.contact.emailAddress;
        if (channel == ContactChannel.whatsApp) {
          await cubit.openWhatsApp();
        } else {
          await cubit.openEmail();
        }
        final failed = cubit.state.contactState!;
        expect(failed.channel, channel);
        expect(failed.failureType, type);
        expect(failed.value, value);
        expect(failed.isPending, isFalse);
        expect(failed.isCopied, isFalse);
        expect(cubit.state.failureType, isNull);
        if (channel == ContactChannel.whatsApp) {
          await cubit.copyWhatsApp();
        } else {
          await cubit.copyEmail();
        }
        expect(contacts.copiedValues, [value]);
        final copied = cubit.state.contactState!;
        expect(copied.channel, channel);
        expect(copied.value, value);
        expect(copied.isCopied, isTrue);
        expect(copied.failureType, isNull);
      });
    }
  }

  test('opens both channels successfully without claiming a copy', () async {
    final contacts = TestContactRepository();
    final cubit = testDetailCubit(contacts: contacts);
    await cubit.loadDetail();
    await cubit.openWhatsApp();
    expect(contacts.whatsAppValues, ['+905550000001']);
    expect(cubit.state.contactState!.failureType, isNull);
    expect(cubit.state.contactState!.isCopied, isFalse);
    await cubit.openEmail();
    expect(contacts.emailValues, ['teacher@example.invalid']);
    expect(cubit.state.contactState!.channel, ContactChannel.email);
  });

  test('clipboard failure preserves context for retry', () async {
    final contacts = TestContactRepository(
      onCopy: (_) => Future.error(
        const ExternalContactFailure(
          ExternalContactFailureType.clipboardFailed,
        ),
      ),
    );
    final cubit = testDetailCubit(contacts: contacts);
    await cubit.loadDetail();
    await cubit.copyEmail();
    expect(
      cubit.state.contactState!.failureType,
      ExternalContactFailureType.clipboardFailed,
    );
    expect(cubit.state.contactState!.channel, ContactChannel.email);
    expect(cubit.state.contactState!.value, 'teacher@example.invalid');
    expect(cubit.state.contactState!.isCopied, isFalse);
    contacts.onCopy = null;
    await cubit.copyEmail();
    expect(cubit.state.contactState!.isCopied, isTrue);
  });

  test('validates published contact values before opening', () async {
    final contacts = TestContactRepository();
    final cubit = testDetailCubit(
      contacts: contacts,
      repository: TestLessonRepository(
        onDetail: (_) async => testListing(
          contact: const TeacherContactInfo(
            whatsAppNumber: 'invalid phone',
            emailAddress: 'invalid email',
          ),
        ),
      ),
    );
    await cubit.loadDetail();
    await cubit.openWhatsApp();
    expect(
      cubit.state.contactState!.failureType,
      ExternalContactFailureType.invalidContactValue,
    );
    expect(cubit.state.contactState!.value, 'invalid phone');
    await cubit.openEmail();
    expect(cubit.state.contactState!.value, 'invalid email');
    expect(contacts.whatsAppValues, isEmpty);
    expect(contacts.emailValues, isEmpty);
  });

  test('ignores absent contact methods and actions before loading', () async {
    final contacts = TestContactRepository();
    final cubit = testDetailCubit(
      contacts: contacts,
      repository: TestLessonRepository(
        onDetail: (_) async => testListing(contact: const TeacherContactInfo()),
      ),
    );
    for (final operation in [
      cubit.openWhatsApp,
      cubit.openEmail,
      cubit.copyWhatsApp,
      cubit.copyEmail,
    ]) {
      await operation();
    }
    await cubit.loadDetail();
    for (final operation in [
      cubit.openWhatsApp,
      cubit.openEmail,
      cubit.copyWhatsApp,
      cubit.copyEmail,
    ]) {
      await operation();
    }
    expect(contacts.whatsAppValues, isEmpty);
    expect(contacts.emailValues, isEmpty);
    expect(contacts.copiedValues, isEmpty);
    expect(cubit.state.contactState, isNull);
  });

  test('serializes contact actions across detail reloads', () async {
    final completion = Completer<void>();
    final contacts = TestContactRepository(onOpen: (_) => completion.future);
    final cubit = testDetailCubit(contacts: contacts);
    await cubit.loadDetail();
    final pending = cubit.openWhatsApp();
    expect(cubit.state.contactState!.isPending, isTrue);
    await cubit.openEmail();
    await cubit.copyWhatsApp();
    expect(contacts.emailValues, isEmpty);
    expect(contacts.copiedValues, isEmpty);
    await cubit.retry();
    final refreshed = cubit.state;
    completion.complete();
    await pending;
    expect(cubit.state, same(refreshed));
    expect(cubit.state.contactState, isNull);
  });

  for (final error in <Object>[Exception('Unexpected'), StateError('Bug')]) {
    test('restores detail after $error and permits another load', () async {
      final repository = TestLessonRepository();
      final cubit = testDetailCubit(repository: repository);
      await cubit.loadDetail();
      final previous = cubit.state;
      repository.onDetail = (_) => Future.error(error);
      await expectLater(cubit.retry(), throwsA(same(error)));
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.listing, same(previous.listing));
      expect(cubit.state, isNot(same(previous)));
      repository.onDetail = null;
      await cubit.retry();
      expect(cubit.state.listing, isNotNull);
    });

    test('restores contact feedback after $error', () async {
      final contacts = TestContactRepository();
      final cubit = testDetailCubit(contacts: contacts);
      await cubit.loadDetail();
      await cubit.copyEmail();
      final previous = cubit.state;
      contacts.onOpen = (_) => Future.error(error);
      await expectLater(cubit.openWhatsApp(), throwsA(same(error)));
      expect(cubit.state.contactState, same(previous.contactState));
      expect(cubit.state.contactState!.isPending, isFalse);
      expect(cubit.state, isNot(same(previous)));
      contacts.onOpen = null;
      await cubit.openWhatsApp();
      expect(cubit.state.contactState!.channel, ContactChannel.whatsApp);
    });
  }

  for (final fail in [false, true]) {
    test('discards stale detail completion, failure: $fail', () async {
      final completion = Completer<LessonListing>();
      final repository = TestLessonRepository(
        onDetail: (_) => completion.future,
      );
      final cubit = testDetailCubit(repository: repository);
      final older = cubit.loadDetail();
      repository.onDetail = null;
      await cubit.retry();
      final current = cubit.state;
      if (fail) {
        completion.completeError(
          const LessonListingFailure(LessonListingFailureType.notFound),
        );
      } else {
        completion.complete(testListing(id: 'old'));
      }
      await older;
      expect(cubit.state, same(current));
    });

    test('ignores detail completion after close, failure: $fail', () async {
      final completion = Completer<LessonListing>();
      final repository = TestLessonRepository(
        onDetail: (_) => completion.future,
      );
      final cubit = testDetailCubit(repository: repository);
      final pending = cubit.loadDetail();
      await cubit.close();
      if (fail) {
        completion.completeError(
          const LessonListingFailure(LessonListingFailureType.storage),
        );
      } else {
        completion.complete(testListing());
      }
      await pending;
      await cubit.retry();
      await cubit.openEmail();
      expect(repository.requestedIds, hasLength(1));
    });

    test('ignores contact completion after close, failure: $fail', () async {
      final completion = Completer<void>();
      final contacts = TestContactRepository(onOpen: (_) => completion.future);
      final cubit = testDetailCubit(contacts: contacts);
      await cubit.loadDetail();
      final pending = cubit.openEmail();
      await cubit.close();
      if (fail) {
        completion.completeError(
          const ExternalContactFailure(
            ExternalContactFailureType.cannotOpenExternalApp,
          ),
        );
      } else {
        completion.complete();
      }
      await pending;
      expect(contacts.emailValues, hasLength(1));
    });
  }
}
