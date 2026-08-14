import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/models/aggregated_item.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/data/services/seerr/seerr_detail_discovery_adapter.dart';
import 'package:moonfin/data/viewmodels/seerr_media_detail_view_model.dart';

SeerrDiscoverItem _discover(
  int id, {
  String mediaType = 'movie',
  bool adult = false,
  int? status,
}) =>
    SeerrDiscoverItem(
      id: id,
      mediaType: mediaType,
      title: 'Title $id',
      posterPath: '/$id.jpg',
      overview: 'Overview $id',
      voteAverage: 7.5,
      adult: adult,
      mediaInfo: status == null ? null : SeerrMediaInfo(status: status),
    );

SeerrMediaDetailState _movieState({
  List<SeerrDiscoverItem> recommendations = const [],
  List<SeerrDiscoverItem> similar = const [],
}) =>
    SeerrMediaDetailState(
      movie: const SeerrMovieDetails(id: 100, title: 'Current'),
      recommendations: recommendations,
      similar: similar,
    );

void main() {
  test('interleaves recommendations and similar into native TMDb items', () {
    final output = SeerrDetailDiscoveryAdapter.mergeIntoExisting(
      existing: const [],
      state: _movieState(
        recommendations: [_discover(1), _discover(2), _discover(3)],
        similar: [_discover(10), _discover(11), _discover(12)],
      ),
      blockNsfw: true,
      limit: 6,
    );

    expect(output.map((item) => item.id), [
      'tmdb:movie:1',
      'tmdb:movie:10',
      'tmdb:movie:2',
      'tmdb:movie:11',
      'tmdb:movie:3',
      'tmdb:movie:12',
    ]);
    expect(output.first.serverId, 'seerr');
    expect(output.first.type, 'Movie');
    expect(output.first.tmdbId, '1');
  });

  test('deduplicates upstream overlap and excludes the current title', () {
    final output = SeerrDetailDiscoveryAdapter.mergeIntoExisting(
      existing: const [],
      state: _movieState(
        recommendations: [_discover(1), _discover(100), _discover(2)],
        similar: [_discover(1), _discover(3), _discover(100)],
      ),
      blockNsfw: false,
    );

    expect(output.map((item) => item.tmdbId).toSet(), {'1', '2', '3'});
    expect(output.where((item) => item.tmdbId == '1').length, 1);
    expect(output.where((item) => item.tmdbId == '100'), isEmpty);
  });

  test('preserves existing local items first and suppresses TMDb duplicates', () {
    final existing = AggregatedItem(
      id: 'jellyfin-local-1',
      serverId: 'server-a',
      rawData: const {
        'Name': 'Owned title',
        'Type': 'Movie',
        'ProviderIds': {'Tmdb': '1'},
      },
    );
    final output = SeerrDetailDiscoveryAdapter.mergeIntoExisting(
      existing: [existing],
      state: _movieState(
        recommendations: [_discover(1), _discover(2)],
        similar: [_discover(3)],
      ),
      blockNsfw: false,
    );

    expect(output.first.id, 'jellyfin-local-1');
    expect(output.where((item) => item.tmdbId == '1').length, 1);
    expect(output.map((item) => item.tmdbId), ['1', '2', '3']);
  });

  test('honours NSFW and Seerr blacklist state', () {
    final output = SeerrDetailDiscoveryAdapter.mergeIntoExisting(
      existing: const [],
      state: _movieState(
        recommendations: [
          _discover(1, adult: true),
          _discover(2, status: 6),
          _discover(3),
        ],
      ),
      blockNsfw: true,
    );

    expect(output.map((item) => item.tmdbId), ['3']);
  });

  test('TV recommendations retain TV route/type when mediaType is implicit', () {
    final state = SeerrMediaDetailState(
      tv: const SeerrTvDetails(id: 200, name: 'Current Series'),
      recommendations: [
        const SeerrDiscoverItem(id: 201, title: 'Recommended Series'),
      ],
    );
    final output = SeerrDetailDiscoveryAdapter.mergeIntoExisting(
      existing: const [],
      state: state,
      blockNsfw: false,
    );

    expect(output.single.id, 'tmdb:tv:201');
    expect(output.single.type, 'Series');
    expect(output.single.rawData['SeerrMediaType'], 'tv');
  });
}
