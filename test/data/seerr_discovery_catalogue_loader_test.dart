import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_catalogue_loader.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

SeerrDiscoveryCatalogue _catalogue(int schema, String id) =>
    SeerrDiscoveryCatalogue(
      schemaVersion: schema,
      tabs: [
        SeerrDiscoveryTab(
          id: id,
          title: id,
          sections: [
            SeerrDiscoverySection(
              id: '$id-section',
              title: 'Section',
              query: const SeerrDiscoveryQuery(
                source: SeerrDiscoverySource.discoverMovies,
                mediaType: 'movie',
              ),
            ),
          ],
        ),
      ],
    );

void main() {
  test(
    'valid remote catalogue wins and becomes last-known-good cache',
    () async {
      final remote = _catalogue(2, 'remote');
      Map<String, dynamic>? written;
      final loader = SeerrDiscoveryCatalogueLoader(
        fallback: _catalogue(1, 'fallback'),
        fetchRemote: () async => remote.toJson(),
        readCached: () async => null,
        writeCached: (json) async => written = json,
      );

      final result = await loader.load();
      expect(result.source, SeerrDiscoveryCatalogueSource.remote);
      expect(result.catalogue.tabs.single.id, 'remote');
      expect(written?['schemaVersion'], 2);
    },
  );

  test('invalid remote falls back to valid last-known-good cache', () async {
    final cached = _catalogue(2, 'cached');
    final loader = SeerrDiscoveryCatalogueLoader(
      fallback: _catalogue(1, 'fallback'),
      fetchRemote: () async => {'schemaVersion': 2, 'tabs': []},
      readCached: () async => cached.toJson(),
      writeCached: (_) async {},
    );

    // An empty catalogue is structurally valid, so force a duplicate tab error.
    final duplicate = cached.toJson();
    duplicate['tabs'] = [
      cached.tabs.single.toJson(),
      cached.tabs.single.toJson(),
    ];
    final loaderWithBadRemote = SeerrDiscoveryCatalogueLoader(
      fallback: _catalogue(1, 'fallback'),
      fetchRemote: () async => duplicate,
      readCached: () async => cached.toJson(),
      writeCached: (_) async {},
    );

    final result = await loaderWithBadRemote.load();
    expect(result.source, SeerrDiscoveryCatalogueSource.cached);
    expect(result.catalogue.tabs.single.id, 'cached');
    expect(result.remoteError, isNotNull);

    // Keep the first loader referenced so analyser catches signature drift.
    expect(loader.maxSupportedSchemaVersion, 2);
  });

  test(
    'unsupported newer remote schema does not replace compatible cache',
    () async {
      final newer = _catalogue(3, 'future');
      final cached = _catalogue(2, 'cached');
      final loader = SeerrDiscoveryCatalogueLoader(
        fallback: _catalogue(1, 'fallback'),
        fetchRemote: () async => newer.toJson(),
        readCached: () async => cached.toJson(),
        writeCached: (_) async {},
      );

      final result = await loader.load();
      expect(result.source, SeerrDiscoveryCatalogueSource.cached);
      expect(result.catalogue.schemaVersion, 2);
    },
  );

  test('remote and cache failure fall back to built-in catalogue', () async {
    final fallback = _catalogue(1, 'fallback');
    final loader = SeerrDiscoveryCatalogueLoader(
      fallback: fallback,
      fetchRemote: () async => throw StateError('server unavailable'),
      readCached: () async => throw StateError('cache corrupt'),
      writeCached: (_) async {},
    );

    final result = await loader.load();
    expect(result.source, SeerrDiscoveryCatalogueSource.builtInFallback);
    expect(result.catalogue.tabs.single.id, 'fallback');
    expect(result.remoteError, isNotNull);
    expect(result.cacheError, isNotNull);
  });
}
