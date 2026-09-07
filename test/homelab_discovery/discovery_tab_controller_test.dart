import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_rotation_history.dart';
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

  test('lane I/O is bounded without changing catalogue order', () async {
    final sections = List.generate(6, (index) => section('section-$index'));
    final tab = HomeLabDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      sections: sections,
      initialLaneBudget: sections.length,
      minimumLaneCount: sections.length,
    );
    var inFlight = 0;
    var peakInFlight = 0;
    final controller = HomeLabDiscoveryTabController(
      tab: tab,
      sessionSeed: 'server:user',
      maxConcurrentLoads: 2,
      loadLane: (section) async {
        inFlight++;
        if (inFlight > peakInFlight) peakInFlight = inFlight;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        inFlight--;
        final index = int.parse(section.id.split('-').last);
        return loaded(section, [index + 1]);
      },
    );

    final result = await controller.load();

    expect(peakInFlight, 2);
    expect(
      result.lanes.map((value) => value.section.id).toList(),
      sections.map((value) => value.id).toList(),
    );
  });

  test('rotation history records only rows that actually surface', () async {
    final first = section('first');
    final failed = section('failed');
    final sparse = section('sparse');
    final history = HomeLabDiscoveryRotationHistory();
    var persistCalls = 0;
    final controller = HomeLabDiscoveryTabController(
      tab: HomeLabDiscoveryTab(
        id: 'movies',
        title: 'Movies',
        sections: [first, failed, sparse],
        initialLaneBudget: 3,
        minimumLaneCount: 3,
      ),
      sessionSeed: 'server:user',
      rotationHistory: history,
      persistRotationHistory: () async {
        persistCalls++;
      },
      loadLane: (candidate) async {
        if (candidate.id == failed.id) throw StateError('boom');
        if (candidate.id == sparse.id) return loaded(candidate, const []);
        return loaded(candidate, [1]);
      },
    );

    final result = await controller.load();

    expect(result.usableLanes.map((value) => value.section.id), ['first']);
    expect(result.failedLanes.map((value) => value.section.id), ['failed']);
    expect(result.hiddenLanes.map((value) => value.section.id), ['sparse']);
    expect(history.sessionNumber, 1);
    expect(history.sessionsSinceSeen['first'], 0);
    expect(history.sessionsSinceSeen.containsKey('failed'), isFalse);
    expect(history.sessionsSinceSeen.containsKey('sparse'), isFalse);
    expect(persistCalls, 1);
  });

  test('refresh rotates nonce while reset persists a fresh session', () async {
    final only = section('only');
    final history = HomeLabDiscoveryRotationHistory();
    var persistCalls = 0;
    final controller = HomeLabDiscoveryTabController(
      tab: HomeLabDiscoveryTab(
        id: 'movies',
        title: 'Movies',
        sections: [only],
        initialLaneBudget: 1,
        minimumLaneCount: 1,
      ),
      sessionSeed: 'server:user',
      rotationHistory: history,
      persistRotationHistory: () async {
        persistCalls++;
      },
      loadLane: (section) async => loaded(section, [1, 2]),
    );

    await controller.load();
    expect(controller.refreshNonce, 0);
    expect(history.sessionsSinceSeen, isNotEmpty);
    expect(persistCalls, 1);

    await controller.refresh();
    expect(controller.refreshNonce, 1);
    expect(persistCalls, 2);

    await controller.resetSession();
    expect(controller.refreshNonce, 0);
    expect(history.sessionNumber, 0);
    expect(history.sessionsSinceSeen, isEmpty);
    expect(persistCalls, 3);
  });
}
