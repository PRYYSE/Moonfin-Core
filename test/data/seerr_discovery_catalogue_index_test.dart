import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_catalogue_index.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

SeerrDiscoverySection _section(
  String id,
  String pool, {
  bool expandable = true,
}) => SeerrDiscoverySection(
  id: id,
  title: id,
  pool: pool,
  expandable: expandable,
  query: const SeerrDiscoveryQuery(
    source: SeerrDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
);

void main() {
  test('groups every expandable lane without applying session budgets', () {
    final tab = SeerrDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 2,
      minimumLaneCount: 1,
      sections: [
        _section('popular', 'movie-anchor'),
        _section('hidden', 'movie-discovery'),
        _section('horror', 'movie-genres'),
        _section('comedy', 'movie-genres'),
        _section('internal-only', 'movie-genres', expandable: false),
      ],
    );

    final groups = SeerrDiscoveryCatalogueIndex.groups(tab);
    expect(SeerrDiscoveryCatalogueIndex.expandableCount(tab), 4);
    expect(groups.map((group) => group.title), [
      'Essentials',
      'Discover More',
      'Genres',
    ]);
    expect(
      groups.expand((group) => group.sections).map((section) => section.id),
      ['popular', 'hidden', 'horror', 'comedy'],
    );
  });

  test('known catalogue pools get concise user-facing names', () {
    expect(
      SeerrDiscoveryCatalogueIndex.poolTitle('anime-themes'),
      'Themes & Topics',
    );
    expect(
      SeerrDiscoveryCatalogueIndex.poolTitle('series-networks'),
      'Networks',
    );
    expect(
      SeerrDiscoveryCatalogueIndex.poolTitle('movie-providers'),
      'Streaming Services',
    );
    expect(
      SeerrDiscoveryCatalogueIndex.poolTitle('anime-rating'),
      'Ratings & Hidden Gems',
    );
  });

  test('unknown pool names are still readable instead of failing', () {
    expect(
      SeerrDiscoveryCatalogueIndex.poolTitle('future-special-pool'),
      'Future Special Pool',
    );
  });
}
