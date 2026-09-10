import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_tv_grid.dart';
import 'package:moonfin/l10n/app_localizations.dart';
import 'package:moonfin/ui/widgets/focus/hub_focus_memory.dart';

void main() {
  setUp(HubFocusMemory.clearAll);

  List<SeerrDiscoverItem> items(int count) => List.generate(
    count,
    (index) => SeerrDiscoverItem(
      id: index + 1,
      mediaType: 'movie',
      title: 'Item ${index + 1}',
    ),
  );

  Future<HomeLabDiscoveryTvGridState> pumpGrid(
    WidgetTester tester, {
    required int itemCount,
    required ValueChanged<SeerrDiscoverItem> onOpen,
    VoidCallback? onNearEnd,
    VoidCallback? onBack,
    VoidCallback? onUpEdge,
    VoidCallback? onDownEdge,
    String hubKey = 'tv-grid-test',
    Size? viewSize,
  }) async {
    if (viewSize != null) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = viewSize;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: viewSize?.width ?? 620,
              height: viewSize?.height ?? 640,
              child: HomeLabDiscoveryTvGrid(
                items: items(itemCount),
                hubKey: hubKey,
                autofocus: true,
                onOpenItem: onOpen,
                onNearEnd: onNearEnd,
                onBack: onBack,
                onUpEdge: onUpEdge,
                onDownEdge: onDownEdge,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.state<HomeLabDiscoveryTvGridState>(
      find.byType(HomeLabDiscoveryTvGrid),
    );
  }

  testWidgets('autofocus owns the first deep-grid item deterministically', (
    tester,
  ) async {
    final state = await pumpGrid(tester, itemCount: 6, onOpen: (_) {});

    expect(state.hasFocus, isTrue);
    expect(state.focusedIndex, 0);
    expect(state.columns, 3);
  });

  testWidgets(
    'D-pad traverses rows and select opens exactly one focused item',
    (tester) async {
      final opened = <int>[];
      final state = await pumpGrid(
        tester,
        itemCount: 6,
        onOpen: (item) => opened.add(item.id),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(state.focusedIndex, 4);

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(opened, [5]);
    },
  );

  testWidgets('down into a partial final row clamps to its last real card', (
    tester,
  ) async {
    final state = await pumpGrid(tester, itemCount: 5, onOpen: (_) {});

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(state.focusedIndex, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(state.focusedIndex, 4);
  });

  testWidgets('vertical edges delegate to the owning TV screen', (
    tester,
  ) async {
    var upEdges = 0;
    var downEdges = 0;
    final state = await pumpGrid(
      tester,
      itemCount: 6,
      onOpen: (_) {},
      onUpEdge: () => upEdges += 1,
      onDownEdge: () => downEdges += 1,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(upEdges, 1);
    expect(state.focusedIndex, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(state.focusedIndex, 3);
    expect(downEdges, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(downEdges, 1);
    expect(state.focusedIndex, 3);
  });

  testWidgets('remote Back is delegated once to the owning deep route', (
    tester,
  ) async {
    var backs = 0;
    await pumpGrid(
      tester,
      itemCount: 6,
      onOpen: (_) {},
      onBack: () => backs += 1,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(backs, 1);
  });

  testWidgets('near-end paging signal fires once per current item set', (
    tester,
  ) async {
    var nearEndCalls = 0;
    final state = await pumpGrid(
      tester,
      itemCount: 9,
      onOpen: (_) {},
      onNearEnd: () => nearEndCalls += 1,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(state.focusedIndex, 3);
    expect(nearEndCalls, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(nearEndCalls, 1);
  });

  testWidgets('1080p and 4K keep off-screen D-pad focus in view', (
    tester,
  ) async {
    const scenarios = [
      (size: Size(1920, 1080), columns: 10, downs: 3, targetIndex: 30),
      (size: Size(3840, 2160), columns: 12, downs: 4, targetIndex: 48),
    ];

    for (final scenario in scenarios) {
      final state = await pumpGrid(
        tester,
        itemCount: 72,
        onOpen: (_) {},
        hubKey: 'tv-grid-wide-${scenario.size.width.toInt()}',
        viewSize: scenario.size,
      );
      expect(state.columns, scenario.columns);

      for (var step = 0; step < scenario.downs; step++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }

      expect(state.focusedIndex, scenario.targetIndex);
      final focusedTitle = find.text('Item ${scenario.targetIndex + 1}');
      expect(focusedTitle, findsWidgets);
      final focusedRect = tester.getRect(focusedTitle.first);
      expect(focusedRect.bottom, greaterThan(0));
      expect(focusedRect.top, lessThan(scenario.size.height));
    }
  });

  testWidgets('focus memory restores the previous deep-grid card', (
    tester,
  ) async {
    var state = await pumpGrid(tester, itemCount: 6, onOpen: (_) {});
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(state.focusedIndex, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    state = await pumpGrid(tester, itemCount: 6, onOpen: (_) {});
    expect(state.hasFocus, isTrue);
    expect(state.focusedIndex, 2);
  });

  testWidgets('pointer tap still opens the tapped externally focused card', (
    tester,
  ) async {
    final opened = <int>[];
    await pumpGrid(tester, itemCount: 6, onOpen: (item) => opened.add(item.id));

    await tester.tap(find.text('Item 2'));
    await tester.pump();
    expect(opened, [2]);
  });
}
