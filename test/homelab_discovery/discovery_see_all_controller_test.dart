import 'dart:async';

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
  test(
    'initial deep load reads ahead across membership-filtered empty page',
    () async {
      final requested = <int>[];
      final controller = HomeLabDiscoverySeeAllController(
        section: section,
        loadPage: (_, {page = 1, forceRefresh = false}) async {
          requested.add(page);
          return page == 1
              ? pageResult(page, const [])
              : pageResult(page, [1, 2]);
        },
      );

      final state = await controller.loadInitial();

      expect(requested, [1, 2]);
      expect(state.throughPage, 2);
      expect(state.items.map((value) => value.id), [1, 2]);
    },
  );

  test(
    'deep paging deduplicates exact media without preview diversification',
    () async {
      final controller = HomeLabDiscoverySeeAllController(
        section: section,
        maxEmptyPageReadAhead: 1,
        loadPage: (_, {page = 1, forceRefresh = false}) async => switch (page) {
          1 => pageResult(1, [1, 2], totalPages: 2),
          2 => pageResult(2, [2, 3], totalPages: 2),
          _ => pageResult(page, const [], totalPages: 2),
        },
      );

      await controller.loadInitial();
      final state = await controller.loadMore();

      expect(state.items.map((value) => value.id), [1, 2, 3]);
      expect(state.throughPage, 2);
      expect(state.hasMore, isFalse);
    },
  );

  test('duplicate near-end paging joins one in-flight page request', () async {
    var secondPageRequests = 0;
    final secondPage = Completer<HomeLabDiscoveryPageLoadResult>();
    final controller = HomeLabDiscoverySeeAllController(
      section: section,
      maxEmptyPageReadAhead: 1,
      loadPage: (_, {page = 1, forceRefresh = false}) {
        if (page == 1) {
          return Future.value(pageResult(1, [1], totalPages: 2));
        }
        secondPageRequests++;
        return secondPage.future;
      },
    );

    await controller.loadInitial();
    final first = controller.loadMore();
    final duplicate = controller.loadMore();
    await Future<void>.delayed(Duration.zero);

    expect(secondPageRequests, 1);

    secondPage.complete(pageResult(2, [2], totalPages: 2));
    final firstState = await first;
    final duplicateState = await duplicate;

    expect(secondPageRequests, 1);
    expect(firstState.items.map((value) => value.id), [1, 2]);
    expect(duplicateState.items.map((value) => value.id), [1, 2]);
    expect(firstState.throughPage, 2);
    expect(duplicateState.throughPage, 2);
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

  test(
    'refresh resets accumulated pages and forces personal source refresh',
    () async {
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
    },
  );

  test(
    'refresh waits for in-flight paging before replacing deep state',
    () async {
      final calls = <(int, bool)>[];
      final secondPage = Completer<HomeLabDiscoveryPageLoadResult>();
      final refreshedFirstPage = Completer<HomeLabDiscoveryPageLoadResult>();
      var refreshRequested = false;
      final controller = HomeLabDiscoverySeeAllController(
        section: section,
        maxEmptyPageReadAhead: 1,
        loadPage: (_, {page = 1, forceRefresh = false}) {
          calls.add((page, forceRefresh));
          if (page == 2) return secondPage.future;
          if (forceRefresh) {
            refreshRequested = true;
            return refreshedFirstPage.future;
          }
          return Future.value(pageResult(1, [1], totalPages: 2));
        },
      );

      await controller.loadInitial();
      final more = controller.loadMore();
      await Future<void>.delayed(Duration.zero);
      expect(calls, [(1, false), (2, false)]);

      final refresh = controller.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(refreshRequested, isFalse);

      secondPage.complete(pageResult(2, [2], totalPages: 2));
      await more;
      await Future<void>.delayed(Duration.zero);

      expect(refreshRequested, isTrue);
      expect(calls, [(1, false), (2, false), (1, true)]);

      refreshedFirstPage.complete(pageResult(1, [9], totalPages: 2));
      final refreshed = await refresh;

      expect(refreshed.items.map((value) => value.id), [9]);
      expect(refreshed.throughPage, 1);
      expect(refreshed.hasError, isFalse);
    },
  );
}

HomeLabDiscoveryPageLoadResult pageResult(
  int number,
  List<int> ids, {
  int totalPages = 3,
}) => page(number, ids, totalPages: totalPages);
