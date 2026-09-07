import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_rotation_history.dart';

void main() {
  test('rotation age survives serialisation and advances by session', () {
    final history = HomeLabDiscoveryRotationHistory();
    history.commitSession(['first']);
    history.commitSession(['second']);

    expect(history.sessionNumber, 2);
    expect(history.sessionsSinceSeen['first'], 1);
    expect(history.sessionsSinceSeen['second'], 0);

    final restored = HomeLabDiscoveryRotationHistory.fromJson(history.toJson());
    expect(restored.sessionNumber, 2);
    expect(restored.sessionsSinceSeen, history.sessionsSinceSeen);
  });

  test('rotation history trims oldest section entries', () {
    final history = HomeLabDiscoveryRotationHistory(maxEntries: 2);
    history.commitSession(['first']);
    history.commitSession(['second']);
    history.commitSession(['third']);

    expect(history.sessionsSinceSeen.keys, containsAll(['second', 'third']));
    expect(history.sessionsSinceSeen.containsKey('first'), isFalse);
  });

  test('clear creates a genuinely fresh rotation session', () {
    final history = HomeLabDiscoveryRotationHistory()..commitSession(['first']);
    history.clear();

    expect(history.sessionNumber, 0);
    expect(history.sessionsSinceSeen, isEmpty);
  });
}
