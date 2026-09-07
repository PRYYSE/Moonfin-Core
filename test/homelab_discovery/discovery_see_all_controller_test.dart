import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_see_all_controller.dart';

final section = HomeLabDiscoverySection(
  id: 'deep',
  title: 'Deep Picks',
  minItems: 1,
  query: const HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
);

SeerrDiscoverItem item(int id) =>
    SeerrDiscoverItem(id: id, mediaType: 'movie', title: 'Item $id');

HomeLabDiscoveryPageLoadResult page(
  int number,
  List<int> ids, {
  int totalPages = 3,
  String? title,
}) => HomeLabDiscoveryPageLoadResult(
  section: section,
  displayTitle: title,
  items: ids.map(item).toList(growable: false),
  page: number,
  totalPages: totalPages,
  totalResults: 60,
);

void main() {
  test('initial deep load reads ahead across membership-filtered empty page', () async {
    final requested = <int>[];
    final controller = HomeLabDiscoverySeeAllController(
      section: section,
      loadPage: (_, {page = 1, forceRefresh = false}) async {
        requested.add(page);
        return page == 1 ? pageResult(page, const []) : pageResult(page, [1, 2]);
      },
    );

    final state = await controller.loadInitial();

    expect(requested, [1, 2]);
    expect(state.throughPage, 2);
    expect(state.items.map((value) => value.id), [1, 2]);
  });

  test('deep paging deduplicates exact media without preview diversification', () async {
    final controller = HomeLabDiscoverySeeAllController(
      section: section,
      maxEmptyPageReadAhead: 1,
      loadPage: (_, {page = 1, forceRefresh = false}) async => switch (page) {
        1 => pageResult(1, [1, 2]),
        2 => pageResult(2, [2, 3]),
        _ => pageResult(page, const [], totalPages: 2),
      },
    );

    await controller.loadInitial();
    final state = await controller.loadMore();

    expect(state.items.map((value) => value.id), [1, 2, 3]);
    expect(state.throughPage, 2);
    expect(state.hasMore, isFalse);
  });

  test('load-more failure preserves items and retries the same page', () async {
    var secondPageAttempts = 0;
    final controller = HomeLabDiscoverySeeAllController(
      section: section,
      maxEmptyPageReadAhead: 1,
      loadPage: (_, {page = 1, forceRefresh = false}) async {
        if (page == 1) return pageResult(1, [1, 2]);
        secondPageAttempts++;
        if (secondPageAttempts == 1) throw StateError('temporary');
        return pageResult(2, [3], totalPages: 2);
      },
    );

    await controller.loadInitial();
    final failed = await controller.loadMore();
    expect(failed.hasError, isTrue);
    expect(failed.throughPage, 1);
    expect(failed.items.map((value) => value.id), [1, 2]);

    final retried = await controller.retry();
    expect(secondPageAttempts, 2);
    expect(retried.hasError, isFalse);
    expect(retried.throughPage, 2);
    expect(retried.items.map((value) => value.id), [1, 2, 3]);
  });

  test('refresh resets accumulated pages and forces personal source refresh', () async {
    final calls = <(int, bool)>[];
    final controller = HomeLabDiscoverySeeAllController(
      section: section,
      maxEmptyPageReadAhead: 1,
      loadPage: (_, {page = 1, forceRefresh = false}) async {
        calls.add((page, forceRefresh));
        return pageResult(page, [forceRefresh ? 9 : page]);
      },
    );

    await controller.loadInitial();
    await controller.loadMore();
    final refreshed = await controller.refresh();

    expect(calls, [(1, false), (2, false), (1, true)]);
    expect(refreshed.items.map((value) => value.id), [9]);
    expect(refreshed.throughPage, 1);
  });
}

HomeLabDiscoveryPageLoadResult pageResult(
  int number,
  List<int> ids, {
  int totalPages = 3,
}) => page(number, ids, totalPages: totalPages);
