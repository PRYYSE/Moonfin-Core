import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/home_lab_discovery_catalogue.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_session.dart';

void main() {
  group('SeerrDiscoveryCatalogue', () {
    test('Home Lab fallback catalogue is valid and has unique sections', () {
      expect(() => homeLabDiscoveryCatalogue.validate(), returnsNormally);
      final sections = homeLabDiscoveryCatalogue.allSections.toList();
      expect(sections.length, greaterThanOrEqualTo(30));
      expect(sections.map((section) => section.id).toSet().length, sections.length);
    });

    test('round-trips without changing exact section query identity', () {
      final restored = SeerrDiscoveryCatalogue.fromJson(
        homeLabDiscoveryCatalogue.toJson(),
      );
      restored.validate();

      final original = {
        for (final section in homeLabDiscoveryCatalogue.allSections)
          section.id: section.query.cacheKey,
      };
      final decoded = {
        for (final section in restored.allSections)
          section.id: section.query.cacheKey,
      };
      expect(decoded, original);
    });

    test('expanded route carries the exact preview filter', () {
      const query = SeerrDiscoveryQuery(
        source: SeerrDiscoverySource.discoverMovies,
        mediaType: 'movie',
        sortBy: 'vote_average.desc',
        filters: {
          'voteAverageGte': '7.0',
          'voteCountGte': '150',
          'voteCountLte': '1500',
        },
      );

      expect(query.toRouteParameters(title: 'Hidden Gems'), {
        'source': 'discoverMovies',
        'mediaType': 'movie',
        'sortBy': 'vote_average.desc',
        'filterName': 'Hidden Gems',
        'q.voteAverageGte': '7.0',
        'q.voteCountGte': '150',
        'q.voteCountLte': '1500',
      });
    });
  });

  group('SeerrDiscoverySession', () {
    test('prefers unseen content while retaining a usable row', () {
      final session = SeerrDiscoverySession();
      session.markSeen('movies', ['1', '2', '3']);

      final output = session.filterFresh<int>(
        group: 'movies',
        items: [1, 2, 3, 4, 5, 6, 7],
        identity: (item) => item.toString(),
        minimumRetained: 6,
      );

      expect(output.take(4), [4, 5, 6, 7]);
      expect(output.length, 6);
      expect(session.hasSeen('movies', '7'), isTrue);
    });

    test('dedup groups are independent', () {
      final session = SeerrDiscoverySession();
      session.markSeen('movies-main', ['100']);

      expect(session.hasSeen('movies-main', '100'), isTrue);
      expect(session.hasSeen('anime-main', '100'), isFalse);
    });
  });
}
