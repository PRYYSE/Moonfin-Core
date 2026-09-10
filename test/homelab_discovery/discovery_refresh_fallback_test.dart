import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_tab_controller.dart';

HomeLabDiscoverySection _section(String id) => HomeLabDiscoverySection(
  id: id,
  title: id,
  minItems: 1,
  previewLimit: 4,
  priority: HomeLabDiscoveryPriority.anchor,
  query: const HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
);

HomeLabDiscoveryLaneLoadResult _loaded(
  HomeLabDiscoverySection section,
  int id,
) => HomeLabDiscoveryLaneLoadResult(
  section: section,
  items: [SeerrDiscoverItem(id: id, mediaType: 'movie', title: 'Item $id')],
  throughPage: 1,
  totalPages: 1,
);

void main() {
  test(
    'total explicit refresh failure retains the previous good tab',
    () async {
      final only = _section('only');
      var calls = 0;
      final controller = HomeLabDiscoveryTabController(
        tab: HomeLabDiscoveryTab(
          id: 'movies',
          title: 'Movies',
          sections: [only],
          initialLaneBudget: 1,
          minimumLaneCount: 1,
        ),
        sessionSeed: 'server:user',
        loadLane: (section) async {
          calls++;
          if (calls == 1) return _loaded(section, 7);
          return HomeLabDiscoveryLaneLoadResult(
            section: section,
            error: StateError('temporary refresh failure'),
          );
        },
      );

      final initial = await controller.load();
      expect(initial.usableLanes.single.items.single.id, 7);
      expect(initial.refreshFailure, isNull);

      final refreshed = await controller.refresh();
      expect(calls, 2);
      expect(controller.refreshNonce, 1);
      expect(refreshed.usableLanes.single.items.single.id, 7);
      expect(refreshed.failedLanes, isEmpty);
      expect(refreshed.refreshFailure, isA<StateError>());

      final resumed = await controller.load();
      expect(calls, 2);
      expect(identical(refreshed, resumed), isTrue);
    },
  );

  test('partial refresh is not replaced by stale data', () async {
    final first = _section('first');
    final second = _section('second');
    var round = 0;
    final controller = HomeLabDiscoveryTabController(
      tab: HomeLabDiscoveryTab(
        id: 'movies',
        title: 'Movies',
        sections: [first, second],
        initialLaneBudget: 2,
        minimumLaneCount: 2,
      ),
      sessionSeed: 'server:user',
      maxConcurrentLoads: 1,
      loadLane: (section) async {
        if (section.id == first.id) round++;
        if (round == 1) {
          return _loaded(section, section.id == first.id ? 1 : 2);
        }
        if (section.id == second.id) {
          return HomeLabDiscoveryLaneLoadResult(
            section: section,
            error: StateError('one row failed'),
          );
        }
        return _loaded(section, 9);
      },
    );

    final initial = await controller.load();
    expect(initial.usableLanes, hasLength(2));

    final refreshed = await controller.refresh();
    expect(refreshed.refreshFailure, isNull);
    expect(refreshed.usableLanes, hasLength(1));
    expect(refreshed.usableLanes.single.items.single.id, 9);
    expect(refreshed.failedLanes, hasLength(1));
  });
}
