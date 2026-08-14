import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/custom_external_lists_service.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_configured_lists_service.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';
import 'package:moonfin/preference/home_section_config.dart';

HomeSectionConfig _config() => HomeSectionConfig.pluginDynamic(
  serverId: 'custom',
  pluginSection: 'external-expanded-list',
  pluginDisplayText: 'External Expanded List',
  pluginSource: HomeSectionPluginSource.custom,
  enabled: true,
  pluginAdditionalData: jsonEncode({
    'source': 'mdblist',
    'type': 'user_list',
    'params': {'listid': 'ls-expanded'},
  }),
);

ImdbExternalListItem _item(int id) => ImdbExternalListItem(
  imdbId: 'tt${id.toString().padLeft(7, '0')}',
  tmdbId: '$id',
  title: 'Item $id',
  type: id.isEven ? 'Series' : 'Movie',
  year: 2025,
);

void main() {
  test(
    'expanded external query preserves configured source order across pages',
    () async {
      final config = _config();
      var fetches = 0;
      final service = SeerrDiscoveryConfiguredListsService.forTesting(
        readConfigs: () => [config],
        fetchItems: (_, {forceRefresh = false}) async {
          fetches++;
          return List.generate(45, (index) => _item(index + 1));
        },
      );
      final section = service.configuredSections().single;

      final first = await service.loadQuery(section.query, page: 1);
      final second = await service.loadQuery(section.query, page: 2);
      final third = await service.loadQuery(section.query, page: 3);

      expect(
        first.results.map((item) => item.id),
        List.generate(20, (index) => index + 1),
      );
      expect(
        second.results.map((item) => item.id),
        List.generate(20, (index) => index + 21),
      );
      expect(third.results.map((item) => item.id), [41, 42, 43, 44, 45]);
      expect(first.totalPages, 3);
      expect(third.totalResults, 45);
      expect(fetches, 1);
    },
  );

  test(
    'expanded query rejects non-external source instead of broadening it',
    () async {
      final service = SeerrDiscoveryConfiguredListsService.forTesting(
        readConfigs: () => [_config()],
        fetchItems: (_, {forceRefresh = false}) async => [_item(1)],
      );

      expect(
        () => service.loadQuery(
          const SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
          ),
        ),
        throwsArgumentError,
      );
    },
  );

  test('expanded query fails if configured source was removed', () async {
    final config = _config();
    var enabled = true;
    final service = SeerrDiscoveryConfiguredListsService.forTesting(
      readConfigs: () => enabled ? [config] : const [],
      fetchItems: (_, {forceRefresh = false}) async => [_item(1)],
    );
    final query = service.configuredSections().single.query;
    enabled = false;
    service.configuredSections();

    expect(() => service.loadQuery(query), throwsStateError);
  });
}
