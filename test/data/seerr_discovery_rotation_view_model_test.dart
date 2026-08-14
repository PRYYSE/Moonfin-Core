import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_catalogue_loader.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_personalisation_service.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_rotation_history.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';
import 'package:moonfin/data/viewmodels/seerr_deep_discovery_view_model.dart';

SeerrDiscoverySection _section(
  String id, {
  SeerrDiscoveryPriority priority = SeerrDiscoveryPriority.normal,
  int cooldownSessions = 0,
}) =>
    SeerrDiscoverySection(
      id: id,
      title: id,
      priority: priority,
      cooldownSessions: cooldownSessions,
      minItems: 1,
      previewLimit: 1,
      query: SeerrDiscoveryQuery(
        source: SeerrDiscoverySource.discoverMovies,
        mediaType: 'movie',
        filters: {'studio': id},
      ),
    );

SeerrDiscoveryCatalogueLoadResult _catalogue() =>
    SeerrDiscoveryCatalogueLoadResult(
      source: SeerrDiscoveryCatalogueSource.remote,
      catalogue: SeerrDiscoveryCatalogue(
        schemaVersion: 2,
        tabs: [
          SeerrDiscoveryTab(
            id: 'movies',
            title: 'Movies',
            initialLaneBudget: 2,
            minimumLaneCount: 2,
            sections: [
              _section('anchor', priority: SeerrDiscoveryPriority.anchor),
              _section('optional-a', cooldownSessions: 3),
              _section('optional-b', cooldownSessions: 3),
            ],
          ),
        ],
      ),
    );

SeerrDiscoverPage _page(SeerrDiscoveryQuery query) => SeerrDiscoverPage(
      page: 1,
      totalPages: 1,
      totalResults: 1,
      results: [
        SeerrDiscoverItem(
          id: query.filters['studio'].hashCode.abs(),
          mediaType: 'movie',
          title: query.filters['studio'],
        ),
      ],
    );

void main() {
  test('restored cooldown avoids a lane shown in the previous session', () async {
    final previous = SeerrDiscoveryRotationHistory()
      ..commitSession(['optional-a']);
    Map<String, SeerrDiscoveryRotationHistory>? saved;

    final vm = SeerrDeepDiscoveryViewModel.forTesting(
      loadCatalogue: () async => _catalogue(),
      loadSessionSeed: () async => 'server|user-a',
      loadRotationHistory: (_) async => {'movies': previous},
      saveRotationHistory: (_, histories) async => saved = histories,
      fetchPage: (query, _) async => _page(query),
      fetchPersonal: (section, page, {forceRefresh = false}) async =>
          const SeerrDiscoveryPersonalPage(
            title: 'unused',
            page: SeerrDiscoverPage(),
          ),
    );

    await vm.load();

    expect(vm.rows.map((row) => row.section.id), ['anchor', 'optional-b']);
    expect(saved, isNotNull);
    expect(saved!['movies']!.sessionNumber, 2);
    vm.dispose();
  });

  test('new session state is persisted using the current user scope', () async {
    String? savedScope;
    Map<String, SeerrDiscoveryRotationHistory>? saved;
    final vm = SeerrDeepDiscoveryViewModel.forTesting(
      loadCatalogue: () async => _catalogue(),
      loadSessionSeed: () async => 'server|user-b',
      loadRotationHistory: (_) async => {},
      saveRotationHistory: (scope, histories) async {
        savedScope = scope;
        saved = histories;
      },
      fetchPage: (query, _) async => _page(query),
      fetchPersonal: (section, page, {forceRefresh = false}) async =>
          const SeerrDiscoveryPersonalPage(
            title: 'unused',
            page: SeerrDiscoverPage(),
          ),
    );

    await vm.load();

    expect(savedScope, 'server|user-b');
    expect(saved, isNotNull);
    expect(saved!['movies']!.sessionNumber, 1);
    expect(saved!['movies']!.sessionsSinceSeen.keys, contains('anchor'));
    vm.dispose();
  });
}
