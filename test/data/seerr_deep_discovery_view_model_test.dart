import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_catalogue_loader.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_personalisation_service.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';
import 'package:moonfin/data/viewmodels/seerr_deep_discovery_view_model.dart';

SeerrDiscoverItem _item(
  int id, {
  String mediaType = 'movie',
  int? status,
  bool adult = false,
  String? title,
}) =>
    SeerrDiscoverItem(
      id: id,
      mediaType: mediaType,
      title: title ?? 'Item $id',
      adult: adult,
      mediaInfo: status == null ? null : SeerrMediaInfo(status: status),
    );

SeerrDiscoverySection _section(
  String id, {
  SeerrDiscoverySource source = SeerrDiscoverySource.discoverMovies,
  SeerrDiscoveryPriority priority = SeerrDiscoveryPriority.normal,
  SeerrDiscoveryAvailabilityMode availability =
      SeerrDiscoveryAvailabilityMode.all,
  String mediaType = 'movie',
  String? seed,
}) =>
    SeerrDiscoverySection(
      id: id,
      title: 'Title $id',
      priority: priority,
      minItems: 1,
      previewLimit: 3,
      availabilityMode: availability,
      query: SeerrDiscoveryQuery(
        source: source,
        mediaType: mediaType,
        seedStrategy: seed,
        filters: source == SeerrDiscoverySource.discoverMovies
            ? {'studio': id.hashCode.abs().toString()}
            : const {},
      ),
    );

SeerrDiscoveryCatalogue _catalogue() => SeerrDiscoveryCatalogue(
      schemaVersion: 2,
      tabs: [
        SeerrDiscoveryTab(
          id: 'for-you',
          title: 'For You',
          initialLaneBudget: 2,
          minimumLaneCount: 1,
          sections: [
            _section(
              'personal',
              source: SeerrDiscoverySource.personalised,
              mediaType: 'all',
              seed: 'recent-history',
              priority: SeerrDiscoveryPriority.anchor,
            ),
          ],
        ),
        SeerrDiscoveryTab(
          id: 'movies',
          title: 'Movies',
          initialLaneBudget: 3,
          minimumLaneCount: 2,
          sections: [
            _section('available', priority: SeerrDiscoveryPriority.anchor),
            _section(
              'requestable',
              availability: SeerrDiscoveryAvailabilityMode.requestable,
            ),
            _section('adult'),
          ],
        ),
        SeerrDiscoveryTab(
          id: 'lists',
          title: 'Lists',
          initialLaneBudget: 1,
          minimumLaneCount: 1,
          sections: [
            _section(
              'unconfigured-list',
              source: SeerrDiscoverySource.externalList,
              mediaType: 'all',
            ),
          ],
        ),
      ],
    );

SeerrDiscoveryCatalogueLoadResult _loadResult() =>
    SeerrDiscoveryCatalogueLoadResult(
      catalogue: _catalogue(),
      source: SeerrDiscoveryCatalogueSource.remote,
    );

void main() {
  test('defaults to For You and uses the accepted generated personal title',
      () async {
    final vm = SeerrDeepDiscoveryViewModel.forTesting(
      loadCatalogue: () async => _loadResult(),
      loadSessionSeed: () async => 'user-1',
      fetchPage: (_, __) async => const SeerrDiscoverPage(),
      fetchPersonal: (
        section,
        page, {
        forceRefresh = false,
      }) async => SeerrDiscoveryPersonalPage(
        title: 'Because You Watched "Dune"',
        page: SeerrDiscoverPage(
          page: 1,
          totalPages: 2,
          totalResults: 20,
          results: [_item(100)],
        ),
      ),
    );

    await vm.load();
    expect(vm.activeTabId, 'for-you');
    expect(vm.catalogueSource, SeerrDiscoveryCatalogueSource.remote);
    expect(vm.rows.single.title, 'Because You Watched "Dune"');
    expect(vm.rows.single.items.single.id, 100);
    expect(vm.rows.single.hasMore, isTrue);
    vm.dispose();
  });

  test('general discovery retains available local media', () async {
    final vm = SeerrDeepDiscoveryViewModel.forTesting(
      loadCatalogue: () async => _loadResult(),
      loadSessionSeed: () async => 'user-1',
      blockNsfw: () => false,
      fetchPersonal: (
        section,
        page, {
        forceRefresh = false,
      }) async => const SeerrDiscoveryPersonalPage(
        title: 'Personal',
        page: SeerrDiscoverPage(),
      ),
      fetchPage: (query, page) async {
        if (query.filters['studio'] == 'available'.hashCode.abs().toString()) {
          return SeerrDiscoverPage(
            page: 1,
            totalPages: 1,
            totalResults: 1,
            results: [_item(1, status: 5)],
          );
        }
        return SeerrDiscoverPage(
          page: 1,
          totalPages: 1,
          totalResults: 1,
          results: [_item(2)],
        );
      },
    );

    await vm.load();
    await vm.selectTab('movies');
    final available = vm.rows.firstWhere((row) => row.section.id == 'available');
    expect(available.items.single.id, 1);
    expect(available.items.single.isAvailable, isTrue);
    vm.dispose();
  });

  test('requestable lane excludes already available media', () async {
    final vm = SeerrDeepDiscoveryViewModel.forTesting(
      loadCatalogue: () async => _loadResult(),
      loadSessionSeed: () async => 'user-1',
      fetchPersonal: (
        section,
        page, {
        forceRefresh = false,
      }) async => const SeerrDiscoveryPersonalPage(
        title: 'Personal',
        page: SeerrDiscoverPage(),
      ),
      fetchPage: (query, page) async {
        final requestableMarker = 'requestable'.hashCode.abs().toString();
        if (query.filters['studio'] == requestableMarker) {
          return SeerrDiscoverPage(
            page: 1,
            totalPages: 1,
            totalResults: 2,
            results: [_item(5, status: 5), _item(6)],
          );
        }
        return SeerrDiscoverPage(
          page: 1,
          totalPages: 1,
          totalResults: 1,
          results: [_item(7)],
        );
      },
    );

    await vm.load();
    await vm.selectTab('movies');
    final row = vm.rows.firstWhere((entry) => entry.section.id == 'requestable');
    expect(row.items.map((item) => item.id), [6]);
    vm.dispose();
  });

  test('existing NSFW preference still filters dynamic catalogue results',
      () async {
    final vm = SeerrDeepDiscoveryViewModel.forTesting(
      loadCatalogue: () async => _loadResult(),
      loadSessionSeed: () async => 'user-1',
      blockNsfw: () => true,
      fetchPersonal: (
        section,
        page, {
        forceRefresh = false,
      }) async => const SeerrDiscoveryPersonalPage(
        title: 'Personal',
        page: SeerrDiscoverPage(),
      ),
      fetchPage: (query, page) async {
        final adultMarker = 'adult'.hashCode.abs().toString();
        if (query.filters['studio'] == adultMarker) {
          return SeerrDiscoverPage(
            page: 1,
            totalPages: 1,
            totalResults: 2,
            results: [
              _item(20, adult: true),
              _item(21, title: 'Ordinary Movie'),
            ],
          );
        }
        return SeerrDiscoverPage(
          page: 1,
          totalPages: 1,
          totalResults: 1,
          results: [_item(22)],
        );
      },
    );

    await vm.load();
    await vm.selectTab('movies');
    final row = vm.rows.firstWhere((entry) => entry.section.id == 'adult');
    expect(row.items.map((item) => item.id), [21]);
    vm.dispose();
  });

  test('unconfigured external list lane fails closed without breaking tab',
      () async {
    final vm = SeerrDeepDiscoveryViewModel.forTesting(
      loadCatalogue: () async => _loadResult(),
      loadSessionSeed: () async => 'user-1',
      fetchPage: (_, __) async => const SeerrDiscoverPage(),
      fetchPersonal: (
        section,
        page, {
        forceRefresh = false,
      }) async => const SeerrDiscoveryPersonalPage(
        title: 'Personal',
        page: SeerrDiscoverPage(),
      ),
    );

    await vm.load();
    await vm.selectTab('lists');
    expect(vm.error, isNull);
    expect(vm.rows, isEmpty);
    vm.dispose();
  });

  test('loadMore appends personal pages without duplicating existing ids',
      () async {
    final vm = SeerrDeepDiscoveryViewModel.forTesting(
      loadCatalogue: () async => _loadResult(),
      loadSessionSeed: () async => 'user-1',
      fetchPage: (_, __) async => const SeerrDiscoverPage(),
      fetchPersonal: (
        section,
        page, {
        forceRefresh = false,
      }) async => SeerrDiscoveryPersonalPage(
        title: 'Personal',
        page: SeerrDiscoverPage(
          page: page,
          totalPages: 2,
          totalResults: 3,
          results: page == 1 ? [_item(1), _item(2)] : [_item(2), _item(3)],
        ),
      ),
    );

    await vm.load();
    await vm.loadMore(0);
    expect(vm.rows.single.items.map((item) => item.id), [1, 2, 3]);
    expect(vm.rows.single.page, 2);
    vm.dispose();
  });
}
