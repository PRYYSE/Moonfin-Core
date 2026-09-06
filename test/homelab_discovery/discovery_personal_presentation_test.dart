import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_personal_presentation.dart';

HomeLabDiscoverySection section(String strategy, String title) =>
    HomeLabDiscoverySection(
      id: 'personal-$strategy',
      title: title,
      query: HomeLabDiscoveryQuery(
        source: HomeLabDiscoverySource.personalised,
        mediaType: 'all',
        seedStrategy: strategy,
      ),
    );

SeerrDiscoverItem item(int id, String title) =>
    SeerrDiscoverItem(id: id, mediaType: 'tv', name: title);

void main() {
  test('duplicate generic generated titles get stable distinct labels', () {
    final used = <String>{};
    final first = HomeLabDiscoveryPersonalPresentation.displayTitle(
      section('recent-history', 'Recent History'),
      'Top Picks For You',
      usedTitles: used,
    );
    final second = HomeLabDiscoveryPersonalPresentation.displayTitle(
      section('favourites', 'Favourites'),
      'Top Picks For You',
      usedTitles: used,
    );

    expect(first, 'Top Picks For You');
    expect(second, 'More Picks For You');
    expect(first, isNot(second));
  });

  test('Demon Slayer family is softly capped at two in preview', () {
    final result = HomeLabDiscoveryPersonalPresentation.diversifyPreview([
      item(1, 'Demon Slayer: Kimetsu no Yaiba'),
      item(2, 'Demon Slayer: Mugen Train'),
      item(3, 'Demon Slayer: Entertainment District'),
      item(4, 'Frieren: Beyond Journey’s End'),
      item(5, 'Vinland Saga'),
    ], minimumRetained: 4);

    expect(
      result
          .where(
            (value) =>
                HomeLabDiscoveryPersonalPresentation.familyKey(
                  value.displayTitle,
                ) ==
                'demon slayer',
          )
          .length,
      2,
    );
    expect(result.map((value) => value.id), containsAll([4, 5]));
  });

  test('Mortal Kombat clustering cannot crowd out unrelated titles', () {
    final result = HomeLabDiscoveryPersonalPresentation.diversifyPreview([
      item(1, 'Mortal Kombat'),
      item(2, 'Mortal Kombat Legends: Scorpion’s Revenge'),
      item(3, 'Mortal Kombat Legends: Snow Blind'),
      item(4, 'The Raid'),
      item(5, 'John Wick'),
    ], minimumRetained: 4);

    expect(
      result
          .where(
            (value) =>
                HomeLabDiscoveryPersonalPresentation.familyKey(
                  value.displayTitle,
                ) ==
                'mortal kombat',
          )
          .length,
      2,
    );
    expect(result.map((value) => value.id), containsAll([4, 5]));
  });

  test('earlier row families are deferred then backfilled only if needed', () {
    final earlier = {'demon slayer'};
    final result = HomeLabDiscoveryPersonalPresentation.diversifyPreview(
      [
        item(1, 'Demon Slayer: Mugen Train'),
        item(2, 'Pluto'),
        item(3, 'Monster'),
      ],
      minimumRetained: 2,
      previouslySurfacedFamilies: earlier,
    );

    expect(result.take(2).map((value) => value.id), [2, 3]);
  });

  test(
    'full ranking remains unchanged when presentation policy is bypassed',
    () {
      final full = [
        item(1, 'Demon Slayer: Kimetsu no Yaiba'),
        item(2, 'Demon Slayer: Mugen Train'),
        item(3, 'Demon Slayer: Entertainment District'),
      ];
      expect(full.map((value) => value.id), [1, 2, 3]);
    },
  );
}
