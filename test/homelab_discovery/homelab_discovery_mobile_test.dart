import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_adaptive_layout.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_media_card.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_tab_strip.dart';
import 'package:moonfin/l10n/app_localizations.dart';

const mobileTabs = [
  HomeLabDiscoveryTab(id: 'movies', title: 'Movies', sections: []),
  HomeLabDiscoveryTab(id: 'series', title: 'Series', sections: []),
  HomeLabDiscoveryTab(id: 'anime', title: 'Anime', sections: []),
];

Widget mobileTabHarness() {
  return MaterialApp(
    home: DefaultTabController(
      length: mobileTabs.length,
      child: const Scaffold(
        body: Column(
          children: [
            HomeLabDiscoveryTabStrip(tabs: mobileTabs),
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

Widget mobileCardHarness(VoidCallback onTap) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: HomeLabDiscoveryMediaCard(
          width: 124,
          onTap: onTap,
          item: const SeerrDiscoverItem(id: 123, mediaType: 'movie', title: ''),
        ),
      ),
    ),
  );
}

void main() {
  test('mobile layout uses compact medium and expanded breakpoints safely', () {
    expect(
      homeLabDiscoveryWindowClass(360),
      HomeLabDiscoveryWindowClass.compact,
    );
    expect(
      homeLabDiscoveryWindowClass(700),
      HomeLabDiscoveryWindowClass.medium,
    );
    expect(
      homeLabDiscoveryWindowClass(840),
      HomeLabDiscoveryWindowClass.expanded,
    );
    expect(
      homeLabDiscoveryWindowClass(double.infinity),
      HomeLabDiscoveryWindowClass.compact,
    );

    expect(homeLabDiscoveryLaneCardWidth(360), 124);
    expect(homeLabDiscoveryLaneCardWidth(700), 140);
    expect(homeLabDiscoveryLaneCardWidth(900), 148);

    expect(homeLabDiscoveryGridColumns(328), 2);
    expect(homeLabDiscoveryGridColumns(552), 3);
    expect(homeLabDiscoveryGridColumns(792), 5);
  });

  testWidgets('mobile tabs keep a full touch target and switch by tap', (
    tester,
  ) async {
    await tester.pumpWidget(mobileTabHarness());
    await tester.pumpAndSettle();

    final moviesTab = find.byKey(
      const ValueKey<String>('homelab-discovery-tab-movies'),
    );
    expect(
      tester.getSize(moviesTab).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('homelab-discovery-tab-series')),
    );
    await tester.pumpAndSettle();
    expect(find.text('SERIES BODY'), findsOneWidget);
  }, skip: kIsWeb);

  testWidgets('mobile media card fallback remains tappable exactly once', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(mobileCardHarness(() => activations++));
    await tester.pumpAndSettle();

    expect(find.text('Untitled'), findsOneWidget);
    expect(find.text('UNTITLED'), findsOneWidget);

    await tester.tap(find.byType(HomeLabDiscoveryMediaCard));
    await tester.pump();
    expect(activations, 1);
  }, skip: kIsWeb);
}
