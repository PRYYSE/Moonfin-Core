import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_session.dart';

HomeLabDiscoverySection section({int minItems = 2}) => HomeLabDiscoverySection(
  id: 'lane',
  title: 'Lane',
  minItems: minItems,
  previewLimit: 4,
  dedupGroup: 'lane',
  query: const HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
);

void main() {
  test('one lane error is isolated into its result', () async {
    final loader = HomeLabDiscoveryLaneLoader(
      fetchPage: (_, _) async => throw StateError('boom'),
    );

    final result = await loader.load(section());
    expect(result.hasError, isTrue);
    expect(result.items, isEmpty);
  });

  test('session dedup prefers novelty but backfills usable row', () async {
    final session = HomeLabDiscoverySession()
      ..markSeen('tab', ['movie:1', 'movie:2']);
    final loader = HomeLabDiscoveryLaneLoader(
      session: session,
      sharedDedupGroup: 'tab',
      fetchPage: (_, _) async => const SeerrDiscoverPage(
        page: 1,
        totalPages: 1,
        results: [
          SeerrDiscoverItem(id: 1, mediaType: 'movie'),
          SeerrDiscoverItem(id: 2, mediaType: 'movie'),
          SeerrDiscoverItem(id: 3, mediaType: 'movie'),
        ],
      ),
    );

    final result = await loader.load(section());
    expect(result.hasError, isFalse);
    expect(result.items.first.id, 3);
    expect(result.items.length, greaterThanOrEqualTo(2));
  });

  test('sparse successful lane is hidden rather than treated as error', () async {
    final loader = HomeLabDiscoveryLaneLoader(
      fetchPage: (_, _) async => const SeerrDiscoverPage(
        page: 1,
        totalPages: 1,
        results: [SeerrDiscoverItem(id: 1, mediaType: 'movie')],
      ),
    );

    final result = await loader.load(section(minItems: 2));
    expect(result.hasError, isFalse);
    expect(result.shouldHide, isTrue);
  });
}
