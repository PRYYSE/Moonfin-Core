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

  test(
    'personalised lane uses stock adapter without race-order presentation',
    () async {
      final personalisation = HomeLabDiscoveryPersonalisation.forTesting(
        serverId: 'server-1',
        loadRow: (_, slot) async => HomeRow(
          id: 'sinceYouWatched$slot',
          title: 'Top Picks For You',
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

      final result = await loader.load(personalSection('favourites'));

      expect(result.hasError, isFalse);
      expect(result.displayTitle, 'Top Picks For You');
      expect(result.items.map((item) => item.id), [101, 102, 103, 104]);
    },
  );
}
