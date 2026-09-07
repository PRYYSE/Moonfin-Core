import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_rotation_history.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_rotation_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('rotation store round-trips per scope without media data', () async {
    final store = HomeLabDiscoveryRotationStore();
    final history = HomeLabDiscoveryRotationHistory()
      ..commitSession(['movies-theme-space'])
      ..commitSession(['movies-theme-heist']);

    await store.save('server|user', {'movies': history});
    final restored = await HomeLabDiscoveryRotationStore().load('server|user');

    expect(restored.keys.toList(), ['movies']);
    expect(restored['movies']!.sessionNumber, 2);
    expect(restored['movies']!.sessionsSinceSeen['movies-theme-space'], 1);
    expect(restored['movies']!.sessionsSinceSeen['movies-theme-heist'], 0);
  });

  test('different scopes cannot read each others rotation state', () async {
    final store = HomeLabDiscoveryRotationStore();
    final history = HomeLabDiscoveryRotationHistory()
      ..commitSession(['for-you-personal-1']);

    await store.save('server|user-a', {'for-you': history});

    expect(await store.load('server|user-b'), isEmpty);
  });
}
