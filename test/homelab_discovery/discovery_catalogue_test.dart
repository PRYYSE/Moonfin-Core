import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';

Map<String, dynamic> validCatalogue({int schemaVersion = 2}) => {
  'schemaVersion': schemaVersion,
  'catalogueRevision': 'test-1',
  'generatedAt': '2026-09-06T00:00:00Z',
  'tabs': [
    {
      'id': 'movies',
      'title': 'Movies',
      'initialLaneBudget': 12,
      'minimumLaneCount': 4,
      'sections': [
        {
          'id': 'movies-top',
          'title': 'Top Movies',
          'priority': 'anchor',
          'query': {
            'source': 'discoverMovies',
            'mediaType': 'movie',
            'sortBy': 'vote_average.desc',
          },
        },
      ],
    },
  ],
};

void main() {
  test('valid current catalogue parses and validates', () {
    final catalogue = HomeLabDiscoveryCatalogue.fromJson(validCatalogue());

    expect(catalogue.schemaVersion, 2);
    expect(catalogue.catalogueRevision, 'test-1');
    expect(catalogue.tabs.single.id, 'movies');
    expect(catalogue.tabs.single.sections.single.isAnchor, isTrue);
  });

  test('legacy schema version 1 remains compatible during migration', () {
    final catalogue = HomeLabDiscoveryCatalogue.fromJson(
      validCatalogue(schemaVersion: 1),
    );
    expect(catalogue.schemaVersion, 1);
  });

  test('unsupported schema fails closed', () {
    expect(
      () => HomeLabDiscoveryCatalogue.fromJson(validCatalogue(schemaVersion: 99)),
      throwsFormatException,
    );
  });

  test('unknown query source fails instead of silently changing meaning', () {
    final json = validCatalogue();
    final section = ((json['tabs'] as List).single as Map)['sections'] as List;
    ((section.single as Map)['query'] as Map)['source'] = 'madeUpSource';

    expect(
      () => HomeLabDiscoveryCatalogue.fromJson(json),
      throwsFormatException,
    );
  });

  test('duplicate section ids are rejected across tabs', () {
    final json = validCatalogue();
    final originalTab = Map<String, dynamic>.from((json['tabs'] as List).single as Map);
    final second = Map<String, dynamic>.from(originalTab)
      ..['id'] = 'series'
      ..['title'] = 'Series';
    json['tabs'] = [originalTab, second];

    expect(
      () => HomeLabDiscoveryCatalogue.fromJson(json),
      throwsFormatException,
    );
  });
}
