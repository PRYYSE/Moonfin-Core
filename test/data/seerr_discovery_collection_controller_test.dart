import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';
import 'package:moonfin/data/viewmodels/seerr_discovery_collection_controller.dart';

SeerrDiscoverItem _item(int id) =>
    SeerrDiscoverItem(id: id, mediaType: 'movie', title: 'Item $id');

void main() {
  const base = SeerrDiscoveryQuery(
    source: SeerrDiscoverySource.discoverMovies,
    mediaType: 'movie',
    sortBy: 'vote_average.desc',
    filters: {
      'voteAverageGte': '7.0',
      'voteCountGte': '150',
      'voteCountLte': '1500',
    },
  );

  test('loads and appends multiple deep collection windows', () async {
    final controller = SeerrDiscoveryCollectionController(
      baseQuery: base,
      minimumMatchesPerLoad: 2,
      fetchPage: (_, page) async => SeerrDiscoverPage(
        page: page,
        totalPages: 2,
        results: [_item(page * 10 + 1), _item(page * 10 + 2)],
      ),
    );

    await controller.load();
    expect(controller.state.items.map((item) => item.id), [11, 12]);
    expect(controller.state.currentPage, 1);
    expect(controller.state.canLoadMore, isTrue);

    await controller.loadMore();
    expect(controller.state.items.map((item) => item.id), [11, 12, 21, 22]);
    expect(controller.state.currentPage, 2);
    expect(controller.state.canLoadMore, isFalse);
    controller.dispose();
  });

  test('user refinements preserve immutable base lane constraints', () async {
    SeerrDiscoveryQuery? seenQuery;
    final controller = SeerrDiscoveryCollectionController(
      baseQuery: base,
      minimumMatchesPerLoad: 1,
      fetchPage: (query, page) async {
        seenQuery = query;
        return SeerrDiscoverPage(page: 1, totalPages: 1, results: [_item(1)]);
      },
    );

    await controller.setRefinements({
      'genre': '27',
      'voteAverageGte': '6.0',
      'withRuntimeLte': '100',
    });

    expect(seenQuery!.filters['voteAverageGte'], '7.0');
    expect(seenQuery!.filters['voteCountGte'], '150');
    expect(seenQuery!.filters['voteCountLte'], '1500');
    expect(seenQuery!.filters['genre'], '27');
    expect(seenQuery!.filters['withRuntimeLte'], '100');
    controller.dispose();
  });

  test(
    'sort override resets collection and uses current Seerr sort policy',
    () async {
      final seenSorts = <String>[];
      final controller = SeerrDiscoveryCollectionController(
        baseQuery: base,
        minimumMatchesPerLoad: 1,
        fetchPage: (query, page) async {
          seenSorts.add(query.sortBy);
          return SeerrDiscoverPage(
            page: 1,
            totalPages: 1,
            results: [_item(seenSorts.length)],
          );
        },
      );

      await controller.load();
      await controller.setSort('vote_count.desc');
      await controller.setSort('name.asc');

      expect(seenSorts, [
        'vote_average.desc',
        'vote_count.desc',
        'popularity.desc',
      ]);
      controller.dispose();
    },
  );

  test('stale initial load cannot overwrite a newer refined load', () async {
    final first = Completer<SeerrDiscoverPage>();
    var calls = 0;
    final controller = SeerrDiscoveryCollectionController(
      baseQuery: base,
      minimumMatchesPerLoad: 1,
      fetchPage: (query, page) async {
        calls++;
        if (calls == 1) return first.future;
        return SeerrDiscoverPage(page: 1, totalPages: 1, results: [_item(200)]);
      },
    );

    final oldLoad = controller.load();
    final newLoad = controller.setRefinements({'genre': '27'});
    await newLoad;
    first.complete(
      SeerrDiscoverPage(page: 1, totalPages: 1, results: [_item(100)]),
    );
    await oldLoad;

    expect(controller.state.items.single.id, 200);
    expect(controller.state.query.filters['genre'], '27');
    controller.dispose();
  });

  test('load more error preserves already loaded results', () async {
    var calls = 0;
    final controller = SeerrDiscoveryCollectionController(
      baseQuery: base,
      minimumMatchesPerLoad: 1,
      fetchPage: (_, page) async {
        calls++;
        if (calls == 2) throw StateError('page failed');
        return SeerrDiscoverPage(page: 1, totalPages: 2, results: [_item(1)]);
      },
    );

    await controller.load();
    await controller.loadMore();
    expect(controller.state.items.single.id, 1);
    expect(controller.state.error, contains('page failed'));
    controller.dispose();
  });
}
