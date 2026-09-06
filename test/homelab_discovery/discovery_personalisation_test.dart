import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/models/aggregated_item.dart';
import 'package:moonfin/data/models/home_row.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_personalisation.dart';

AggregatedItem media(
  int localId,
  int tmdb, {
  String type = 'Movie',
  String? name,
  List<String> genres = const [],
  List<String> tags = const [],
  String? language,
}) {
  final raw = <String, dynamic>{
    'Name': name ?? 'Item $localId',
    'Type': type,
    'ProviderIds': {'Tmdb': '$tmdb'},
    'Genres': genres,
    'Tags': tags,
  };
  if (language != null) raw['OriginalLanguage'] = language;
  return AggregatedItem(id: '$localId', serverId: 'server-1', rawData: raw);
}

HomeLabDiscoverySection section(
  String strategy, {
  String mediaType = 'all',
  List<String> tags = const [],
}) => HomeLabDiscoverySection(
  id: 'personal-$strategy',
  title: 'Personal $strategy',
  tags: tags,
  query: HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.personalised,
    mediaType: mediaType,
    seedStrategy: strategy,
  ),
);

void main() {
  test('known strategies keep stable 1..16 recommendation slots', () async {
    var requestedSlot = 0;
    final service = HomeLabDiscoveryPersonalisation.forTesting(
      serverId: 'server-1',
      loadRow: (_, slot) async {
        requestedSlot = slot;
        return HomeRow(
          id: 'sinceYouWatched$slot',
          title: 'Since you watched Test',
          rowType: HomeRowType.latestMedia,
          items: [media(1, 101)],
          totalCount: 1,
        );
      },
      loadMore: ({required row, required serverId, offset}) async =>
          (row.items, row.totalCount),
    );

    await service.load(section('watchlist'));
    expect(requestedSlot, 3);
    service.clear();
    await service.load(section('recent-discovery-context'));
    expect(requestedSlot, 16);
  });

  test('expands scored cache before media filtering and pagination', () async {
    final first = [
      media(1, 101, type: 'Series'),
      media(2, 102, type: 'Series'),
    ];
    final all = [...first, media(3, 103), media(4, 104), media(5, 105)];
    var loadMoreCalls = 0;
    final service = HomeLabDiscoveryPersonalisation.forTesting(
      serverId: 'server-1',
      loadRow: (_, slot) async => HomeRow(
        id: 'sinceYouWatched$slot',
        title: 'Since you watched Example',
        rowType: HomeRowType.latestMedia,
        items: first,
        totalCount: all.length,
      ),
      loadMore: ({required row, required serverId, offset}) async {
        loadMoreCalls++;
        return (all, all.length);
      },
    );

    final result = await service.load(
      section('movie-affinity', mediaType: 'movie'),
    );
    expect(loadMoreCalls, 1);
    expect(result.page.results.map((item) => item.id), [103, 104, 105]);
    expect(result.page.totalResults, 3);
    expect(result.title, 'Since you watched Example');
  });

  test('anime filtering is conservative and metadata based', () async {
    final service = HomeLabDiscoveryPersonalisation.forTesting(
      serverId: 'server-1',
      loadRow: (_, slot) async => HomeRow(
        id: 'sinceYouWatched$slot',
        title: 'Recommended For You',
        rowType: HomeRowType.latestMedia,
        items: [
          media(1, 201, type: 'Series', genres: ['Animation'], language: 'ja'),
          media(2, 202, type: 'Series', genres: ['Animation']),
          media(3, 203, type: 'Series', tags: ['Anime']),
        ],
        totalCount: 3,
      ),
      loadMore: ({required row, required serverId, offset}) async =>
          (row.items, row.totalCount),
    );

    final result = await service.load(
      section('anime-affinity', mediaType: 'tv', tags: ['anime']),
    );
    expect(result.page.results.map((item) => item.id), [201, 203]);
    expect(result.title, 'Personal anime-affinity');
  });

  test('items without a real TMDB id are omitted', () async {
    final bad = AggregatedItem(
      id: 'local',
      serverId: 'server-1',
      rawData: const {'Name': 'Local only', 'Type': 'Movie'},
    );
    final service = HomeLabDiscoveryPersonalisation.forTesting(
      serverId: 'server-1',
      loadRow: (_, slot) async => HomeRow(
        id: 'sinceYouWatched$slot',
        title: 'Recommended For You',
        rowType: HomeRowType.latestMedia,
        items: [bad],
        totalCount: 1,
      ),
      loadMore: ({required row, required serverId, offset}) async =>
          (row.items, row.totalCount),
    );

    final result = await service.load(section('recent-history'));
    expect(result.page.results, isEmpty);
  });
}
