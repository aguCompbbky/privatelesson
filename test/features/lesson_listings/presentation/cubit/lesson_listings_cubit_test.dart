import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_delivery_mode.dart';
import 'package:privatelesson/features/lesson_listings/domain/entities/lesson_listing.dart';
import 'package:privatelesson/features/lesson_listings/domain/failures/lesson_listing_failure.dart';

import '../../../../helpers/lesson_listings_test_support.dart';

void main() {
  test('emits loading and immutable results', () async {
    final result = Completer<List<LessonListing>>();
    final repository = TestLessonRepository(onList: (_) => result.future);
    final cubit = testListingsCubit(repository: repository);
    final initial = cubit.state;
    expect(initial.listings, isEmpty);
    expect(initial.filter.hasActiveFilters, isFalse);
    final states = cubit.stream.toList();
    final loading = cubit.loadListings();
    expect(cubit.state.isLoading, isTrue);
    final listings = [testListing()];
    result.complete(listings);
    await loading;
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.failureType, isNull);
    expect(cubit.state.listings, listings);
    listings.clear();
    expect(cubit.state.listings, hasLength(1));
    expect(() => cubit.state.listings.clear(), throwsUnsupportedError);
    await cubit.close();
    final emitted = await states;
    expect(emitted.map((state) => state.isLoading), [true, false]);
    expect(identical(emitted.first, emitted.last), isFalse);
  });

  test('combines, retries and clears criteria', () async {
    final repository = TestLessonRepository();
    final cubit = testListingsCubit(repository: repository);
    await cubit.updateSearchQuery('İpek');
    await cubit.selectDeliveryMode(LessonDeliveryMode.online);
    await cubit.setCertificateOnly(value: true);
    await cubit.retry();
    final filter = repository.filters.last;
    expect(filter.searchQuery, 'İpek');
    expect(filter.deliveryMode, LessonDeliveryMode.online);
    expect(filter.hasCertificateOnly, isTrue);
    expect(filter.hasActiveFilters, isTrue);
    await cubit.selectDeliveryMode(null);
    expect(cubit.state.filter.deliveryMode, isNull);
    expect(cubit.state.filter.searchQuery, 'İpek');
    await cubit.clearFilters();
    expect(cubit.state.filter.hasActiveFilters, isFalse);
    expect(cubit.state.filter.searchQuery, isEmpty);
    expect(repository.filters, hasLength(6));
  });

  for (final type in LessonListingFailureType.values) {
    test('preserves $type and permits retry with the same query', () async {
      final repository = TestLessonRepository(
        onList: (_) => Future.error(LessonListingFailure(type)),
      );
      final cubit = testListingsCubit(repository: repository);
      await cubit.updateSearchQuery('Matematik');
      expect(cubit.state.failureType, type);
      expect(cubit.state.isLoading, isFalse);
      repository.onList = (_) async => [];
      await cubit.retry();
      expect(repository.filters.last.searchQuery, 'Matematik');
      expect(cubit.state.failureType, isNull);
      expect(cubit.state.listings, isEmpty);
    });
  }

  for (final staleFailure in [false, true]) {
    test('ignores stale ${staleFailure ? 'failure' : 'success'}', () async {
      final older = Completer<List<LessonListing>>();
      final newer = Completer<List<LessonListing>>();
      final cubit = testListingsCubit(
        repository: TestLessonRepository(
          onList: (filter) {
            if (filter.searchQuery == 'old') {
              return older.future;
            }
            return newer.future;
          },
        ),
      );
      final first = cubit.updateSearchQuery('old');
      final second = cubit.updateSearchQuery('new');
      newer.complete([testListing(id: 'new')]);
      await second;
      final current = cubit.state;
      if (staleFailure) {
        older.completeError(
          const LessonListingFailure(LessonListingFailureType.connection),
        );
      } else {
        older.complete([testListing(id: 'old')]);
      }
      await first;
      expect(cubit.state, same(current));
      expect(cubit.state.listings.single.id, 'new');
      expect(cubit.state.filter.searchQuery, 'new');
    });
  }

  for (final error in <Object>[Exception('Unexpected'), StateError('Bug')]) {
    test('restores settled criteria after $error and rethrows', () async {
      final older = Completer<List<LessonListing>>();
      final repository = TestLessonRepository();
      final cubit = testListingsCubit(repository: repository);
      await cubit.updateSearchQuery('settled');
      final previous = cubit.state;
      repository.onList = (_) => older.future;
      final first = cubit.updateSearchQuery('pending');
      repository.onList = (_) => Future.error(error);
      await expectLater(
        cubit.updateSearchQuery('failing'),
        throwsA(same(error)),
      );
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.filter, same(previous.filter));
      expect(cubit.state.listings, previous.listings);
      expect(cubit.state, isNot(same(previous)));
      older.complete([]);
      await first;
      expect(cubit.state.filter.searchQuery, 'settled');
      repository.onList = (_) async => [];
      await cubit.retry();
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.listings, isEmpty);
    });
  }

  test('stale unexpected errors preserve newer state', () async {
    final result = Completer<List<LessonListing>>();
    final repository = TestLessonRepository(onList: (_) => result.future);
    final cubit = testListingsCubit(repository: repository);
    final error = StateError('Old request');
    final first = cubit.loadListings();
    final assertion = expectLater(first, throwsA(same(error)));
    repository.onList = (_) async => [testListing()];
    await cubit.updateSearchQuery('new');
    final current = cubit.state;
    result.completeError(error);
    await assertion;
    expect(cubit.state, same(current));
  });

  for (final fail in [false, true]) {
    test('ignores pending completion after close, failure: $fail', () async {
      final result = Completer<List<LessonListing>>();
      final repository = TestLessonRepository(onList: (_) => result.future);
      final cubit = testListingsCubit(repository: repository);
      final loading = cubit.loadListings();
      await cubit.close();
      if (fail) {
        result.completeError(
          const LessonListingFailure(LessonListingFailureType.storage),
        );
      } else {
        result.complete([]);
      }
      await loading;
      await cubit.retry();
      expect(repository.filters, hasLength(1));
    });
  }
}
