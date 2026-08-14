import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_sort_policy.dart';

void main() {
  test('accepts current Seerr vote-count and release-date sorts', () {
    expect(
      SeerrDiscoverySortPolicy.normalise('vote_count.desc'),
      'vote_count.desc',
    );
    expect(
      SeerrDiscoverySortPolicy.normalise('release_date.asc'),
      'release_date.asc',
    );
  });

  test('rejects older Moonfin name/title sorts not in current Seerr', () {
    expect(SeerrDiscoverySortPolicy.normalise('name.asc'), 'popularity.desc');
    expect(SeerrDiscoverySortPolicy.normalise('title.desc'), 'popularity.desc');
  });
}
