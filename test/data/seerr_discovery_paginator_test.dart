import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_paginator.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

SeerrDiscoverItem _item(int id, {String? mediaType}) => SeerrDiscoverItem(
      id: id,
      title: 'Item $id',
      mediaType: mediaType,
    );

void main() {
  const query = SeerrDiscoveryQuery(
    source: SeerrDiscoverySource.discoverMovies,
    mediaType: 'movie',
  );

  test('reads ahead through sparse pages until it has a useful window', () async {
    final pages = <int, SeerrDiscoverPage>{
      1: SeerrDiscoverPage(
        page: 1,
        totalPages: 4,
        results: [_item(1), _item(2)],
      ),
      2: SeerrDiscoverPage(
        page: 2,
        totalPages: 4,
        results: [_item(3), _item(4)],
      ),
      3: SeerrDiscoverPage(
        page: 3,
        totalPages: 4,
        results: [_item(5), _item(6)],
      ),
    };

    final paginator = SeerrDiscoveryPaginator(
      query: query,
      minimumMatchesPerLoad: 5,
      fetchPage: (_, page) async => pages[page]!,
    );

    final window = await paginator.loadNext();
    expect(window.fromPage, 1);
    expect(window.throughPage, 3);
    expect(window.items.map((item) => item.id), [1, 2, 3, 4, 5, 6]);
    expect(paginator.currentPage, 3);
    expect(paginator.canLoadMore, isTrue);
  });

  test('suppresses exact duplicates across source page boundaries', () async {
    final paginator = SeerrDiscoveryPaginator(
      query: query,
      minimumMatchesPerLoad: 2,
      fetchPage: (_, page) async => switch (page) {
        1 => SeerrDiscoverPage(
            page: 1,
            totalPages: 2,
            results: [_item(1), _item(2)],
          ),
        _ => SeerrDiscoverPage(
            page: 2,
            totalPages: 2,
            results: [_item(2), _item(3)],
          ),
      },
    );

    final first = await paginator.loadNext();
    final second = await paginator.loadNext();
    expect(first.items.map((item) => item.id), [1, 2]);
    expect(second.items.map((item) => item.id), [3]);
    expect(paginator.uniqueItemCount, 3);
    expect(paginator.canLoadMore, isFalse);
  });

  test('mixed trending endpoint respects lane media type', () async {
    const movieTrending = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.trending,
      mediaType: 'movie',
    );
    final paginator = SeerrDiscoveryPaginator(
      query: movieTrending,
      minimumMatchesPerLoad: 2,
      maxPagesPerScan: 2,
      fetchPage: (_, page) async => SeerrDiscoverPage(
        page: page,
        totalPages: 2,
        results: [
          _item(page * 10 + 1, mediaType: 'tv'),
          _item(page * 10 + 2, mediaType: 'movie'),
        ],
      ),
    );

    final window = await paginator.loadNext();
    expect(window.items.map((item) => item.mediaType), everyElement('movie'));
    expect(window.items.length, 2);
  });

  test('predicate can filter results and read ahead remains bounded', () async {
    var calls = 0;
    final paginator = SeerrDiscoveryPaginator(
      query: query,
      minimumMatchesPerLoad: 5,
      maxPagesPerScan: 3,
      include: (item) => item.id.isEven,
      fetchPage: (_, page) async {
        calls++;
        return SeerrDiscoverPage(
          page: page,
          totalPages: 20,
          results: [_item(page * 10 + 1), _item(page * 10 + 2)],
        );
      },
    );

    final window = await paginator.loadNext();
    expect(calls, 3);
    expect(window.items.map((item) => item.id), [12, 22, 32]);
    expect(paginator.currentPage, 3);
  });

  test('reset makes the paginator reusable from page one', () async {
    final calls = <int>[];
    final paginator = SeerrDiscoveryPaginator(
      query: query,
      minimumMatchesPerLoad: 1,
      fetchPage: (_, page) async {
        calls.add(page);
        return SeerrDiscoverPage(
          page: page,
          totalPages: 1,
          results: [_item(1)],
        );
      },
    );

    await paginator.loadNext();
    expect(paginator.canLoadMore, isFalse);
    paginator.reset();
    await paginator.loadNext();
    expect(calls, [1, 1]);
  });
}
