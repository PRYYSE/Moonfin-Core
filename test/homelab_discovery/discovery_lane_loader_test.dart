import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/models/aggregated_item.dart';
import 'package:moonfin/data/models/home_row.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_personalisation.dart';

HomeLabDiscoverySection section({int minItems = 2}) => HomeLabDiscoverySection(
  id: 'lane',
  title: 'Lane',
  minItems: minItems,
  previewLimit: 4,
  dedupGroup: 'lane',
  query: const HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
);

HomeLabDiscoverySection personalSection(String strategy) =>
    HomeLabDiscoverySection(
      id: 'personal-$strategy',
      title: 'Personal',
      minItems: 2,
      previewLimit: 4,
      dedupGroup: 'personal',
      query: HomeLabDiscoveryQuery(
        source: HomeLabDiscoverySource.personalised,
        mediaType: 'movie',
        seedStrategy: strategy,
      ),
    );

AggregatedItem personalItem(int id, int tmdb, String title) => AggregatedItem(
  id: '$id',
  serverId: 'server-1',
  rawData: {
    'Name': title,
    'Type': 'Movie',
    'ProviderIds': {'Tmdb': '$tmdb'},
  },
);

void main() {
  test('one lane error is isolated into its result', () async {
    final loader = HomeLabDiscoveryLaneLoader(
      fetchPage: (_, _) async => throw StateError('boom'),
    );

    final result = await loader.load(section());
    expect(result.hasError, isTrue);
    expect(result.items, isEmpty);
  });

  test('lane load preserves raw preview order for post-fetch policy', () async {
    final loader = HomeLabDiscoveryLaneLoader(
      fetchPage: (_, _) async => const SeerrDiscoverPage(
        page: 1,
        totalPages: 1,
        results: [
          SeerrDiscoverItem(id: 1, mediaType: 'movie'),
          SeerrDiscoverItem(id: 2, mediaType: 'movie'),
          SeerrDiscoverItem(id: 3, mediaType: 'movie'),
        ],
      ),
    );

    final result = await loader.load(section());
    expect(result.hasError, isFalse);
    expect(result.items.map((item) => item.id), [1, 2, 3]);
  });

  test(
    'sparse successful lane is hidden rather than treated as error',
    () async {
      final loader = HomeLabDiscoveryLaneLoader(
        fetchPage: (_, _) async => const SeerrDiscoverPage(
          page: 1,
          totalPages: 1,
          results: [SeerrDiscoverItem(id: 1, mediaType: 'movie')],
        ),
      );

      final result = await loader.load(section(minItems: 2));
      expect(result.hasError, isFalse);
      expect(result.shouldHide, isTrue);
    },
  );

  test('unsupported personal semantics hide without running a fake row', () async {
    var loadRowCalls = 0;
    final personalisation = HomeLabDiscoveryPersonalisation.forTesting(
      serverId: 'server-1',
      loadRow: (_, slot) async {
        loadRowCalls++;
        return HomeRow(
          id: 'sinceYouWatched$slot',
          title: 'Should not load',
          rowType: HomeRowType.latestMedia,
          items: [personalItem(1, 101, 'Wrong source')],
          totalCount: 1,
        );
      },
      loadMore: ({required row, required serverId, offset}) async =>
          (row.items, row.totalCount),
    );
    final loader = HomeLabDiscoveryLaneLoader(
      personalisation: personalisation,
      fetchPage: (_, _) async => throw StateError('raw bridge should not run'),
    );

    final result = await loader.load(personalSection('watchlist'));

    expect(result.hasError, isFalse);
    expect(result.shouldHide, isTrue);
    expect(result.items, isEmpty);
    expect(loadRowCalls, 0);
    await expectLater(
      loader.loadPage(personalSection('watchlist')),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test(
    'supported personalised lane keeps authored semantics and raw order',
    () async {
      final personalisation = HomeLabDiscoveryPersonalisation.forTesting(
        serverId: 'server-1',
        loadRow: (_, slot) async => HomeRow(
          id: 'sinceYouWatched$slot',
          title: 'Unrelated upstream seed title',
          rowType: HomeRowType.latestMedia,
          items: [
            personalItem(1, 101, 'Demon Slayer: Kimetsu no Yaiba'),
            personalItem(2, 102, 'Demon Slayer: Mugen Train'),
            personalItem(3, 103, 'Demon Slayer: Entertainment District'),
            personalItem(4, 104, 'Pluto'),
          ],
          totalCount: 4,
        ),
        loadMore: ({required row, required serverId, offset}) async =>
            (row.items, row.totalCount),
      );
      final loader = HomeLabDiscoveryLaneLoader(
        personalisation: personalisation,
        fetchPage: (_, _) async =>
            throw StateError('raw bridge should not run'),
      );

      final result = await loader.load(personalSection('movie-affinity'));

      expect(result.hasError, isFalse);
      expect(result.displayTitle, 'Personal');
      expect(result.items.map((item) => item.id), [101, 102, 103, 104]);
    },
  );

  test(
    'deep personalised page honours requested page and force refresh',
    () async {
      var loadRowCalls = 0;
      final personalisation = HomeLabDiscoveryPersonalisation.forTesting(
        serverId: 'server-1',
        loadRow: (_, slot) async {
          loadRowCalls++;
          return HomeRow(
            id: 'sinceYouWatched$slot',
            title: 'Unrelated upstream seed title',
            rowType: HomeRowType.latestMedia,
            items: List.generate(
              35,
              (index) => personalItem(index, 1000 + index, 'Item $index'),
            ),
            totalCount: 35,
          );
        },
        loadMore: ({required row, required serverId, offset}) async =>
            (row.items, row.totalCount),
      );
      final loader = HomeLabDiscoveryLaneLoader(
        personalisation: personalisation,
        fetchPage: (_, _) async =>
            throw StateError('raw bridge should not run'),
      );
      final personal = personalSection('movie-affinity');

      final second = await loader.loadPage(personal, page: 2);
      expect(second.displayTitle, 'Personal');
      expect(second.page, 2);
      expect(second.items.length, 15);
      expect(second.items.first.id, 1015);
      expect(loadRowCalls, 1);

      final refreshed = await loader.loadPage(
        personal,
        page: 1,
        forceRefresh: true,
      );
      expect(refreshed.page, 1);
      expect(loadRowCalls, 2);
    },
  );
}
