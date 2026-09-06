import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_composer.dart';

HomeLabDiscoverySection section(
  String id, {
  String pool = 'general',
  HomeLabDiscoveryPriority priority = HomeLabDiscoveryPriority.normal,
  double weight = 1,
  int cooldownSessions = 0,
}) => HomeLabDiscoverySection(
  id: id,
  title: id,
  pool: pool,
  priority: priority,
  weight: weight,
  cooldownSessions: cooldownSessions,
  query: const HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
);

void main() {
  const composer = HomeLabDiscoveryComposer();

  test('keeps anchors while selecting a bounded rotating subset', () {
    final tab = HomeLabDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 5,
      minimumLaneCount: 4,
      sections: [
        section('anchor-a', priority: HomeLabDiscoveryPriority.anchor),
        section('anchor-b', priority: HomeLabDiscoveryPriority.anchor),
        for (var i = 0; i < 10; i++) section('s$i'),
      ],
    );

    final result = composer.compose(tab, sessionSeed: 'user-day');
    expect(result.length, 5);
    expect(result.take(2).map((item) => item.id), ['anchor-a', 'anchor-b']);
    expect(result.map((item) => item.id).toSet().length, result.length);
  });

  test('large anchor sets expose deep pools inside the first screen', () {
    final tab = HomeLabDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 20,
      minimumLaneCount: 16,
      poolBudgets: const {
        'anchor': 10,
        'discovery': 2,
        'runtime': 2,
        'era': 2,
        'genre': 2,
        'theme': 2,
      },
      sections: [
        for (var i = 0; i < 10; i++)
          section(
            'anchor-$i',
            pool: 'anchor',
            priority: HomeLabDiscoveryPriority.anchor,
          ),
        for (final pool in ['discovery', 'runtime', 'era', 'genre', 'theme'])
          for (var i = 0; i < 3; i++) section('$pool-$i', pool: pool),
      ],
    );

    final result = composer.compose(tab, sessionSeed: 'layered');
    final firstTwelve = result.take(12).toList();
    final deepRows = firstTwelve.where((item) => !item.isAnchor).toList();
    final deepPools = deepRows.map((item) => item.pool).toSet();

    expect(result.take(3).every((item) => item.isAnchor), isTrue);
    expect(deepRows.length, greaterThanOrEqualTo(4));
    expect(deepPools.length, greaterThanOrEqualTo(4));
    expect(result.where((item) => item.isAnchor).length, 10);
  });

  test('same seed and nonce are deterministic', () {
    final tab = HomeLabDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 4,
      minimumLaneCount: 4,
      sections: [for (var i = 0; i < 10; i++) section('s$i')],
    );

    final first = composer.compose(tab, sessionSeed: 'user-day');
    final second = composer.compose(tab, sessionSeed: 'user-day');
    expect(second.map((item) => item.id), first.map((item) => item.id));
  });

  test('refresh nonce can change optional lane set', () {
    final tab = HomeLabDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 4,
      minimumLaneCount: 4,
      sections: [for (var i = 0; i < 10; i++) section('s$i')],
    );

    final first = composer.compose(tab, sessionSeed: 'user-day');
    final refreshed = composer.compose(
      tab,
      sessionSeed: 'user-day',
      refreshNonce: 2,
    );

    expect(
      refreshed.map((item) => item.id),
      isNot(equals(first.map((item) => item.id))),
    );
  });

  test('pool budgets prevent one category dominating normal fill', () {
    final tab = HomeLabDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 5,
      minimumLaneCount: 3,
      poolBudgets: const {'genre': 1},
      sections: [
        for (var i = 0; i < 5; i++) section('genre-$i', pool: 'genre'),
        for (var i = 0; i < 5; i++) section('era-$i', pool: 'era'),
      ],
    );

    final result = composer.compose(tab, sessionSeed: 'balanced');
    expect(
      result.where((item) => item.pool == 'genre').length,
      lessThanOrEqualTo(1),
    );
    expect(result.length, 5);
  });

  test('cooldown is honoured unless fallback is required', () {
    final tab = HomeLabDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 3,
      minimumLaneCount: 2,
      sections: [
        section('cooling', cooldownSessions: 3),
        section('fresh-a'),
        section('fresh-b'),
        section('fresh-c'),
      ],
    );

    final result = composer.compose(
      tab,
      sessionSeed: 'cooldown',
      sessionsSinceSeen: const {'cooling': 1},
    );
    expect(result.map((item) => item.id), isNot(contains('cooling')));
  });

  test('empty and fully filtered tabs fail closed without throwing', () {
    const empty = HomeLabDiscoveryTab(id: 'empty', title: 'Empty', sections: []);
    expect(composer.compose(empty, sessionSeed: 'x'), isEmpty);

    final filtered = HomeLabDiscoveryTab(
      id: 'filtered',
      title: 'Filtered',
      sections: [section('one'), section('two')],
    );
    expect(
      composer.compose(filtered, sessionSeed: 'x', isEligible: (_) => false),
      isEmpty,
    );
  });
}
