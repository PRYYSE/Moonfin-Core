import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/models/aggregated_item.dart';
import 'package:moonfin/data/models/home_row.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_personalisation_service.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

AggregatedItem _item(
  int tmdbId, {
  String type = 'Movie',
  String serverId = 'seerr',
  bool blacklisted = false,
}) => AggregatedItem(
  id: serverId == 'seerr' ? '$tmdbId' : 'jellyfin-$tmdbId',
  serverId: serverId,
  rawData: {
    'Name': 'Item $tmdbId',
    'Type': type,
    'Overview': 'Overview $tmdbId',
    'PosterPath': '/poster-$tmdbId.jpg',
    'BackdropPath': '/backdrop-$tmdbId.jpg',
    'ProductionYear': 2020 + (tmdbId % 5),
    'CommunityRating': 7.5,
    'ProviderIds': {'Tmdb': '$tmdbId'},
    'SeerrMediaType': type == 'Series' ? 'tv' : 'movie',
    'OriginalLanguage': 'en',
    'GenreIds': [18, 35],
    'Adult': false,
    'IsBlacklisted': blacklisted,
  },
);

SeerrDiscoverySection _section({
  String id = 'for-you-because-you-watched',
  String strategy = 'recent-history',
  String mediaType = 'all',
  List<String> tags = const [],
}) => SeerrDiscoverySection(
  id: id,
  title: 'Fallback Personal Title',
  tags: tags,
  query: SeerrDiscoveryQuery(
    source: SeerrDiscoverySource.personalised,
    mediaType: mediaType,
    seedStrategy: strategy,
  ),
);

void main() {
  test(
    'uses stable accepted Home row slot and dynamic generated title',
    () async {
      int? requestedSlot;
      List<String>? requestedTypes;
      bool? requestedAnimeOnly;
      final service = SeerrDiscoveryPersonalisationService.forTesting(
        serverId: 'server-1',
        loadRow:
            (
              serverId,
              rowIndex, {
              preferredItemTypes,
              animeOnly = false,
            }) async {
              requestedSlot = rowIndex;
              requestedTypes = preferredItemTypes;
              requestedAnimeOnly = animeOnly;
              return HomeRow(
                id: 'sinceYouWatched$rowIndex',
                title: 'Because You Watched "Dune"',
                rowType: HomeRowType.latestMedia,
                items: List.generate(15, (index) => _item(index + 1)),
                totalCount: 30,
              );
            },
        loadMore: ({required row, required serverId, offset}) async =>
            (row.items, row.totalCount),
      );

      final result = await service.load(_section());
      expect(requestedSlot, 1);
      expect(requestedTypes, isNull);
      expect(requestedAnimeOnly, isFalse);
      expect(result.title, 'Because You Watched "Dune"');
      expect(result.page.results.length, 15);
      expect(result.page.totalPages, 2);
    },
  );

  test(
    'movie series and anime sections constrain the accepted engine',
    () async {
      final calls = <(List<String>?, bool)>[];
      final service = SeerrDiscoveryPersonalisationService.forTesting(
        serverId: 'server-1',
        loadRow:
            (
              serverId,
              rowIndex, {
              preferredItemTypes,
              animeOnly = false,
            }) async {
              calls.add((preferredItemTypes, animeOnly));
              return HomeRow(
                id: 'sinceYouWatched$rowIndex',
                title: 'Recommended For You',
                rowType: HomeRowType.latestMedia,
                items: [_item(rowIndex)],
                totalCount: 1,
              );
            },
        loadMore: ({required row, required serverId, offset}) async =>
            (row.items, row.totalCount),
      );

      await service.load(_section(id: 'movie', mediaType: 'movie'));
      await service.load(_section(id: 'series', mediaType: 'tv'));
      await service.load(
        _section(
          id: 'anime-personal',
          strategy: 'anime-affinity',
          tags: const ['anime'],
        ),
      );

      expect(calls[0], (const ['Movie'], false));
      expect(calls[1], (const ['Series'], false));
      expect(calls[2], (const ['Movie', 'Series'], true));
    },
  );

  test('pages through the existing scored Home recommendation cache', () async {
    final all = List.generate(32, (index) => _item(index + 1));
    var loadMoreCalls = 0;
    final service = SeerrDiscoveryPersonalisationService.forTesting(
      serverId: 'server-1',
      loadRow:
          (serverId, rowIndex, {preferredItemTypes, animeOnly = false}) async =>
              HomeRow(
                id: 'sinceYouWatched$rowIndex',
                title: 'Top Picks For You',
                rowType: HomeRowType.latestMedia,
                items: all.take(15).toList(),
                totalCount: all.length,
              ),
      loadMore: ({required row, required serverId, offset}) async {
        loadMoreCalls++;
        final end = ((offset ?? row.items.length) + 15).clamp(0, all.length);
        return (all.take(end).toList(), all.length);
      },
    );

    final section = _section();
    final first = await service.load(section, page: 1);
    final second = await service.load(section, page: 2);
    final third = await service.load(section, page: 3);

    expect(
      first.page.results.map((item) => item.id),
      List.generate(15, (index) => index + 1),
    );
    expect(
      second.page.results.map((item) => item.id),
      List.generate(15, (index) => index + 16),
    );
    expect(third.page.results.map((item) => item.id), [31, 32]);
    expect(loadMoreCalls, 2);
  });

  test(
    'local accepted recommendation is surfaced as available with Jellyfin id',
    () async {
      final service = SeerrDiscoveryPersonalisationService.forTesting(
        serverId: 'server-1',
        loadRow:
            (
              serverId,
              rowIndex, {
              preferredItemTypes,
              animeOnly = false,
            }) async => HomeRow(
              id: 'sinceYouWatched$rowIndex',
              title: 'Local Pick',
              rowType: HomeRowType.latestMedia,
              items: [_item(42, serverId: 'jellyfin-local')],
              totalCount: 1,
            ),
        loadMore: ({required row, required serverId, offset}) async =>
            (row.items, row.totalCount),
      );

      final result = await service.load(_section());
      final item = result.page.results.single;
      expect(item.id, 42);
      expect(item.isAvailable, isTrue);
      expect(item.mediaInfo?.jellyfinMediaId, 'jellyfin-42');
    },
  );

  test('blacklisted accepted recommendation preserves block state', () async {
    final service = SeerrDiscoveryPersonalisationService.forTesting(
      serverId: 'server-1',
      loadRow:
          (serverId, rowIndex, {preferredItemTypes, animeOnly = false}) async =>
              HomeRow(
                id: 'sinceYouWatched$rowIndex',
                title: 'Blocked',
                rowType: HomeRowType.latestMedia,
                items: [_item(99, blacklisted: true)],
                totalCount: 1,
              ),
      loadMore: ({required row, required serverId, offset}) async =>
          (row.items, row.totalCount),
    );

    final result = await service.load(_section());
    expect(result.page.results.single.isBlacklisted, isTrue);
  });
}
