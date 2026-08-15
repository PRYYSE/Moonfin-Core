import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_personal_presentation.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

SeerrDiscoverItem _item(int id, String title) => SeerrDiscoverItem(
  id: id,
  mediaType: 'movie',
  title: title,
);

SeerrDiscoverySection _section(String id, String strategy, String title) =>
    SeerrDiscoverySection(
      id: id,
      title: title,
      minItems: 4,
      previewLimit: 15,
      query: SeerrDiscoveryQuery(
        source: SeerrDiscoverySource.personalised,
        mediaType: 'all',
        seedStrategy: strategy,
      ),
    );

void main() {
  test('specific generated Home title is preserved', () {
    final used = <String>{};
    final section = _section('history', 'recent-history', 'Because You Watched');
    expect(
      SeerrDiscoveryPersonalPresentation.displayTitle(
        section,
        'Because You Watched "Dune"',
        usedTitles: used,
      ),
      'Because You Watched "Dune"',
    );
  });

  test('duplicate generic Home titles become stable neutral unique labels', () {
    final used = <String>{};
    final first = _section('history', 'recent-history', 'Because You Watched');
    final second = _section('favourites', 'favourites', 'More Like Your Favourites');
    final third = _section('watchlist', 'watchlist', 'Inspired by Your Watchlist');

    expect(
      SeerrDiscoveryPersonalPresentation.displayTitle(
        first,
        'Top Picks For You',
        usedTitles: used,
      ),
      'Top Picks For You',
    );
    expect(
      SeerrDiscoveryPersonalPresentation.displayTitle(
        second,
        'Top Picks For You',
        usedTitles: used,
      ),
      'More Picks For You',
    );
    expect(
      SeerrDiscoveryPersonalPresentation.displayTitle(
        third,
        'Top Picks For You',
        usedTitles: used,
      ),
      'Picks Worth a Look',
    );
  });

  test('Demon Slayer cluster is capped before unrelated recommendations', () {
    final items = [
      _item(1, 'Demon Slayer: Mugen Train'),
      _item(2, 'Demon Slayer: Kimetsu no Yaiba'),
      _item(3, 'Demon Slayer - To the Swordsmith Village'),
      _item(4, 'Demon Slayer: Hashira Training'),
      _item(5, 'Demon Slayer: Infinity Castle'),
      _item(6, 'Fate/stay night: Heaven’s Feel'),
      _item(7, 'Wicked City'),
      _item(8, 'Perfect Blue'),
      _item(9, 'Akira'),
    ];

    final output = SeerrDiscoveryPersonalPresentation.diversifyPreview(
      items,
      minimumRetained: 4,
    );

    expect(
      output.where(
        (item) =>
            SeerrDiscoveryPersonalPresentation.familyKey(item.displayTitle) ==
            'demon slayer',
      ).length,
      2,
    );
    expect(output.map((item) => item.id), [1, 2, 6, 7, 8, 9]);
  });

  test('Mortal Kombat cluster is capped without making a sparse row', () {
    final items = [
      _item(1, 'Mortal Kombat'),
      _item(2, 'Mortal Kombat Legends: Scorpion’s Revenge'),
      _item(3, 'Mortal Kombat Legends: Battle of the Realms'),
      _item(4, 'Mortal Kombat Legends: Cage Match'),
      _item(5, 'Mortal Kombat: Annihilation'),
      _item(6, 'Street Fighter'),
    ];

    final output = SeerrDiscoveryPersonalPresentation.diversifyPreview(
      items,
      minimumRetained: 5,
    );

    expect(output.length, 5);
    expect(output.take(3).map((item) => item.id), [1, 2, 6]);
    expect(output.last.id, isIn([3, 4, 5]));
  });

  test('later For You rows prefer title families not used by earlier rows', () {
    final surfaced = <String>{};
    final first = SeerrDiscoveryPersonalPresentation.diversifyPreview(
      [
        _item(1, 'Demon Slayer: Mugen Train'),
        _item(2, 'Fate/stay night: Heaven’s Feel'),
        _item(3, 'Akira'),
        _item(4, 'Perfect Blue'),
      ],
      minimumRetained: 4,
      previouslySurfacedFamilies: surfaced,
    );
    expect(first.length, 4);

    final second = SeerrDiscoveryPersonalPresentation.diversifyPreview(
      [
        _item(10, 'Demon Slayer: Infinity Castle'),
        _item(11, 'Fate/stay night: Unlimited Blade Works'),
        _item(12, 'Mortal Kombat'),
        _item(13, 'Wicked City'),
        _item(14, 'Ghost in the Shell'),
        _item(15, 'Paprika'),
      ],
      minimumRetained: 4,
      previouslySurfacedFamilies: surfaced,
    );

    expect(second.take(4).map((item) => item.id), [12, 13, 14, 15]);
  });

  test('family key catches screenshot franchise clusters conservatively', () {
    expect(
      SeerrDiscoveryPersonalPresentation.familyKey(
        'Demon Slayer -Kimetsu no Yaiba- The Movie: Mugen Train',
      ),
      'demon slayer',
    );
    expect(
      SeerrDiscoveryPersonalPresentation.familyKey(
        'Mortal Kombat Legends: Cage Match',
      ),
      'mortal kombat',
    );
  });
}
