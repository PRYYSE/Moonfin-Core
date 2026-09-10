import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_quality.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_tab_controller.dart';

HomeLabDiscoverySection _section(String id, {int previewLimit = 3}) =>
    HomeLabDiscoverySection(
      id: id,
      title: id,
      minItems: 1,
      previewLimit: previewLimit,
      priority: HomeLabDiscoveryPriority.anchor,
      query: const HomeLabDiscoveryQuery(
        source: HomeLabDiscoverySource.discoverMovies,
        mediaType: 'movie',
      ),
    );

SeerrDiscoverItem _item(
  int id, {
  String title = 'Secret Title',
  String? posterPath,
  String? backdropPath,
  String? jellyfinMediaId,
}) => SeerrDiscoverItem(
  id: id,
  mediaType: 'movie',
  title: title,
  posterPath: posterPath,
  backdropPath: backdropPath,
  mediaInfo: jellyfinMediaId == null
      ? null
      : SeerrMediaInfo(tmdbId: id, status: 5, jellyfinMediaId: jellyfinMediaId),
);

void main() {
  test(
    'quality report mirrors aggregate parity metrics without media identity',
    () {
      final first = _section('first');
      final second = _section('second');
      final hidden = _section('hidden');
      final failed = _section('failed');

      final result = HomeLabDiscoveryTabLoadResult(
        selectedSections: [first, second, hidden, failed],
        lanes: [
          HomeLabDiscoveryLaneLoadResult(
            section: first,
            items: [
              _item(
                1,
                posterPath: '/one.jpg',
                backdropPath: '/one-bg.jpg',
                jellyfinMediaId: 'private-jellyfin-id',
              ),
              _item(2),
            ],
          ),
          HomeLabDiscoveryLaneLoadResult(
            section: second,
            items: [
              _item(2),
              _item(3, posterPath: '/three.jpg'),
            ],
          ),
          HomeLabDiscoveryLaneLoadResult(section: hidden),
          HomeLabDiscoveryLaneLoadResult(
            section: failed,
            error: StateError('temporary'),
          ),
        ],
        refreshFailure: StateError('refresh failed'),
      );

      final report = HomeLabDiscoveryQuality.analyse(result);

      expect(report.laneCount, 2);
      expect(report.totalCards, 4);
      expect(report.uniqueCards, 3);
      expect(report.repeatedCards, 1);
      expect(report.duplicateDistinctItems, 1);
      expect(report.duplicateRatio, 0.25);
      expect(report.missingIdentityCards, 0);
      expect(report.missingPosterCards, 2);
      expect(report.missingPosterRatio, 0.5);
      expect(report.missingBackdropCards, 3);
      expect(report.ownedCards, 1);
      expect(report.ownedRatio, 0.25);
      expect(report.underfilledLaneCount, 2);
      expect(report.hiddenLaneCount, 1);
      expect(report.failedLaneCount, 1);
      expect(report.refreshFailure, isTrue);
      expect(report.laneSummaries[1].repeatedFromEarlierLanes, 1);

      final serialised = report.toJson().toString();
      expect(serialised, isNot(contains('Secret Title')));
      expect(serialised, isNot(contains('private-jellyfin-id')));
      expect(serialised, isNot(contains('movie:1')));
    },
  );

  test('invalid item identity is counted but never serialised', () {
    final lane = _section('identity');
    final result = HomeLabDiscoveryTabLoadResult(
      selectedSections: [lane],
      lanes: [
        HomeLabDiscoveryLaneLoadResult(
          section: lane,
          items: [_item(0, title: 'Do Not Leak')],
        ),
      ],
    );

    final report = HomeLabDiscoveryQuality.analyse(result);
    expect(report.missingIdentityCards, 1);
    expect(report.uniqueCards, 0);
    expect(report.toJson().toString(), isNot(contains('Do Not Leak')));
  });
}
