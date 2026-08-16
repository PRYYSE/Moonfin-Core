import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_composer.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

SeerrDiscoverySection _section(
  String id, {
  String pool = 'general',
  SeerrDiscoveryPriority priority = SeerrDiscoveryPriority.normal,
  double weight = 1,
  int cooldownSessions = 0,
}) => SeerrDiscoverySection(
  id: id,
  title: id,
  pool: pool,
  priority: priority,
  weight: weight,
  cooldownSessions: cooldownSessions,
  query: const SeerrDiscoveryQuery(
    source: SeerrDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
);

void main() {
  const composer = SeerrDiscoveryComposer();

  test('keeps anchors while selecting a bounded rotating subset', () {
    final tab = SeerrDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 5,
      minimumLaneCount: 4,
      sections: [
        _section('anchor-a', priority: SeerrDiscoveryPriority.anchor),
        _section('anchor-b', priority: SeerrDiscoveryPriority.anchor),
        for (var i = 0; i < 10; i++) _section('s$i'),
      ],
    );

    final result = composer.compose(tab, sessionSeed: 'user-day');
    expect(result.length, 5);
    expect(result.take(2).map((s) => s.id), ['anchor-a', 'anchor-b']);
    expect(result.map((s) => s.id).toSet().length, result.length);
  });

  test('large anchor sets expose deep pools inside the first screen', () {
    final tab = SeerrDiscoveryTab(
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
          _section(
            'anchor-$i',
            pool: 'anchor',
            priority: SeerrDiscoveryPriority.anchor,
          ),
        for (final pool in ['discovery', 'runtime', 'era', 'genre', 'theme'])
          for (var i = 0; i < 3; i++) _section('$pool-$i', pool: pool),
      ],
    );

    final result = composer.compose(tab, sessionSeed: 'layered');
    final firstTwelve = result.take(12).toList();

    expect(result.take(3).every((s) => s.isAnchor), isTrue);
    expect(firstTwelve.where((s) => !s.isAnchor).length, greaterThanOrEqualTo(4));
    expect(
      firstTwelve.where((s) => !s.isAnchor).map((s) => s.pool).toSet().length,
      greaterThanOrEqualTo(4),
    );
    expect(result.where((s) => s.isAnchor).length, 10);
  });

  test('same session seed and nonce produce stable composition', () {
    final tab = SeerrDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 4,
      minimumLaneCount: 4,
      sections: [for (var i = 0; i < 10; i++) _section('s$i')],
    );

    final first = composer.compose(tab, sessionSeed: 'user-day');
    final second = composer.compose(tab, sessionSeed: 'user-day');
    expect(second.map((s) => s.id), first.map((s) => s.id));
  });

  test('refresh nonce can materially change the optional lane set', () {
    final tab = SeerrDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 4,
      minimumLaneCount: 4,
      sections: [for (var i = 0; i < 10; i++) _section('s$i')],
    );

    final first = composer.compose(
      tab,
      sessionSeed: 'user-day',
      refreshNonce: 0,
    );
    final refreshed = composer.compose(
      tab,
      sessionSeed: 'user-day',
      refreshNonce: 2,
    );

    expect(refreshed.map((s) => s.id), isNot(equals(first.map((s) => s.id))));
  });

  test('pool budgets prevent one category dominating a normal pass', () {
    final tab = SeerrDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      initialLaneBudget: 5,
      minimumLaneCount: 3,
      poolBudgets: const {'genre': 1},
      sections: [
        for (var i = 0; i < 5; i++) _section('genre-$i', pool: 'genre'),
        for (var i = 0; i < 5; i++) _section('era-$i', pool: 'era'),
      ],
    );

    final result = composer.compose(tab, sessionSeed: 'balanced');
    expect(result.where((s) => s.pool == 'genre').length, lessThanOrEqualTo(1));
    expect(result.length, 5);
  });

  test(
    'cooldown is honoured unless minimum lane count requires a fallback',
    () {
      final tab = SeerrDiscoveryTab(
        id: 'movies',
        title: 'Movies',
        initialLaneBudget: 3,
        minimumLaneCount: 2,
        sections: [
          _section('cooling', cooldownSessions: 3),
          _section('fresh-a'),
          _section('fresh-b'),
          _section('fresh-c'),
        ],
      );

      final result = composer.compose(
        tab,
        sessionSeed: 'cooldown',
        sessionsSinceSeen: const {'cooling': 1},
      );

      expect(result.map((s) => s.id), isNot(contains('cooling')));
    },
  );

  test('empty and condition-filtered tabs fail closed without throwing', () {
    const empty = SeerrDiscoveryTab(id: 'empty', title: 'Empty', sections: []);
    expect(composer.compose(empty, sessionSeed: 'x'), isEmpty);

    final filtered = SeerrDiscoveryTab(
      id: 'filtered',
      title: 'Filtered',
      sections: [_section('one'), _section('two')],
    );
    expect(
      composer.compose(filtered, sessionSeed: 'x', isEligible: (_) => false),
      isEmpty,
    );
  });
}
