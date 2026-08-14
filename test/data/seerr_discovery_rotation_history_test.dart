import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_rotation_history.dart';

void main() {
  test('tracks sessions since a lane was last shown', () {
    final history = SeerrDiscoveryRotationHistory();
    history.commitSession(['a', 'b']);
    expect(history.sessionsSinceSeen, {'a': 0, 'b': 0});

    history.commitSession(['c']);
    expect(history.sessionsSinceSeen['a'], 1);
    expect(history.sessionsSinceSeen['b'], 1);
    expect(history.sessionsSinceSeen['c'], 0);
  });

  test('round-trips without changing cooldown ages', () {
    final history = SeerrDiscoveryRotationHistory();
    history.commitSession(['a']);
    history.commitSession(['b']);
    history.commitSession(['c']);

    final restored = SeerrDiscoveryRotationHistory.fromJson(history.toJson());
    expect(restored.sessionNumber, history.sessionNumber);
    expect(restored.sessionsSinceSeen, history.sessionsSinceSeen);
  });

  test('trims oldest section ids to a bounded history', () {
    final history = SeerrDiscoveryRotationHistory(maxEntries: 2);
    history.commitSession(['oldest']);
    history.commitSession(['middle']);
    history.commitSession(['newest']);

    expect(history.sessionsSinceSeen.length, 2);
    expect(history.sessionsSinceSeen.containsKey('oldest'), isFalse);
    expect(history.sessionsSinceSeen.containsKey('middle'), isTrue);
    expect(history.sessionsSinceSeen.containsKey('newest'), isTrue);
  });

  test('clear removes rotation state', () {
    final history = SeerrDiscoveryRotationHistory();
    history.commitSession(['a']);
    history.clear();
    expect(history.sessionNumber, 0);
    expect(history.sessionsSinceSeen, isEmpty);
  });
}
