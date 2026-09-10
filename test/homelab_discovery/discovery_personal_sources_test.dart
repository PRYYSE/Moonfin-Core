import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/models/aggregated_item.dart';
import 'package:moonfin/data/models/home_row.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_personal_sources.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_personalisation.dart';

AggregatedItem sourceItem(
  int tmdb, {
  String type = 'Movie',
  String serverId = 'server-1',
  bool anime = false,
  String? jellyfinMediaId,
}) => AggregatedItem(
  id: serverId == 'seerr' ? '$tmdb' : 'local-$tmdb',
  serverId: serverId,
  rawData: {
    'Name': 'Item $tmdb',
    'Type': type,
    'ProviderIds': {'Tmdb': '$tmdb'},
    if (anime) 'Tags': ['anime'],
    if (anime) 'GenreIds': [16],
    if (anime) 'OriginalLanguage': 'ja',
    if (serverId == 'seerr') 'SeerrStatus': 5,
    'JellyfinMediaId': ?jellyfinMediaId,
  },
);

AggregatedItem japaneseAnimationItem(int tmdb) => AggregatedItem(
  id: 'local-$tmdb',
  serverId: 'server-1',
  rawData: {
    'Name': 'Item $tmdb',
    'Type': 'Series',
    'ProviderIds': {'Tmdb': '$tmdb'},
    'Genres': ['Animation'],
    'OriginalLanguage': 'ja',
  },
);

HomeLabDiscoverySection personal(String strategy, {String mediaType = 'all'}) =>
    HomeLabDiscoverySection(
      id: 'source-$strategy-$mediaType',
      title: 'Source $strategy',
      minItems: 1,
      query: HomeLabDiscoveryQuery(
        source: HomeLabDiscoverySource.personalised,
        mediaType: mediaType,
        seedStrategy: strategy,
      ),
    );

void main() {
  test('maps only proven source families', () {
    final expected = {
      'recent-history': HomeLabDiscoveryPersonalSourceKind.recentHistory,
      'favourites': HomeLabDiscoveryPersonalSourceKind.favourites,
      'watchlist': HomeLabDiscoveryPersonalSourceKind.watchlist,
      'high-ratings': HomeLabDiscoveryPersonalSourceKind.highRatings,
      'likes': HomeLabDiscoveryPersonalSourceKind.likes,
      'mixed-positive': HomeLabDiscoveryPersonalSourceKind.mixedPositive,
      'novelty': HomeLabDiscoveryPersonalSourceKind.random,
      'something-completely-different':
          HomeLabDiscoveryPersonalSourceKind.random,
      'rewatch': HomeLabDiscoveryPersonalSourceKind.rewatchPositive,
      'comfort-rewatch-candidates':
          HomeLabDiscoveryPersonalSourceKind.rewatchPositive,
      'anime-recent-history': HomeLabDiscoveryPersonalSourceKind.recentHistory,
      'anime-favourites': HomeLabDiscoveryPersonalSourceKind.favourites,
      'anime-watchlist': HomeLabDiscoveryPersonalSourceKind.watchlist,
      'anime-high-ratings': HomeLabDiscoveryPersonalSourceKind.highRatings,
      'anime-novelty': HomeLabDiscoveryPersonalSourceKind.random,
      'anime-something-different': HomeLabDiscoveryPersonalSourceKind.random,
      'recently-added': HomeLabDiscoveryPersonalSourceKind.recentlyAdded,
      'trending-anime': HomeLabDiscoveryPersonalSourceKind.trendingAnime,
    };

    for (final entry in expected.entries) {
      final policy = homeLabDiscoveryPersonalSourcePolicy(personal(entry.key));
      expect(policy?.kind, entry.value, reason: entry.key);
    }

    expect(
      homeLabDiscoveryPersonalSourcePolicy(personal('novelty'))?.mode,
      HomeLabDiscoveryPersonalSourceMode.recommendations,
    );
    expect(
      homeLabDiscoveryPersonalSourcePolicy(personal('rewatch'))?.mode,
      HomeLabDiscoveryPersonalSourceMode.direct,
    );
    expect(
      homeLabDiscoveryPersonalSourcePolicy(
        personal('anime-novelty'),
      )?.animeOnly,
      isTrue,
    );

    for (final strategy in [
      'recent-discovery-context',
      'limited-series',
      'one-season-wonders',
      'anime-specials',
      'anime-completed',
    ]) {
      expect(
        homeLabDiscoveryPersonalSourcePolicy(personal(strategy)),
        isNull,
        reason: strategy,
      );
    }
  });

  test('bounds and dedupes recommendation transport', () async {
    final seeds = <int>[];
    final service = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (_) async => [
        sourceItem(10),
        sourceItem(11),
        sourceItem(12),
        sourceItem(13),
      ],
      loadRecommendations: (seed) async {
        seeds.add(int.parse(seed.tmdbId!));
        return [
          sourceItem(10, serverId: 'seerr'),
          sourceItem(100, serverId: 'seerr'),
          sourceItem(200 + seeds.length, serverId: 'seerr'),
        ];
      },
    );

    final result = await service.load(personal('recent-history'));
    expect(seeds.length, 2);
    expect(result.items.map((item) => item.tmdbId), isNot(contains('10')));
    expect(result.items.where((item) => item.tmdbId == '100').length, 1);
    expect(result.totalResults, result.items.length);

    await service.load(personal('recent-history'));
    expect(seeds.length, 2);
  });

  test(
    'novelty uses the bounded random source as recommendation seeds',
    () async {
      HomeLabDiscoveryPersonalSourceKind? loadedKind;
      var recommendationCalls = 0;
      final service = HomeLabDiscoveryPersonalSources.forTesting(
        serverId: 'server-1',
        loadPool: (kind) async {
          loadedKind = kind;
          return [sourceItem(501), sourceItem(502)];
        },
        loadRecommendations: (_) async {
          recommendationCalls++;
          return [sourceItem(900 + recommendationCalls, serverId: 'seerr')];
        },
      );

      final result = await service.load(
        personal('novelty', mediaType: 'movie'),
      );
      expect(loadedKind, HomeLabDiscoveryPersonalSourceKind.random);
      expect(recommendationCalls, 2);
      expect(result.items.map((item) => item.tmdbId), ['901', '902']);
    },
  );

  test(
    'rewatch is a direct positive source and skips recommendation transport',
    () async {
      HomeLabDiscoveryPersonalSourceKind? loadedKind;
      var calls = 0;
      final service = HomeLabDiscoveryPersonalSources.forTesting(
        serverId: 'server-1',
        loadPool: (kind) async {
          loadedKind = kind;
          return [sourceItem(501), sourceItem(502)];
        },
        loadRecommendations: (_) async {
          calls++;
          return const [];
        },
      );

      final result = await service.load(
        personal('rewatch', mediaType: 'movie'),
      );
      expect(loadedKind, HomeLabDiscoveryPersonalSourceKind.rewatchPositive);
      expect(result.items.map((item) => item.tmdbId), ['501', '502']);
      expect(calls, 0);
    },
  );

  test('direct source skips recommendation transport', () async {
    var calls = 0;
    final service = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (_) async => [sourceItem(501), sourceItem(502)],
      loadRecommendations: (_) async {
        calls++;
        return const [];
      },
    );

    final result = await service.load(
      personal('recently-added', mediaType: 'movie'),
    );
    expect(result.items.map((item) => item.tmdbId), ['501', '502']);
    expect(calls, 0);
  });

  test('anime source remains anime only', () async {
    var calls = 0;
    final service = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (_) async => [
        sourceItem(601, type: 'Series', anime: true),
        sourceItem(602, type: 'Series'),
      ],
      loadRecommendations: (_) async {
        calls++;
        return [
          sourceItem(701, type: 'Series', serverId: 'seerr', anime: true),
          sourceItem(702, type: 'Series', serverId: 'seerr'),
        ];
      },
    );

    final result = await service.load(
      personal('anime-favourites', mediaType: 'tv'),
    );
    expect(calls, 1);
    expect(result.items.map((item) => item.tmdbId), ['701']);
  });

  test(
    'anime novelty accepts Japanese animation and uses a truthful label',
    () async {
      var genericLoads = 0;
      final sources = HomeLabDiscoveryPersonalSources.forTesting(
        serverId: 'server-1',
        loadPool: (kind) async {
          expect(kind, HomeLabDiscoveryPersonalSourceKind.random);
          return [japaneseAnimationItem(801), sourceItem(802, type: 'Series')];
        },
        loadRecommendations: (_) async => [
          sourceItem(901, type: 'Series', serverId: 'seerr', anime: true),
          sourceItem(902, type: 'Series', serverId: 'seerr'),
        ],
      );
      final service = HomeLabDiscoveryPersonalisation.forTesting(
        serverId: 'server-1',
        loadRow: (_, slot) async {
          genericLoads++;
          return HomeRow(
            id: 'unused-$slot',
            title: 'Unused',
            rowType: HomeRowType.latestMedia,
          );
        },
        loadMore: ({required row, required serverId, offset}) async =>
            (row.items, row.totalCount),
        personalSources: sources,
      );

      final result = await service.load(
        personal('anime-novelty', mediaType: 'tv'),
      );
      expect(genericLoads, 0);
      expect(result.title, 'Something Different in Anime');
      expect(result.page.results.map((item) => item.id), [901]);
    },
  );

  test('force refresh clears source snapshots', () async {
    var poolLoads = 0;
    var recommendationLoads = 0;
    final service = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (_) async {
        poolLoads++;
        return [sourceItem(801)];
      },
      loadRecommendations: (_) async {
        recommendationLoads++;
        return [sourceItem(901, serverId: 'seerr')];
      },
    );
    final candidate = personal('likes');

    await service.load(candidate);
    await service.load(candidate);
    expect(poolLoads, 1);
    expect(recommendationLoads, 1);

    await service.load(candidate, forceRefresh: true);
    expect(poolLoads, 2);
    expect(recommendationLoads, 2);
  });

  test('personalisation uses source without generic row IO', () async {
    var genericLoads = 0;
    final sources = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (_) async => [sourceItem(1)],
      loadRecommendations: (_) async => [
        sourceItem(601, serverId: 'seerr', jellyfinMediaId: 'real-jellyfin-id'),
      ],
    );
    final service = HomeLabDiscoveryPersonalisation.forTesting(
      serverId: 'server-1',
      loadRow: (_, slot) async {
        genericLoads++;
        return HomeRow(
          id: 'unused-$slot',
          title: 'Unused',
          rowType: HomeRowType.latestMedia,
        );
      },
      loadMore: ({required row, required serverId, offset}) async =>
          (row.items, row.totalCount),
      personalSources: sources,
    );

    final result = await service.load(personal('favourites'));
    expect(genericLoads, 0);
    expect(result.page.results.single.id, 601);
    expect(
      result.page.results.single.mediaInfo?.jellyfinMediaId,
      'real-jellyfin-id',
    );
  });
}
