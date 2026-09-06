import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_paginator.dart';

const query = HomeLabDiscoveryQuery(
  source: HomeLabDiscoverySource.discoverMovies,
  mediaType: 'movie',
);

SeerrDiscoverItem item(int id, {String? mediaType = 'movie'}) =>
    SeerrDiscoverItem(id: id, mediaType: mediaType, title: 'Item $id');

void main() {
  test('reads ahead through sparse pages and deduplicates IDs', () async {
    final pages = <int, SeerrDiscoverPage>{
      1: SeerrDiscoverPage(
        page: 1,
        totalPages: 3,
        results: [item(1), item(2), item(2)],
      ),
      2: SeerrDiscoverPage(
        page: 2,
        totalPages: 3,
        results: [item(2), item(3), item(4)],
      ),
      3: SeerrDiscoverPage(page: 3, totalPages: 3, results: [item(5)]),
    };
    final paginator = HomeLabDiscoveryPaginator(
      query: query,
      fetchPage: (_, page) async => pages[page]!,
      minimumMatchesPerLoad: 4,
    );

    final first = await paginator.loadNext();
    expect(first.items.map((value) => value.id), [1, 2, 3, 4]);
    expect(first.throughPage, 2);
    expect(paginator.canLoadMore, isTrue);

    final second = await paginator.loadNext();
    expect(second.items.map((value) => value.id), [5]);
    expect(paginator.canLoadMore, isFalse);
  });

  test('media type and custom predicate are applied before output', () async {
    final paginator = HomeLabDiscoveryPaginator(
      query: query,
      fetchPage: (_, _) async => SeerrDiscoverPage(
        page: 1,
        totalPages: 1,
        results: [
          item(1),
          item(2, mediaType: 'tv'),
          item(3),
        ],
      ),
      include: (value) => value.id != 3,
    );

    final result = await paginator.loadNext();
    expect(result.items.map((value) => value.id), [1]);
  });
}
