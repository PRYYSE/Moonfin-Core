import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_tab_controller.dart';

HomeLabDiscoverySection section(String id) => HomeLabDiscoverySection(
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

SeerrDiscoverItem item(int id) =>
    SeerrDiscoverItem(id: id, mediaType: 'movie', title: 'Item $id');

HomeLabDiscoveryLaneLoadResult loaded(
  HomeLabDiscoverySection section,
  List<int> ids,
) => HomeLabDiscoveryLaneLoadResult(
  section: section,
  items: ids.map(item).toList(growable: false),
  throughPage: 1,
  totalPages: 3,
);

void main() {
  test('reverse async completion still presents in selected order', () async {
    final first = section('first');
    final second = section('second');
    final tab = HomeLabDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      sections: [first, second],
      initialLaneBudget: 2,
      minimumLaneCount: 2,
    );
    final completers = <String, Completer<HomeLabDiscoveryLaneLoadResult>>{
      first.id: Completer<HomeLabDiscoveryLaneLoadResult>(),
      second.id: Completer<HomeLabDiscoveryLaneLoadResult>(),
    };
    final controller = HomeLabDiscoveryTabController(
      tab: tab,
      sessionSeed: 'server:user',
      loadLane: (section) => completers[section.id]!.future,
    );

    final pending = controller.load();
    completers[second.id]!.complete(loaded(second, [2, 3]));
    await Future<void>.delayed(Duration.zero);
    completers[first.id]!.complete(loaded(first, [1, 2]));

    final result = await pending;
    expect(result.selectedSections.map((value) => value.id), [
      'first',
      'second',
    ]);
    expect(result.lanes.map((value) => value.section.id), ['first', 'second']);
    expect(result.lanes[0].items.map((value) => value.id), [1, 2]);
    expect(result.lanes[1].items.map((value) => value.id), [3]);
    expect(result.usableLanes.length, 2);
  });

  test(
    'unexpected lane exception is isolated without aborting the tab',
    () async {
      final first = section('first');
      final second = section('second');
      final tab = HomeLabDiscoveryTab(
        id: 'movies',
        title: 'Movies',
        sections: [first, second],
        initialLaneBudget: 2,
        minimumLaneCount: 2,
      );
      final controller = HomeLabDiscoveryTabController(
        tab: tab,
        sessionSeed: 'server:user',
        loadLane: (section) async {
          if (section.id == second.id) throw StateError('boom');
          return loaded(section, [1, 2]);
        },
      );

      final result = await controller.load();
      expect(result.usableLanes.map((value) => value.section.id), ['first']);
      expect(result.failedLanes.map((value) => value.section.id), ['second']);
    },
  );

  test('refresh rotates nonce while reset starts a fresh session', () async {
    final only = section('only');
    final controller = HomeLabDiscoveryTabController(
      tab: HomeLabDiscoveryTab(
        id: 'movies',
        title: 'Movies',
        sections: [only],
        initialLaneBudget: 1,
        minimumLaneCount: 1,
      ),
      sessionSeed: 'server:user',
      loadLane: (section) async => loaded(section, [1, 2]),
    );

    await controller.load();
    expect(controller.refreshNonce, 0);
    await controller.refresh();
    expect(controller.refreshNonce, 1);
    controller.resetSession();
    expect(controller.refreshNonce, 0);
  });
}
