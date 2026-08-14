import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_session.dart';

void main() {
  test('shared tab scope suppresses repeats across different lane pools', () {
    final session = SeerrDiscoverySession();

    final first = session.filterFresh<int>(
      group: 'movies-genres',
      sharedGroup: 'tab:movies',
      items: [1, 2, 3, 4],
      identity: (item) => item.toString(),
      minimumRetained: 4,
    );
    expect(first, [1, 2, 3, 4]);

    final second = session.filterFresh<int>(
      group: 'movies-studios',
      sharedGroup: 'tab:movies',
      items: [1, 2, 5, 6, 7, 8],
      identity: (item) => item.toString(),
      minimumRetained: 4,
    );

    expect(second.take(4), [5, 6, 7, 8]);
    expect(session.hasSeen('movies-studios', '1'), isFalse);
    expect(session.hasSeen('tab:movies', '8'), isTrue);
  });

  test('dedup relaxes rather than returning a nearly empty row', () {
    final session = SeerrDiscoverySession();
    session.markSeen('old-lane', ['1', '2', '3'], sharedGroup: 'tab:movies');

    final output = session.filterFresh<int>(
      group: 'new-lane',
      sharedGroup: 'tab:movies',
      items: [1, 2, 3, 4],
      identity: (item) => item.toString(),
      minimumRetained: 3,
    );

    expect(output.first, 4);
    expect(output.length, 3);
  });

  test('expanded collection can ignore landing-page shared scope', () {
    final session = SeerrDiscoverySession();
    session.markSeen('preview', ['1', '2', '3'], sharedGroup: 'tab:movies');

    final expanded = session.filterFresh<int>(
      group: 'expanded:hidden-gems',
      items: [1, 2, 3, 4],
      identity: (item) => item.toString(),
      minimumRetained: 4,
      record: false,
    );

    expect(expanded, [1, 2, 3, 4]);
  });
}
