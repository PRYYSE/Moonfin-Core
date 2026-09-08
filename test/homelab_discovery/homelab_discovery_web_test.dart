import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_adaptive_layout.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_media_card.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_tab_strip.dart';
import 'package:moonfin/ui/navigation/destinations.dart';

const webTabs = [
  HomeLabDiscoveryTab(id: 'movies', title: 'Movies', sections: []),
  HomeLabDiscoveryTab(id: 'series', title: 'Series', sections: []),
  HomeLabDiscoveryTab(id: 'anime', title: 'Anime', sections: []),
];

Widget tabHarness() {
  return MaterialApp(
    home: DefaultTabController(
      length: webTabs.length,
      child: const Scaffold(
        body: Column(
          children: [
            HomeLabDiscoveryTabStrip(tabs: webTabs),
            Expanded(
              child: TabBarView(
                children: [
                  Center(child: Text('MOVIES BODY')),
                  Center(child: Text('SERIES BODY')),
                  Center(child: Text('ANIME BODY')),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget cardHarness(VoidCallback onTap) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: HomeLabDiscoveryMediaCard(
          autofocus: true,
          width: 150,
          onTap: onTap,
          item: const SeerrDiscoverItem(id: 123, mediaType: 'tv', name: ''),
        ),
      ),
    ),
  );
}

void main() {
  test('adaptive Web grid keeps useful card density on wide displays', () {
    expect(homeLabDiscoveryLaneCardWidth(480), 124);
    expect(homeLabDiscoveryLaneCardWidth(1280), 148);
    expect(homeLabDiscoveryGridColumns(320), 2);
    expect(homeLabDiscoveryGridColumns(1536), greaterThanOrEqualTo(9));
    expect(homeLabDiscoveryGridColumns(3840), 20);
    expect(homeLabDiscoveryGridColumns(double.infinity), 2);
  });

  test(
    'owned Discovery item routes to Jellyfin while external stays Seerr',
    () {
      const owned = SeerrDiscoverItem(
        id: 44,
        mediaType: 'movie',
        title: 'Owned',
        mediaInfo: SeerrMediaInfo(jellyfinMediaId: 'jf-44', status: 5),
      );
      const external = SeerrDiscoverItem(
        id: 45,
        mediaType: 'tv',
        name: 'External',
      );
      const malformedLocal = SeerrDiscoverItem(
        id: 46,
        mediaType: 'movie',
        title: 'Malformed local pointer',
        mediaInfo: SeerrMediaInfo(jellyfinMediaId: ' null ', status: 5),
      );

      expect(homeLabDiscoveryItemLocation(owned), Destinations.item('jf-44'));
      expect(
        homeLabDiscoveryItemLocation(external),
        Destinations.seerrMedia('45', mediaType: 'tv'),
      );
      expect(
        homeLabDiscoveryItemLocation(malformedLocal),
        Destinations.seerrMedia('46', mediaType: 'movie'),
      );
    },
  );

  testWidgets('Web tab strip accepts touch, mouse and keyboard selection', (
    tester,
  ) async {
    await tester.pumpWidget(tabHarness());
    await tester.pumpAndSettle();
    expect(find.text('MOVIES BODY'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(find.text('ANIME BODY'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(find.text('MOVIES BODY'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('homelab-discovery-tab-series')),
    );
    await tester.pumpAndSettle();
    expect(find.text('SERIES BODY'), findsOneWidget);

    final animeFinder = find.byKey(
      const ValueKey<String>('homelab-discovery-tab-anime'),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final animeCenter = tester.getCenter(animeFinder);
    await mouse.addPointer(location: animeCenter);
    await mouse.down(animeCenter);
    await mouse.up();
    await tester.pumpAndSettle();
    expect(find.text('ANIME BODY'), findsOneWidget);
    await mouse.removePointer();
  }, skip: !kIsWeb);

  testWidgets(
    'Web media card accepts touch, mouse and keyboard and falls back without art',
    (tester) async {
      var activations = 0;
      await tester.pumpWidget(cardHarness(() => activations++));
      await tester.pumpAndSettle();

      expect(find.text('Untitled'), findsOneWidget);
      expect(find.text('UNTITLED'), findsOneWidget);

      final cardFinder = find.byType(HomeLabDiscoveryMediaCard);
      await tester.tap(cardFinder);
      await tester.pump();
      expect(activations, 1);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      final center = tester.getCenter(cardFinder);
      await mouse.addPointer(location: center);
      await mouse.down(center);
      await mouse.up();
      await tester.pump();
      expect(activations, 2);
      await mouse.removePointer();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(activations, 3);
    },
    skip: !kIsWeb,
  );
}
