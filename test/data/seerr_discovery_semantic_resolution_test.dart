import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_request_plan.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

void main() {
  test('unresolved keyword authoring lane cannot run as a broad query', () {
    const query = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverTv,
      mediaType: 'tv',
      filters: {'genre': '16', 'language': 'ja'},
      keywordNames: ['isekai'],
    );
    expect(SeerrDiscoveryRequestPlan.fromQuery(query), isNull);
  });

  test('unresolved AU provider authoring lane cannot ignore provider constraint', () {
    const query = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverMovies,
      mediaType: 'movie',
      filters: {'watchRegion': 'AU'},
      providerNames: ['BINGE'],
    );
    expect(SeerrDiscoveryRequestPlan.fromQuery(query), isNull);
  });

  test('compiled keyword/provider IDs become executable normal filters', () {
    const query = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverTv,
      mediaType: 'tv',
      filters: {
        'genre': '16',
        'language': 'ja',
        'keywords': '210024',
        'watchProviders': '283',
        'watchRegion': 'AU',
      },
    );
    final plan = SeerrDiscoveryRequestPlan.fromQuery(query)!;
    expect(plan.queryParameters['keywords'], '210024');
    expect(plan.queryParameters['watchProviders'], '283');
    expect(plan.queryParameters['watchRegion'], 'AU');
  });
}
