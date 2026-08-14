import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/custom_external_lists_service.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_configured_lists_service.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';
import 'package:moonfin/preference/home_section_config.dart';

HomeSectionConfig _config({
  required String section,
  required String source,
  String type = 'user_list',
  String? display,
  bool enabled = true,
  String? mediaType,
}) => HomeSectionConfig.pluginDynamic(
  serverId: 'custom',
  pluginSection: section,
  pluginDisplayText: display,
  pluginSource: HomeSectionPluginSource.custom,
  enabled: enabled,
  pluginAdditionalData: jsonEncode({
    'source': source,
    'type': type,
    if (mediaType != null) 'media_type': mediaType,
    'params': {'listid': 'ls123'},
  }),
);

ImdbExternalListItem _item(int id, {String type = 'Movie', String? poster}) =>
    ImdbExternalListItem(
      imdbId: 'tt${id.toString().padLeft(7, '0')}',
      tmdbId: '$id',
      title: 'Item $id',
      type: type,
      year: 2024,
      rating: 7.5,
      posterUrl: poster,
    );

SeerrDiscoveryCatalogue _catalogue() => SeerrDiscoveryCatalogue(
  schemaVersion: 2,
  tabs: [
    const SeerrDiscoveryTab(id: 'movies', title: 'Movies', sections: []),
    SeerrDiscoveryTab(
      id: 'lists',
      title: 'Lists',
      initialLaneBudget: 16,
      minimumLaneCount: 8,
      poolBudgets: const {
        'smart-collections': 12,
        'configured-lists': 6,
      },
      sections: List.generate(
        20,
        (index) => SeerrDiscoverySection(
          id: 'smart-$index',
          title: 'Smart $index',
          pool: 'smart-collections',
          query: const SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
          ),
        ),
      ),
    ),
  ],
);

void main() {
  test('imports only enabled supported custom external-list configs', () {
    final configs = [
      _config(section: 'imdb-row', source: 'imdb', display: 'IMDb Picks'),
      _config(
        section: 'mdblist-row',
        source: 'mdblist',
        display: 'MDBList Picks',
      ),
      _config(section: 'tmdb-row', source: 'tmdb', display: 'TMDb Collection'),
      _config(
        section: 'letterboxd-row',
        source: 'letterboxd',
        display: 'Letterboxd Activity',
      ),
      _config(section: 'editorial-row', source: 'tmdb_chart'),
      _config(section: 'disabled-row', source: 'imdb', enabled: false),
    ];
    final service = SeerrDiscoveryConfiguredListsService.forTesting(
      readConfigs: () => configs,
      fetchItems: (_, {forceRefresh = false}) async => const [],
    );

    final sections = service.configuredSections();
    expect(sections.length, 4);
    expect(sections.map((section) => section.title).toSet(), {
      'IMDb Picks',
      'MDBList Picks',
      'TMDb Collection',
      'Letterboxd Activity',
    });
    expect(sections.map((section) => section.query.listProvider).toSet(), {
      'imdb',
      'mdblist',
      'tmdb',
      'letterboxd',
    });
  });

  test('prepends configured sources without replacing smart collections', () {
    final config = _config(
      section: 'movie-collection',
      source: 'tmdb',
      type: 'movie_collection',
      display: 'Movie Collection',
    );
    final service = SeerrDiscoveryConfiguredListsService.forTesting(
      readConfigs: () => [config],
      fetchItems: (_, {forceRefresh = false}) async => const [],
    );

    final merged = service.mergeIntoCatalogue(_catalogue());
    expect(merged.tabs.map((tab) => tab.id), ['movies', 'lists']);
    final lists = merged.tabs.last;
    expect(lists.sections.length, 21);
    expect(lists.sections.first.title, 'Movie Collection');
    expect(lists.sections.first.query.mediaType, 'movie');
    expect(lists.sections.first.query.listId, config.stableId);
    expect(
      lists.sections.skip(1).map((section) => section.id),
      List.generate(20, (index) => 'smart-$index'),
    );
    expect(lists.initialLaneBudget, 16);
    expect(lists.minimumLaneCount, 8);
    expect(lists.poolBudgets['smart-collections'], 12);
    expect(lists.poolBudgets['configured-lists'], 1);
  });

  test('keeps smart Lists destination when no external list is configured', () {
    final service = SeerrDiscoveryConfiguredListsService.forTesting(
      readConfigs: () => [_config(section: 'editorial', source: 'tmdb_chart')],
      fetchItems: (_, {forceRefresh = false}) async => const [],
    );

    final merged = service.mergeIntoCatalogue(_catalogue());
    expect(merged.tabs.map((tab) => tab.id), ['movies', 'lists']);
    expect(merged.tabs.last.sections.length, 20);
    expect(merged.tabs.last.sections.first.id, 'smart-0');
  });

  test('configured-list pool is capped so it cannot monopolise a session', () {
    final configs = List.generate(
      10,
      (index) => _config(
        section: 'list-$index',
        source: 'mdblist',
        display: 'List $index',
      ),
    );
    final service = SeerrDiscoveryConfiguredListsService.forTesting(
      readConfigs: () => configs,
      fetchItems: (_, {forceRefresh = false}) async => const [],
    );

    final lists = service.mergeIntoCatalogue(_catalogue()).tabs.last;
    expect(lists.sections.length, 30);
    expect(lists.poolBudgets['configured-lists'], 6);
    expect(lists.poolBudgets['smart-collections'], 12);
  });

  test(
    'loads and pages configured list once from existing external service',
    () async {
      final config = _config(
        section: 'big-list',
        source: 'mdblist',
        display: 'Big List',
      );
      var fetches = 0;
      final service = SeerrDiscoveryConfiguredListsService.forTesting(
        readConfigs: () => [config],
        fetchItems: (_, {forceRefresh = false}) async {
          fetches++;
          return List.generate(
            45,
            (index) =>
                _item(index + 1, type: index.isEven ? 'Movie' : 'Series'),
          );
        },
      );
      final section = service.configuredSections().single;

      final first = await service.load(section, page: 1);
      final second = await service.load(section, page: 2);
      final third = await service.load(section, page: 3);

      expect(first.results.length, 20);
      expect(second.results.length, 20);
      expect(third.results.length, 5);
      expect(first.totalResults, 45);
      expect(first.totalPages, 3);
      expect(fetches, 1);
      expect(first.results[0].mediaType, 'movie');
      expect(first.results[1].mediaType, 'tv');
    },
  );

  test('force refresh replaces in-memory list cache', () async {
    final config = _config(section: 'refresh-list', source: 'imdb');
    var generation = 0;
    final service = SeerrDiscoveryConfiguredListsService.forTesting(
      readConfigs: () => [config],
      fetchItems: (_, {forceRefresh = false}) async {
        generation++;
        return [_item(generation)];
      },
    );
    final section = service.configuredSections().single;

    final first = await service.load(section);
    final cached = await service.load(section);
    final refreshed = await service.load(section, forceRefresh: true);
    expect(first.results.single.id, 1);
    expect(cached.results.single.id, 1);
    expect(refreshed.results.single.id, 2);
  });

  test(
    'normalises TMDb image URL and drops entries without TMDb identity',
    () async {
      final config = _config(section: 'images', source: 'tmdb');
      final service = SeerrDiscoveryConfiguredListsService.forTesting(
        readConfigs: () => [config],
        fetchItems: (_, {forceRefresh = false}) async => [
          _item(10, poster: 'https://image.tmdb.org/t/p/w500/abc123.jpg'),
          ImdbExternalListItem(
            imdbId: 'tt0000999',
            title: 'IMDb only',
            type: 'Movie',
          ),
        ],
      );
      final page = await service.load(service.configuredSections().single);
      expect(page.results.length, 1);
      expect(page.results.single.posterPath, '/abc123.jpg');
    },
  );
}
