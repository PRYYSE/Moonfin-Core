import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_seed_selector.dart';

SeerrDiscoveryTasteSeed _seed(
  String id,
  double affinity, {
  String mediaType = 'movie',
  Set<int> genres = const {},
  String? franchise,
}) =>
    SeerrDiscoveryTasteSeed(
      id: id,
      mediaType: mediaType,
      affinity: affinity,
      genreIds: genres,
      franchiseKey: franchise,
    );

void main() {
  test('first pass avoids near-identical genre clusters', () {
    final selected = SeerrDiscoverySeedSelector.select(
      [
        _seed('a', 10, genres: {28, 12}),
        _seed('b', 9, genres: {28, 12}),
        _seed('c', 8, genres: {35}),
        _seed('d', 7, genres: {878}),
      ],
      limit: 3,
    );

    expect(selected.map((seed) => seed.id), ['a', 'c', 'd']);
  });

  test('duplicate franchise seeds are deferred when alternatives exist', () {
    final selected = SeerrDiscoverySeedSelector.select(
      [
        _seed('film-1', 10, franchise: 'collection:42'),
        _seed('film-2', 9, franchise: 'collection:42'),
        _seed('other', 8, franchise: 'collection:77'),
      ],
      limit: 2,
    );

    expect(selected.map((seed) => seed.id), ['film-1', 'other']);
  });

  test('media type quota stops one type consuming mixed For You seeds', () {
    final selected = SeerrDiscoverySeedSelector.select(
      [
        _seed('m1', 10),
        _seed('m2', 9),
        _seed('m3', 8),
        _seed('tv1', 7, mediaType: 'tv'),
        _seed('tv2', 6, mediaType: 'tv'),
      ],
      limit: 4,
      maxPerMediaType: 2,
    );

    expect(selected.where((seed) => seed.mediaType == 'movie').length, 2);
    expect(selected.where((seed) => seed.mediaType == 'tv').length, 2);
  });

  test('diversity rules relax rather than returning too few seeds', () {
    final selected = SeerrDiscoverySeedSelector.select(
      [
        _seed('a', 10, genres: {28}, franchise: 'same'),
        _seed('b', 9, genres: {28}, franchise: 'same'),
        _seed('c', 8, genres: {28}, franchise: 'same'),
      ],
      limit: 3,
      maxPerMediaType: 1,
    );

    expect(selected.length, 3);
    expect(selected.map((seed) => seed.id), ['a', 'b', 'c']);
  });

  test('affinity order is deterministic for equivalent diversity', () {
    final selected = SeerrDiscoverySeedSelector.select(
      [
        _seed('low', 1, genres: {35}),
        _seed('high', 5, genres: {28}),
        _seed('mid', 3, genres: {878}),
      ],
      limit: 3,
    );
    expect(selected.map((seed) => seed.id), ['high', 'mid', 'low']);
  });
}
