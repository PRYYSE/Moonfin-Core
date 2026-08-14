import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_request_plan.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

void main() {
  test('movie plan forwards rich current Seerr filters and moving dates', () {
    const query = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverMovies,
      mediaType: 'movie',
      sortBy: 'vote_average.desc',
      filters: {
        'genre': '878,53',
        'withRuntimeLte': '120',
        'voteAverageGte': '7.0',
        'voteCountGte': '250',
        'primaryReleaseDateGte': r'$yearsAgo:5',
        'notAllowed': 'drop-me',
      },
    );

    final plan = SeerrDiscoveryRequestPlan.fromQuery(
      query,
      page: 3,
      now: DateTime(2026, 8, 14),
    )!;

    expect(plan.path, 'discover/movies');
    expect(plan.queryParameters, {
      'page': 3,
      'sortBy': 'vote_average.desc',
      'genre': '878,53',
      'withRuntimeLte': '120',
      'voteAverageGte': '7.0',
      'voteCountGte': '250',
      'primaryReleaseDateGte': '2021-08-14',
    });
  });

  test('tv plan supports network provider language and air-date filters', () {
    const query = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverTv,
      mediaType: 'tv',
      filters: {
        'network': '213',
        'watchProviders': '8',
        'watchRegion': 'AU',
        'language': 'ko',
        'firstAirDateGte': r'$monthsAgo:6',
      },
    );

    final plan = SeerrDiscoveryRequestPlan.fromQuery(
      query,
      now: DateTime(2026, 8, 14),
    )!;
    expect(plan.path, 'discover/tv');
    expect(plan.queryParameters['page'], 1);
    expect(plan.queryParameters['network'], '213');
    expect(plan.queryParameters['watchProviders'], '8');
    expect(plan.queryParameters['watchRegion'], 'AU');
    expect(plan.queryParameters['language'], 'ko');
    expect(plan.queryParameters['firstAirDateGte'], '2026-02-14');
  });

  test('unsafe sort falls back instead of being forwarded', () {
    const query = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverMovies,
      mediaType: 'movie',
      sortBy: 'drop database',
    );
    final plan = SeerrDiscoveryRequestPlan.fromQuery(query)!;
    expect(plan.queryParameters['sortBy'], 'popularity.desc');
  });

  test('page is clamped and non-Seerr sources do not make raw plans', () {
    const trending = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.trending,
      mediaType: 'all',
    );
    expect(
      SeerrDiscoveryRequestPlan.fromQuery(trending, page: 0)!.queryParameters,
      {'page': 1},
    );

    const personal = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.personalised,
      mediaType: 'all',
      seedStrategy: 'favourites',
    );
    expect(SeerrDiscoveryRequestPlan.fromQuery(personal), isNull);
  });
}
