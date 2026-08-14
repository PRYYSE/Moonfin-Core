import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_recommendation_mixer.dart';

SeerrDiscoverItem _item(int id, {String mediaType = 'movie'}) =>
    SeerrDiscoverItem(
      id: id,
      title: 'Item $id',
      mediaType: mediaType,
    );

void main() {
  test('round robin prevents one seed monopolising the result', () {
    final output = SeerrDiscoveryRecommendationMixer.mix(
      limit: 6,
      seeds: [
        SeerrDiscoverySeedResults(
          seedId: 'favourite-a',
          weight: 2,
          items: [_item(1), _item(2), _item(3), _item(4)],
        ),
        SeerrDiscoverySeedResults(
          seedId: 'recent-b',
          items: [_item(10), _item(11), _item(12)],
        ),
        SeerrDiscoverySeedResults(
          seedId: 'watchlist-c',
          items: [_item(20), _item(21), _item(22)],
        ),
      ],
    );

    expect(output.map((item) => item.id), [1, 10, 20, 2, 11, 21]);
  });

  test('duplicate recommendation from several seeds appears once', () {
    final output = SeerrDiscoveryRecommendationMixer.mix(
      limit: 5,
      seeds: [
        SeerrDiscoverySeedResults(
          seedId: 'a',
          items: [_item(1), _item(2), _item(3)],
        ),
        SeerrDiscoverySeedResults(
          seedId: 'b',
          items: [_item(1), _item(4), _item(5)],
        ),
      ],
    );

    expect(output.map((item) => item.id).toSet().length, output.length);
    expect(output.where((item) => item.id == 1).length, 1);
  });

  test('recently surfaced items are deferred behind fresh alternatives', () {
    final output = SeerrDiscoveryRecommendationMixer.mix(
      limit: 4,
      recentlySurfaced: const {'movie:1', 'movie:10'},
      seeds: [
        SeerrDiscoverySeedResults(
          seedId: 'a',
          items: [_item(1), _item(2), _item(3)],
        ),
        SeerrDiscoverySeedResults(
          seedId: 'b',
          items: [_item(10), _item(11), _item(12)],
        ),
      ],
    );

    expect(output.take(4).map((item) => item.id), [2, 11, 3, 12]);
  });

  test('recent candidates can return as fallback when fresh pool is sparse', () {
    final output = SeerrDiscoveryRecommendationMixer.mix(
      limit: 3,
      recentlySurfaced: const {'movie:1', 'movie:2'},
      seeds: [
        SeerrDiscoverySeedResults(
          seedId: 'a',
          items: [_item(1), _item(3)],
        ),
        SeerrDiscoverySeedResults(
          seedId: 'b',
          items: [_item(2)],
        ),
      ],
    );

    expect(output.first.id, 3);
    expect(output.length, 3);
    expect(output.map((item) => item.id).toSet(), {1, 2, 3});
  });

  test('media-type lane drops clearly mismatched mixed results', () {
    final output = SeerrDiscoveryRecommendationMixer.mix(
      limit: 4,
      mediaType: 'tv',
      seeds: [
        SeerrDiscoverySeedResults(
          seedId: 'mixed',
          items: [
            _item(1, mediaType: 'movie'),
            _item(2, mediaType: 'tv'),
            _item(3, mediaType: 'tv'),
          ],
        ),
      ],
    );

    expect(output.map((item) => item.id), [2, 3]);
  });
}
