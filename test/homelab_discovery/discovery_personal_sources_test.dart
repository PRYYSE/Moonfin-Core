import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/models/aggregated_item.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_personal_sources.dart';

AggregatedItem sourceItem(
  int tmdb, {
  String type = 'Movie',
  String serverId = 'server-1',
  List<String> genres = const [],
  List<String> tags = const [],
  String? language,
}) => AggregatedItem(
  id: serverId == 'seerr' ? '$tmdb' : 'local-$tmdb',
  serverId: serverId,
  rawData: {
    'Name': 'Item $tmdb',
    'Type': type,
    'ProviderIds': {'Tmdb': '$tmdb'},
    'Genres': genres,
    'Tags': tags,
    if (language != null) 'OriginalLanguage': language,
    if (serverId == 'seerr') 'GenreIds': genres.contains('anime') ? [16] : [],
  },
);

HomeLabDiscoverySection sourceSection(
  String strategy, {
  String mediaType = 'all',
  List<String> tags = const [],
}) => HomeLabDiscoverySection(
  id: 'source-$strategy-$mediaType',
  title: 'Source $strategy',
  tags: tags,
  minItems: 1,
  query: HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.personalised,
    mediaType: mediaType,
    seedStrategy: strategy,
  ),
);

void main() {
  test('source policy exposes only proven provenance families', () {
    final expected = {
      'recent-history': HomeLabDiscoveryPersonalSourceKind.recentHistory,
      'favourites': HomeLabDiscoveryPersonalSourceKind.favourites,
      'watchlist': HomeLabDiscoveryPersonalSourceKind.watchlist,
      'high-ratings': HomeLabDiscoveryPersonalSourceKind.highRatings,
      'likes': HomeLabDiscoveryPersonalSourceKind.likes,
      'mixed-positive': HomeLabDiscoveryPersonalSourceKind.mixedPositive,
      'anime-recent-history': HomeLabDiscoveryPersonalSourceKind.recentHistory,
      'anime-favourites': HomeLabDiscoveryPersonalSourceKind.favourites,
      'anime-watchlist': HomeLabDiscoveryPersonalSourceKind.watchlist,
      'anime-high-ratings': HomeLabDiscoveryPersonalSourceKind.highRatings,
      'recently-added': HomeLabDiscoveryPersonalSourceKind.recentlyAdded,
      'trending-anime': HomeLabDiscoveryPersonalSourceKind.trendingAnime,
    };

    for (final entry in expected.entries) {
      expect(
        homeLabDiscoveryPersonalSourcePolicy(sourceSection(entry.key))?.kind,
        entry.value,
        reason: entry.key,
      );
    }

    for (final unsupported in [
      'novelty',
      'rewatch',
      'recent-discovery-context',
      'limited-series',
      'one-season-wonders',
      'anime-specials',
      'anime-completed',
      'anime-novelty',
    ]) {
      expect(
        homeLabDiscoveryPersonalSourcePolicy(sourceSection(unsupported)),
        isNull,
        reason: unsupported,
      );
    }
  });

  test('recommendation source is bounded, deduped and excludes source seeds', () async {
    final recommendationSeeds = <int>[];
    final service = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (kind) async => [
        sourceItem(10),
        sourceItem(11),
        sourceItem(12),
        sourceItem(13),
      ],
      loadRecommendations: (seed) async {
        recommendationSeeds.add(int.parse(seed.tmdbId!));
        return [
          sourceItem(10, serverId: 'seerr'),
          sourceItem(100, serverId: 'seerr'),
          sourceItem(200 + recommendationSeeds.length, serverId: 'seerr'),
        ];
      },
    );

    final result = await service.load(sourceSection('recent-history'));
    expect(recommendationSeeds.length, 2);
    expect(result.items.map((item) => item.tmdbId), isNot(contains('10')));
    expect(result.items.where((item) => item.tmdbId == '100').length, 1);
    expect(result.totalResults, result.items.length);
    expect(result.totalPages, 1);

    await service.load(sourceSection('recent-history'));
    expect(recommendationSeeds.length, 2, reason: 'section snapshot is cached');
  });

  test('seed selection is deterministic within the truthful source pool', () async {
    Future<List<int>> selected() async {
      final calls = <int>[];
      final service = HomeLabDiscoveryPersonalSources.forTesting(
        serverId: 'server-1',
        loadPool: (_) async => [
          sourceItem(1),
          sourceItem(2),
          sourceItem(3),
          sourceItem(4),
        ],
        loadRecommendations: (seed) async {
          calls.add(int.parse(seed.tmdbId!));
          return [sourceItem(100 + calls.length, serverId: 'seerr')];
        },
      );
      await service.load(sourceSection('favourites'));
      return calls;
    }

    expect(await selected(), await selected());
  });

  test('direct source does not invoke recommendation transport', () async {
    var recommendationCalls = 0;
    final service = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (kind) async => [sourceItem(501), sourceItem(502)],
      loadRecommendations: (seed) async {
        recommendationCalls++;
        return const [];
      },
    );

    final result = await service.load(
      sourceSection('recently-added', mediaType: 'movie'),
    );
    expect(result.items.map((item) => item.tmdbId), ['501', '502']);
    expect(recommendationCalls, 0);
  });

  test('anime provenance and recommendation results stay anime-only', () async {
    var recommendationCalls = 0;
    final service = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (_) async => [
        sourceItem(601, type: 'Series', genres: ['anime']),
        sourceItem(602, type: 'Series', genres: ['Drama']),
      ],
      loadRecommendations: (seed) async {
        recommendationCalls++;
        return [
          sourceItem(
            701,
            type: 'Series',
            serverId: 'seerr',
            genres: ['anime'],
            language: 'ja',
          ),
          sourceItem(
            702,
            type: 'Series',
            serverId: 'seerr',
            genres: ['Drama'],
            language: 'en',
          ),
        ];
      },
    );

    final result = await service.load(
      sourceSection('anime-favourites', mediaType: 'tv', tags: ['anime']),
    );
    expect(recommendationCalls, 1);
    expect(result.items.map((item) => item.tmdbId), ['701']);
  });

  test('force refresh invalidates source and recommendation snapshots', () async {
    var poolLoads = 0;
    var recommendationLoads = 0;
    final service = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (_) async {
        poolLoads++;
        return [sourceItem(801)];
      },
      loadRecommendations: (seed) async {
        recommendationLoads++;
        return [sourceItem(901, serverId: 'seerr')];
      },
    );
    final candidate = sourceSection('likes');

    await service.load(candidate);
    await service.load(candidate);
    expect((poolLoads, recommendationLoads), (1, 1));

    await service.load(candidate, forceRefresh: true);
    expect((poolLoads, recommendationLoads), (2, 2));
  });
}
