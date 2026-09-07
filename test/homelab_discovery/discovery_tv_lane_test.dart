import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_tv_lane.dart';
import 'package:moonfin/l10n/app_localizations.dart';

void main() {
  const items = [
    SeerrDiscoverItem(id: 1, mediaType: 'movie', title: 'One'),
    SeerrDiscoverItem(id: 2, mediaType: 'movie', title: 'Two'),
  ];
  const section = HomeLabDiscoverySection(
    id: 'tv-focus-test-row',
    title: 'TV Focus Test',
    query: HomeLabDiscoveryQuery(
      source: HomeLabDiscoverySource.discoverMovies,
      mediaType: 'movie',
    ),
    previewLimit: 2,
    minItems: 1,
  );

  HomeLabDiscoveryLaneLoadResult lane() => HomeLabDiscoveryLaneLoadResult(
    section: section,
    items: items,
    throughPage: 1,
    totalPages: 4,
  );

  Future<void> pumpLane(
    WidgetTester tester, {
    required ValueChanged<SeerrDiscoverItem> onOpen,
    VoidCallback? onSeeAll,
    bool Function(bool isUp)? onVerticalNavigation,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeLabDiscoveryTvLane(
            tabId: 'movies-test-${onSeeAll != null}',
            lane: lane(),
            autofocus: true,
            onOpenItem: onOpen,
            onSeeAll: onSeeAll,
            onVerticalNavigation: onVerticalNavigation,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Widget tests can have a competing root focus scope. Exercise the same
    // public focus-restoration path used by Discovery when moving vertically
    // between TV lanes so the D-pad assertions are deterministic rather than
    // depending on autofocus timing.
    final laneState = tester.state<HomeLabDiscoveryTvLaneState>(
      find.byType(HomeLabDiscoveryTvLane),
    );
    laneState.requestFocusFromMemory();
    await tester.pumpAndSettle();
  }

  testWidgets('D-pad select activates the currently focused item once', (
    tester,
  ) async {
    final opened = <int>[];
    await pumpLane(tester, onOpen: (item) => opened.add(item.id));

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(opened, [1]);
  });

  testWidgets('right edge enters See All instead of trapping focus', (
    tester,
  ) async {
    var seeAllCount = 0;
    await pumpLane(tester, onOpen: (_) {}, onSeeAll: () => seeAllCount += 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(seeAllCount, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(seeAllCount, 1);
  });

  testWidgets('up and down are delegated to deterministic lane navigation', (
    tester,
  ) async {
    final directions = <bool>[];
    await pumpLane(
      tester,
      onOpen: (_) {},
      onVerticalNavigation: (isUp) {
        directions.add(isUp);
        return true;
      },
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(directions, [false, true]);
  });

  testWidgets('pointer tap still activates a card with external TV focus', (
    tester,
  ) async {
    final opened = <int>[];
    await pumpLane(tester, onOpen: (item) => opened.add(item.id));

    await tester.tap(find.text('Two'));
    await tester.pump();

    expect(opened, [2]);
  });
}
