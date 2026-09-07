import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_tab_presentation.dart';

HomeLabDiscoverySection personalSection(
  String id,
  String strategy, {
  int minItems = 2,
}) => HomeLabDiscoverySection(
  id: id,
  title: 'Personal $id',
  minItems: minItems,
  previewLimit: 6,
  dedupGroup: 'personal',
  query: HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.personalised,
    mediaType: 'all',
    seedStrategy: strategy,
  ),
);

HomeLabDiscoverySection regularSection(String id) => HomeLabDiscoverySection(
  id: id,
  title: 'Regular $id',
  minItems: 1,
  query: const HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
);

SeerrDiscoverItem item(int id, String title) =>
    SeerrDiscoverItem(id: id, mediaType: 'tv', name: title);

HomeLabDiscoveryLaneLoadResult result(
  HomeLabDiscoverySection section,
  String title,
  List<SeerrDiscoverItem> items, {
  Object? error,
}) => HomeLabDiscoveryLaneLoadResult(
  section: section,
  displayTitle: title,
  items: items,
  throughPage: 2,
  totalPages: 7,
  error: error,
);

void main() {
  test('presentation is independent of async result insertion order', () {
    final first = personalSection('first', 'recent-history');
    final second = personalSection('second', 'favourites');
    final tab = HomeLabDiscoveryTab(
      id: 'for-you',
      title: 'For You',
      sections: [first, second],
    );
    final firstResult = result(first, 'Top Picks For You', [
      item(1, 'Demon Slayer: Kimetsu no Yaiba'),
      item(2, 'Demon Slayer: Mugen Train'),
      item(3, 'Pluto'),
    ]);
    final secondResult = result(second, 'Top Picks For You', [
      item(4, 'Demon Slayer: Entertainment District'),
      item(5, 'Monster'),
      item(6, 'Vinland Saga'),
    ]);

    final forward = LinkedHashMap<String, HomeLabDiscoveryLaneLoadResult>()
      ..[first.id] = firstResult
      ..[second.id] = secondResult;
    final reverse = LinkedHashMap<String, HomeLabDiscoveryLaneLoadResult>()
      ..[second.id] = secondResult
      ..[first.id] = firstResult;

    final a = HomeLabDiscoveryTabPresentation.compose(tab, forward);
    final b = HomeLabDiscoveryTabPresentation.compose(tab, reverse);

    expect(a.map((value) => value.section.id), ['first', 'second']);
    expect(a.map((value) => value.displayTitle), [
      'Top Picks For You',
      'More Picks For You',
    ]);
    expect(
      b.map((value) => value.displayTitle).toList(),
      a.map((value) => value.displayTitle).toList(),
    );
    expect(
      b.map((value) => value.items.map((item) => item.id).toList()).toList(),
      a.map((value) => value.items.map((item) => item.id).toList()).toList(),
    );
    expect(a[1].items.take(2).map((value) => value.id), [5, 6]);
  });

  test('non-personal, sparse and errored results preserve lane semantics', () {
    final personal = personalSection('personal', 'recent-history', minItems: 2);
    final regular = regularSection('regular');
    final broken = personalSection('broken', 'favourites');
    final tab = HomeLabDiscoveryTab(
      id: 'mixed',
      title: 'Mixed',
      sections: [regular, personal, broken],
    );
    final regularResult = result(regular, 'Original regular title', [
      item(10, 'Movie'),
    ]);
    final sparseResult = result(personal, 'Personal source title', [
      item(11, 'Only One'),
    ]);
    final error = StateError('boom');
    final brokenResult = result(
      broken,
      'Broken source title',
      const [],
      error: error,
    );

    final composed = HomeLabDiscoveryTabPresentation.compose(tab, {
      broken.id: brokenResult,
      personal.id: sparseResult,
      regular.id: regularResult,
    });

    expect(composed.map((value) => value.section.id), [
      'regular',
      'personal',
      'broken',
    ]);
    expect(composed[0], same(regularResult));
    expect(composed[0].displayTitle, 'Original regular title');
    expect(composed[1].items.single.id, 11);
    expect(composed[1].shouldHide, isTrue);
    expect(composed[2], same(brokenResult));
    expect(composed[2].error, same(error));
  });

  test('missing asynchronous result is skipped without reordering others', () {
    final first = regularSection('first');
    final missing = regularSection('missing');
    final last = regularSection('last');
    final tab = HomeLabDiscoveryTab(
      id: 'tab',
      title: 'Tab',
      sections: [first, missing, last],
    );

    final composed = HomeLabDiscoveryTabPresentation.compose(tab, {
      last.id: result(last, 'Last', [item(3, 'Three')]),
      first.id: result(first, 'First', [item(1, 'One')]),
    });

    expect(composed.map((value) => value.section.id), ['first', 'last']);
  });
}
