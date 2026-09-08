import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/models/aggregated_item.dart';
import 'package:moonfin/data/models/home_row.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_personal_policy.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_personal_sources.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_personalisation.dart';

AggregatedItem media(
  int localId,
  int tmdb, {
  String type = 'Movie',
  String? name,
  String serverId = 'server-1',
  List<String> genres = const [],
  List<String> tags = const [],
  String? language,
  double? rating,
  bool played = false,
  int? runtimeMinutes,
  int? productionYear,
  int? seerrStatus,
  String? jellyfinMediaId,
}) {
  final raw = <String, dynamic>{
    'Name': name ?? 'Item $localId',
    'Type': type,
    'ProviderIds': {'Tmdb': '$tmdb'},
    'Genres': genres,
    'Tags': tags,
    'UserData': {'Played': played},
  };
  if (language != null) raw['OriginalLanguage'] = language;
  if (rating != null) raw['CommunityRating'] = rating;
  if (runtimeMinutes != null) {
    raw['RunTimeTicks'] = Duration(minutes: runtimeMinutes).inMicroseconds * 10;
  }
  if (productionYear != null) raw['ProductionYear'] = productionYear;
  if (seerrStatus != null) raw['SeerrStatus'] = seerrStatus;
  if (jellyfinMediaId != null) raw['JellyfinMediaId'] = jellyfinMediaId;
  return AggregatedItem(
    id: serverId == 'seerr' ? 'seerr-$tmdb' : '$localId',
    serverId: serverId,
    rawData: raw,
  );
}

HomeLabDiscoverySection section(
  String strategy, {
  String mediaType = 'all',
  List<String> tags = const [],
}) => HomeLabDiscoverySection(
  id: 'personal-$strategy',
  title: 'Personal $strategy',
  tags: tags,
  minItems: 1,
  query: HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.personalised,
    mediaType: mediaType,
    seedStrategy: strategy,
  ),
);

HomeLabDiscoveryPersonalisation serviceWith({
  required Future<HomeRow> Function(String serverId, int rowIndex) loadRow,
  HomeLabDiscoveryPersonalSources? personalSources,
}) => HomeLabDiscoveryPersonalisation.forTesting(
  serverId: 'server-1',
  loadRow: loadRow,
  loadMore: ({required row, required serverId, offset}) async =>
      (row.items, row.totalCount),
  personalSources: personalSources,
);

void main() {
  test('source-specific and structural labels fail closed without an adapter', () async {
    var loadCalls = 0;
    final service = serviceWith(
      loadRow: (_, slot) async {
        loadCalls++;
        return HomeRow(
          id: 'sinceYouWatched$slot',
          title: 'Since you watched Test',
          rowType: HomeRowType.latestMedia,
          items: [media(1, 101)],
          totalCount: 1,
        );
      },
    );

    for (final strategy in [
      'recent-history',
      'favourites',
      'watchlist',
      'high-ratings',
      'likes',
      'mixed-positive',
      'novelty',
      'rewatch',
      'recently-added',
      'trending-anime',
      'recent-discovery-context',
      'limited-series',
      'anime-completed',
    ]) {
      final candidate = section(strategy);
      expect(service.supports(candidate), isFalse, reason: strategy);
      await expectLater(
        service.load(candidate),
        throwsA(isA<UnsupportedError>()),
      );
    }

    expect(loadCalls, 0);
  });

  test('proven source adapter executes without generic row IO', () async {
    var genericLoads = 0;
    var sourceLoads = 0;
    final sources = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (kind) async {
        sourceLoads++;
        expect(kind, HomeLabDiscoveryPersonalSourceKind.favourites);
        return [media(1, 501)];
      },
      loadRecommendations: (seed) async => [
        media(2, 601, serverId: 'seerr', seerrStatus: 3),
      ],
    );
    final service = serviceWith(
      personalSources: sources,
      loadRow: (_, slot) async {
        genericLoads++;
        return HomeRow(
          id: 'sinceYouWatched$slot',
          title: 'Generic',
          rowType: HomeRowType.latestMedia,
        );
      },
    );

    final candidate = section('favourites');
    expect(service.supports(candidate), isTrue);
    final result = await service.load(candidate);
    expect(sourceLoads, 1);
    expect(genericLoads, 0);
    expect(result.title, candidate.title);
    expect(result.page.results.map((item) => item.id), [601]);
  });

  test(
    'generic affinity strategies use explicit fixed policies, not hashes',
    () async {
      final requestedSlots = <int>[];
      final service = serviceWith(
        loadRow: (_, slot) async {
          requestedSlots.add(slot);
          return HomeRow(
            id: 'sinceYouWatched$slot',
            title: 'Since you watched Test',
            rowType: HomeRowType.latestMedia,
            items: [
              media(
                slot,
                100 + slot,
                type: slot == 10 ? 'Series' : 'Movie',
                genres: slot == 11 ? ['Animation'] : const [],
                language: slot == 11 ? 'ja' : null,
              ),
            ],
            totalCount: 1,
          );
        },
      );

      expect(service.supports(section('movie-affinity')), isTrue);
      expect(service.supports(section('series-affinity')), isTrue);
      expect(service.supports(section('anime-affinity')), isTrue);

      await service.load(section('movie-affinity'));
      await service.load(section('series-affinity'));
      await service.load(section('anime-affinity'));

      expect(requestedSlots, [9, 10, 11]);
    },
  );

  test(
    'explicit result constraints provide the advertised generic semantics',
    () async {
      final service = serviceWith(
        loadRow: (_, slot) async => HomeRow(
          id: 'sinceYouWatched$slot',
          title: 'Unrelated upstream seed title',
          rowType: HomeRowType.latestMedia,
          items: [
            media(
              1,
              201,
              type: 'Series',
              genres: ['Animation', 'Action'],
              language: 'ja',
              rating: 8.5,
              runtimeMinutes: 24,
            ),
            media(
              2,
              202,
              type: 'Series',
              genres: ['Animation', 'Comedy'],
              language: 'ja',
              rating: 8.2,
              runtimeMinutes: 24,
            ),
            media(
              3,
              203,
              type: 'Series',
              genres: ['Animation', 'Action'],
              language: 'en',
              rating: 8.0,
              runtimeMinutes: 24,
            ),
          ],
          totalCount: 3,
        ),
      );

      final result = await service.load(
        section('anime-action-affinity', mediaType: 'tv', tags: ['anime']),
      );

      expect(result.page.results.map((item) => item.id), [201]);
      expect(result.title, 'Personal anime-action-affinity');
    },
  );

  test(
    'highly-rated unseen policy excludes low-rated and played items',
    () async {
      final service = serviceWith(
        loadRow: (_, slot) async => HomeRow(
          id: 'sinceYouWatched$slot',
          title: 'Recommended For You',
          rowType: HomeRowType.latestMedia,
          items: [
            media(1, 301, rating: 8.0),
            media(2, 302, rating: 6.9),
            media(3, 303, rating: 9.0, played: true),
          ],
          totalCount: 3,
        ),
      );

      final result = await service.load(section('highly-rated-unseen'));
      expect(result.page.results.map((item) => item.id), [301]);
    },
  );

  test(
    'external recommendation identity is not fabricated as local Jellyfin',
    () async {
      final service = serviceWith(
        loadRow: (_, slot) async => HomeRow(
          id: 'sinceYouWatched$slot',
          title: 'Recommended For You',
          rowType: HomeRowType.latestMedia,
          items: [
            media(1, 401, serverId: 'seerr', rating: 8.0, seerrStatus: 3),
            media(2, 402, rating: 8.0),
          ],
          totalCount: 2,
        ),
      );

      final result = await service.load(section('highly-rated-unseen'));
      expect(result.page.results.length, 2);

      final external = result.page.results.first;
      expect(external.id, 401);
      expect(external.mediaInfo?.status, 3);
      expect(external.mediaInfo?.jellyfinMediaId, isNull);

      final local = result.page.results.last;
      expect(local.id, 402);
      expect(local.mediaInfo?.status, 5);
      expect(local.mediaInfo?.jellyfinMediaId, '2');
    },
  );

  test('explicit external Jellyfin identity is preserved, never invented', () async {
    final sources = HomeLabDiscoveryPersonalSources.forTesting(
      serverId: 'server-1',
      loadPool: (_) async => [media(1, 701)],
      loadRecommendations: (_) async => [
        media(
          2,
          702,
          serverId: 'seerr',
          seerrStatus: 5,
          jellyfinMediaId: 'real-jellyfin-id',
        ),
      ],
    );
    final service = serviceWith(
      personalSources: sources,
      loadRow: (_, slot) async => HomeRow(
        id: 'sinceYouWatched$slot',
        title: 'Unused',
        rowType: HomeRowType.latestMedia,
      ),
    );

    final result = await service.load(section('recent-history'));
    expect(result.page.results.single.mediaInfo?.jellyfinMediaId, 'real-jellyfin-id');
  });

  test('items without a real TMDB id are omitted from results and totals', () async {
    final bad = AggregatedItem(
      id: 'local',
      serverId: 'server-1',
      rawData: const {'Name': 'Local only', 'Type': 'Movie'},
    );
    final service = serviceWith(
      loadRow: (_, slot) async => HomeRow(
        id: 'sinceYouWatched$slot',
        title: 'Recommended For You',
        rowType: HomeRowType.latestMedia,
        items: [bad, media(2, 802)],
        totalCount: 2,
      ),
    );

    final result = await service.load(section('movie-affinity'));
    expect(result.page.results.map((item) => item.id), [802]);
    expect(result.page.totalResults, 1);
    expect(result.page.totalPages, 1);
  });
}
