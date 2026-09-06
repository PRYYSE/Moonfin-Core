import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_request_plan.dart';

void main() {
  test('movie plan forwards rich filters and moving dates safely', () {
    const query = HomeLabDiscoveryQuery(
      source: HomeLabDiscoverySource.discoverMovies,
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

    final plan = HomeLabDiscoveryRequestPlan.fromQuery(
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

  test('tv plan preserves provider and air-date filters', () {
    const query = HomeLabDiscoveryQuery(
      source: HomeLabDiscoverySource.discoverTv,
      mediaType: 'tv',
      filters: {
        'network': '213',
        'watchProviders': '8',
        'watchRegion': 'AU',
        'language': 'ko',
        'firstAirDateGte': r'$monthsAgo:6',
      },
    );

    final plan = HomeLabDiscoveryRequestPlan.fromQuery(
      query,
      now: DateTime(2026, 8, 14),
    )!;
    expect(plan.path, 'discover/tv');
    expect(plan.queryParameters['watchProviders'], '8');
    expect(plan.queryParameters['watchRegion'], 'AU');
    expect(plan.queryParameters['firstAirDateGte'], '2026-02-14');
  });

  test('unsafe sort falls back rather than being forwarded', () {
    const query = HomeLabDiscoveryQuery(
      source: HomeLabDiscoverySource.discoverMovies,
      mediaType: 'movie',
      sortBy: 'drop database',
    );
    final plan = HomeLabDiscoveryRequestPlan.fromQuery(query)!;
    expect(plan.queryParameters['sortBy'], 'popularity.desc');
  });

  test('semantic authoring names fail closed until server compilation', () {
    const query = HomeLabDiscoveryQuery(
      source: HomeLabDiscoverySource.discoverMovies,
      mediaType: 'movie',
      keywordNames: ['post-apocalyptic'],
    );
    expect(HomeLabDiscoveryRequestPlan.fromQuery(query), isNull);
  });

  test('non-raw personalised source does not produce a proxy plan', () {
    const query = HomeLabDiscoveryQuery(
      source: HomeLabDiscoverySource.personalised,
      mediaType: 'all',
      seedStrategy: 'favourites',
    );
    expect(HomeLabDiscoveryRequestPlan.fromQuery(query), isNull);
  });
}
