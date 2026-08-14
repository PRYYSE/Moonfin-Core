import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_rotation_history.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_rotation_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('empty scope starts with no rotation history', () async {
    final store = SeerrDiscoveryRotationStore();
    expect(await store.load('server|user-a'), isEmpty);
  });

  test('round-trips per-tab cooldown history', () async {
    final store = SeerrDiscoveryRotationStore();
    final movies = SeerrDiscoveryRotationHistory();
    movies.commitSession(['movies-hidden-gems', 'movies-horror']);
    movies.commitSession(['movies-sci-fi']);
    final anime = SeerrDiscoveryRotationHistory();
    anime.commitSession(['anime-isekai']);

    await store.save('server|user-a', {
      'movies': movies,
      'anime': anime,
    });
    final restored = await store.load('server|user-a');

    expect(restored.keys.toSet(), {'movies', 'anime'});
    expect(restored['movies']!.sessionNumber, movies.sessionNumber);
    expect(restored['movies']!.sessionsSinceSeen, movies.sessionsSinceSeen);
    expect(restored['anime']!.sessionsSinceSeen, anime.sessionsSinceSeen);
  });

  test('different user scopes never share lane cooldown state', () async {
    final store = SeerrDiscoveryRotationStore();
    final history = SeerrDiscoveryRotationHistory();
    history.commitSession(['movies-hidden-gems']);

    await store.save('server|user-a', {'movies': history});

    expect((await store.load('server|user-a'))['movies'], isNotNull);
    expect(await store.load('server|user-b'), isEmpty);
  });

  test('corrupt local novelty data fails open and is discarded', () async {
    final store = SeerrDiscoveryRotationStore();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'moonfin.discovery.rotation.v1.c2VydmVyfHVzZXItYQ',
      '{broken json',
    );

    expect(await store.load('server|user-a'), isEmpty);
    expect(preferences.getKeys(), isEmpty);
  });

  test('clear removes only the selected user scope', () async {
    final store = SeerrDiscoveryRotationStore();
    final a = SeerrDiscoveryRotationHistory()..commitSession(['a']);
    final b = SeerrDiscoveryRotationHistory()..commitSession(['b']);
    await store.save('server|user-a', {'movies': a});
    await store.save('server|user-b', {'movies': b});

    await store.clear('server|user-a');

    expect(await store.load('server|user-a'), isEmpty);
    expect((await store.load('server|user-b'))['movies'], isNotNull);
  });
}
