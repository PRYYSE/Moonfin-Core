import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_route_codec.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

void main() {
  test('compiled preview query round-trips unchanged into expanded route', () {
    const query = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverMovies,
      mediaType: 'movie',
      sortBy: 'vote_average.desc',
      filters: {
        'genre': '878,53',
        'voteAverageGte': '7.0',
        'voteCountGte': '150',
        'voteCountLte': '1500',
        'keywords': '123,456',
        'watchProviders': '8|337',
        'watchRegion': 'AU',
      },
    );

    final encoded = SeerrDiscoveryRouteCodec.encode(
      query,
      title: 'Hidden Sci-Fi Gems',
    );
    final decoded = SeerrDiscoveryRouteCodec.decode(encoded);

    expect(decoded.title, 'Hidden Sci-Fi Gems');
    expect(decoded.query.cacheKey, query.cacheKey);
  });

  test(
    'route decoder ignores arbitrary non-q and unsupported q parameters',
    () {
      final decoded = SeerrDiscoveryRouteCodec.decode({
        'source': 'discoverTv',
        'mediaType': 'tv',
        'sortBy': 'vote_average.desc',
        'filterName': 'Safe',
        'apiKey': 'must-not-pass',
        'q.genre': '80',
        'q.apiKey': 'must-not-pass',
        'q.notARealFilter': 'drop-me',
      });

      expect(decoded.query.filters, {'genre': '80'});
    },
  );

  test('moving route dates are resolved on decode', () {
    final decoded = SeerrDiscoveryRouteCodec.decode({
      'source': 'discoverTv',
      'mediaType': 'tv',
      'q.firstAirDateGte': r'$monthsAgo:3',
    }, now: DateTime(2026, 8, 14));
    expect(decoded.query.filters['firstAirDateGte'], '2026-05-14');
  });

  test('invalid source and sort fail to safe defaults', () {
    final decoded = SeerrDiscoveryRouteCodec.decode({
      'source': 'unknown',
      'sortBy': 'malicious-sort',
    });
    expect(decoded.query.source, SeerrDiscoverySource.discoverMovies);
    expect(decoded.query.mediaType, 'movie');
    expect(decoded.query.sortBy, 'popularity.desc');
  });
}
