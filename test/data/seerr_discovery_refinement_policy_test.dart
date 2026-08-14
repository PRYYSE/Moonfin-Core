import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_refinement_policy.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

void main() {
  test('refinement adds new filters without dropping base constraints', () {
    const base = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverMovies,
      mediaType: 'movie',
      filters: {
        'voteAverageGte': '7.0',
        'voteCountGte': '150',
        'voteCountLte': '1500',
      },
    );

    final merged = SeerrDiscoveryRefinementPolicy.merge(base, {
      'genre': '27',
      'withRuntimeLte': '120',
    });

    expect(merged.filters, {
      'voteAverageGte': '7.0',
      'voteCountGte': '150',
      'voteCountLte': '1500',
      'genre': '27',
      'withRuntimeLte': '120',
    });
  });

  test('numeric refinement can tighten but not loosen base bounds', () {
    const base = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverMovies,
      mediaType: 'movie',
      filters: {
        'voteAverageGte': '7.0',
        'voteCountLte': '1500',
        'withRuntimeLte': '120',
      },
    );

    final merged = SeerrDiscoveryRefinementPolicy.merge(base, {
      'voteAverageGte': '6.0',
      'voteCountLte': '2000',
      'withRuntimeLte': '100',
    });

    expect(merged.filters['voteAverageGte'], '7.0');
    expect(merged.filters['voteCountLte'], '1500');
    expect(merged.filters['withRuntimeLte'], '100');
  });

  test(
    'genre refinement combines with a base genre instead of replacing it',
    () {
      const base = SeerrDiscoveryQuery(
        source: SeerrDiscoverySource.discoverMovies,
        mediaType: 'movie',
        filters: {'genre': '878'},
      );
      final merged = SeerrDiscoveryRefinementPolicy.merge(base, {
        'genre': '53',
      });
      expect(merged.filters['genre'], '878,53');
    },
  );

  test('exact base identity filters remain locked', () {
    const base = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverTv,
      mediaType: 'tv',
      filters: {
        'network': '213',
        'language': 'ko',
        'watchProviders': '8',
        'watchRegion': 'AU',
      },
    );

    final merged = SeerrDiscoveryRefinementPolicy.merge(base, {
      'network': '49',
      'language': 'en',
      'watchProviders': '337',
      'watchRegion': 'US',
    });

    expect(merged.filters['network'], '213');
    expect(merged.filters['language'], 'ko');
    expect(merged.filters['watchProviders'], '8');
    expect(merged.filters['watchRegion'], 'AU');
  });

  test('date refinements keep the narrower interval', () {
    const base = SeerrDiscoveryQuery(
      source: SeerrDiscoverySource.discoverTv,
      mediaType: 'tv',
      filters: {
        'firstAirDateGte': '2020-01-01',
        'firstAirDateLte': '2026-12-31',
      },
    );

    final merged = SeerrDiscoveryRefinementPolicy.merge(base, {
      'firstAirDateGte': '2023-01-01',
      'firstAirDateLte': '2025-12-31',
    });
    expect(merged.filters['firstAirDateGte'], '2023-01-01');
    expect(merged.filters['firstAirDateLte'], '2025-12-31');
  });
}
