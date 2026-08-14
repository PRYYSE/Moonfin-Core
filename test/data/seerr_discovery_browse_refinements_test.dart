import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_browse_refinements.dart';

void main() {
  test('movie refinements compile to current Seerr discover filters', () {
    const refinements = SeerrDiscoveryBrowseRefinements(
      genreIds: {878, 53},
      yearFrom: 2015,
      yearTo: 2026,
      minimumRating: 7.5,
      minimumVotes: 500,
      runtimeMin: 80,
      runtimeMax: 140,
      originalLanguage: 'en',
    );

    expect(refinements.toFilters('movie'), {
      'genre': '53,878',
      'primaryReleaseDateGte': '2015-01-01',
      'primaryReleaseDateLte': '2026-12-31',
      'voteAverageGte': '7.5',
      'voteCountGte': '500',
      'withRuntimeGte': '80',
      'withRuntimeLte': '140',
      'language': 'en',
    });
    expect(refinements.activeCount, 6);
    expect(refinements.isEmpty, isFalse);
  });

  test('tv refinements use first-air date keys', () {
    const refinements = SeerrDiscoveryBrowseRefinements(
      yearFrom: 2020,
      yearTo: 2024,
      genreIds: {80, 9648},
    );
    expect(refinements.toFilters('tv'), {
      'genre': '80,9648',
      'firstAirDateGte': '2020-01-01',
      'firstAirDateLte': '2024-12-31',
    });
  });

  test('empty/default refinements do not add accidental constraints', () {
    const refinements = SeerrDiscoveryBrowseRefinements(
      minimumRating: 0,
      minimumVotes: 0,
      runtimeMin: 0,
      originalLanguage: ' ',
    );
    expect(refinements.toFilters('movie'), isEmpty);
    expect(refinements.isEmpty, isTrue);
    expect(refinements.activeCount, 0);
  });

  test('copyWith can clear independent refinement groups', () {
    const initial = SeerrDiscoveryBrowseRefinements(
      genreIds: {28},
      yearFrom: 2010,
      yearTo: 2020,
      minimumRating: 7,
      minimumVotes: 100,
      runtimeMin: 90,
      runtimeMax: 120,
      originalLanguage: 'ko',
    );

    final cleared = initial.copyWith(
      clearYearFrom: true,
      clearYearTo: true,
      clearMinimumRating: true,
      clearOriginalLanguage: true,
    );
    expect(cleared.yearFrom, isNull);
    expect(cleared.yearTo, isNull);
    expect(cleared.minimumRating, isNull);
    expect(cleared.originalLanguage, isNull);
    expect(cleared.minimumVotes, 100);
    expect(cleared.runtimeMin, 90);
    expect(cleared.genreIds, {28});
  });

  test('taxonomy keeps Movie and TV genre IDs distinct where upstream does', () {
    expect(
      SeerrDiscoveryBrowseTaxonomy.movieGenres
          .firstWhere((genre) => genre.label == 'Action')
          .id,
      28,
    );
    expect(
      SeerrDiscoveryBrowseTaxonomy.tvGenres
          .firstWhere((genre) => genre.label == 'Action & Adventure')
          .id,
      10759,
    );
    expect(
      SeerrDiscoveryBrowseTaxonomy.languages
          .firstWhere((entry) => entry.key == 'ja')
          .value,
      'Japanese',
    );
  });
}
