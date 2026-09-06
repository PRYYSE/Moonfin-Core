import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_session.dart';

void main() {
  test('prefers unseen items across lane and shared tab scopes', () {
    final session = HomeLabDiscoverySession();
    session.markSeen('first', ['movie:1', 'movie:2'], sharedGroup: 'tab:movies');

    final result = session.filterFresh<int>(
      group: 'second',
      sharedGroup: 'tab:movies',
      items: [1, 2, 3, 4],
      identity: (id) => 'movie:$id',
      minimumRetained: 2,
    );

    expect(result, [3, 4]);
    expect(session.hasSeen('tab:movies', 'movie:4'), isTrue);
  });

  test('backfills repeats when novelty would make a row too sparse', () {
    final session = HomeLabDiscoverySession();
    session.markSeen('tab', ['1', '2', '3']);

    final result = session.filterFresh<int>(
      group: 'tab',
      items: [1, 2, 3, 4],
      identity: (id) => '$id',
      minimumRetained: 3,
    );

    expect(result, [4, 1, 2]);
  });

  test('record false leaves session state unchanged', () {
    final session = HomeLabDiscoverySession();
    final result = session.filterFresh<int>(
      group: 'preview',
      items: [1, 2],
      identity: (id) => '$id',
      record: false,
    );

    expect(result, [1, 2]);
    expect(session.counts, isEmpty);
  });
}
