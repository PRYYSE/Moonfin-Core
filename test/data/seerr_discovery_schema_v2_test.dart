import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

void main() {
  test('schema v2 round-trips rotation, availability and semantic fields', () {
    const catalogue = SeerrDiscoveryCatalogue(
      schemaVersion: 2,
      tabs: [
        SeerrDiscoveryTab(
          id: 'anime',
          title: 'Anime',
          initialLaneBudget: 22,
          minimumLaneCount: 12,
          poolBudgets: {'themes': 6, 'eras': 2},
          sections: [
            SeerrDiscoverySection(
              id: 'anime-isekai',
              title: 'Isekai',
              pool: 'themes',
              priority: SeerrDiscoveryPriority.high,
              weight: 1.5,
              cooldownSessions: 2,
              minItems: 10,
              availabilityMode: SeerrDiscoveryAvailabilityMode.notOwned,
              tags: ['anime', 'theme'],
              conditions: {'region': 'AU'},
              query: SeerrDiscoveryQuery(
                source: SeerrDiscoverySource.discoverTv,
                mediaType: 'tv',
                filters: {'genre': '16', 'language': 'ja'},
                keywordNames: ['isekai'],
                excludeKeywordNames: ['hentai'],
                providerNames: ['Crunchyroll'],
              ),
            ),
          ],
        ),
      ],
    );

    catalogue.validate();
    final restored = SeerrDiscoveryCatalogue.fromJson(catalogue.toJson());
    restored.validate();

    final tab = restored.tabs.single;
    final section = tab.sections.single;
    expect(restored.schemaVersion, 2);
    expect(tab.initialLaneBudget, 22);
    expect(tab.minimumLaneCount, 12);
    expect(tab.poolBudgets, {'themes': 6, 'eras': 2});
    expect(section.priority, SeerrDiscoveryPriority.high);
    expect(section.weight, 1.5);
    expect(section.cooldownSessions, 2);
    expect(section.minItems, 10);
    expect(section.availabilityMode, SeerrDiscoveryAvailabilityMode.notOwned);
    expect(section.tags, ['anime', 'theme']);
    expect(section.conditions, {'region': 'AU'});
    expect(section.query.keywordNames, ['isekai']);
    expect(section.query.excludeKeywordNames, ['hentai']);
    expect(section.query.providerNames, ['Crunchyroll']);
    expect(
      section.query.cacheKey,
      catalogue.tabs.single.sections.single.query.cacheKey,
    );
  });

  test(
    'semantic authoring fields never leak into executable route filters',
    () {
      const query = SeerrDiscoveryQuery(
        source: SeerrDiscoverySource.discoverMovies,
        mediaType: 'movie',
        filters: {'genre': '878'},
        keywordNames: ['time travel'],
        providerNames: ['Netflix'],
      );

      expect(query.toRouteParameters(), {
        'source': 'discoverMovies',
        'mediaType': 'movie',
        'sortBy': 'popularity.desc',
        'q.genre': '878',
      });
    },
  );

  test('invalid v2 lane constraints are rejected', () {
    const bad = SeerrDiscoveryCatalogue(
      schemaVersion: 2,
      tabs: [
        SeerrDiscoveryTab(
          id: 'movies',
          title: 'Movies',
          initialLaneBudget: 4,
          minimumLaneCount: 4,
          sections: [
            SeerrDiscoverySection(
              id: 'bad',
              title: 'Bad',
              previewLimit: 5,
              minItems: 6,
              query: SeerrDiscoveryQuery(
                source: SeerrDiscoverySource.discoverMovies,
                mediaType: 'movie',
              ),
            ),
          ],
        ),
      ],
    );

    expect(bad.validate, throwsFormatException);
  });
}
