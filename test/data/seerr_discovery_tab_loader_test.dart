import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_lane_loader.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_tab_loader.dart';

SeerrDiscoverySection _section(
  String id, {
  SeerrDiscoveryPriority priority = SeerrDiscoveryPriority.normal,
  int minItems = 1,
}) =>
    SeerrDiscoverySection(
      id: id,
      title: id,
      priority: priority,
      minItems: minItems,
      previewLimit: 2,
      query: const SeerrDiscoveryQuery(
        source: SeerrDiscoverySource.discoverMovies,
        mediaType: 'movie',
      ),
    );

SeerrDiscoverItem _item(int id) => SeerrDiscoverItem(
      id: id,
      mediaType: 'movie',
      title: 'Item $id',
    );

void main() {
  test('preserves session order while limiting concurrent lane fetches', () async {
    var inFlight = 0;
    var maxInFlight = 0;
    final loader = SeerrDiscoveryLaneLoader(
      fetchPage: (query, page) async {
        inFlight++;
        if (inFlight > maxInFlight) maxInFlight = inFlight;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        final base = query.filters['testId'] == null
            ? 1
            : int.parse(query.filters['testId']!);
        inFlight--;
        return SeerrDiscoverPage(
          page: 1,
          totalPages: 1,
          results: [_item(base), _item(base + 100)],
        );
      },
    );
    final tabLoader = SeerrDiscoveryTabLoader(
      laneLoader: loader,
      concurrency: 2,
    );
    final sections = List.generate(
      6,
      (index) => SeerrDiscoverySection(
        id: 's$index',
        title: 's$index',
        minItems: 1,
        previewLimit: 2,
        query: SeerrDiscoveryQuery(
          source: SeerrDiscoverySource.discoverMovies,
          mediaType: 'movie',
          filters: {'testId': '${index + 1}'},
        ),
      ),
    );

    final result = await tabLoader.load(sections);
    expect(maxInFlight, lessThanOrEqualTo(2));
    expect(
      result.rendered.map((entry) => entry.section.id),
      ['s0', 's1', 's2', 's3', 's4', 's5'],
    );
  });

  test('failed optional lane is omitted while a failed anchor remains retryable',
      () async {
    final anchor = _section(
      'anchor',
      priority: SeerrDiscoveryPriority.anchor,
    );
    final optional = _section('optional');
    final good = _section('good');

    var calls = 0;
    final loader = SeerrDiscoveryLaneLoader(
      fetchPage: (_, __) async {
        calls++;
        if (calls <= 2) throw StateError('lane failed');
        return SeerrDiscoverPage(
          page: 1,
          totalPages: 1,
          results: [_item(1)],
        );
      },
    );
    final result = await SeerrDiscoveryTabLoader(
      laneLoader: loader,
      concurrency: 1,
    ).load([anchor, optional, good]);

    expect(result.hasAnchorFailure, isTrue);
    expect(result.rendered.map((entry) => entry.section.id), ['anchor', 'good']);
    expect(result.failedOptional.map((entry) => entry.section.id), ['optional']);
  });

  test('successful shallow lane is classified separately from an error', () async {
    final shallow = _section('shallow', minItems: 2);
    final loader = SeerrDiscoveryLaneLoader(
      fetchPage: (_, __) async => SeerrDiscoverPage(
        page: 1,
        totalPages: 1,
        results: [_item(1)],
      ),
    );

    final result = await SeerrDiscoveryTabLoader(laneLoader: loader).load([shallow]);
    expect(result.rendered, isEmpty);
    expect(result.failedOptional, isEmpty);
    expect(result.hiddenShallow.single.section.id, 'shallow');
  });
}
