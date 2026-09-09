import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moonfin/auth/repositories/user_repository.dart';
import 'package:moonfin/data/models/aggregated_library.dart';
import 'package:moonfin/data/repositories/user_views_repository.dart';
import 'package:moonfin/data/services/plugin_sync_service.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_see_all_controller.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_tab_strip.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_tv_grid.dart';
import 'package:moonfin/features/homelab_discovery/ui/homelab_discovery_see_all_screen.dart';
import 'package:moonfin/l10n/app_localizations.dart';
import 'package:moonfin/preference/seerr_preferences.dart';
import 'package:moonfin/preference/user_preferences.dart';
import 'package:moonfin/ui/widgets/focus/hub_focus_memory.dart';
import 'package:moonfin/util/platform_detection.dart';
import 'package:playback_core/playback_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockUserViewsRepository extends Mock implements UserViewsRepository {}

class _MockPluginSyncService extends Mock implements PluginSyncService {}

class _MockSeerrPreferences extends Mock implements SeerrPreferences {}

const _tabs = [
  HomeLabDiscoveryTab(id: 'movies', title: 'Movies', sections: []),
  HomeLabDiscoveryTab(id: 'series', title: 'Series', sections: []),
  HomeLabDiscoveryTab(id: 'anime', title: 'Anime', sections: []),
];

const _section = HomeLabDiscoverySection(
  id: 'tv-recovery',
  title: 'TV Recovery',
  query: HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
  previewLimit: 4,
  minItems: 1,
);

const _item = SeerrDiscoverItem(
  id: 101,
  mediaType: 'movie',
  title: 'Recovered Item',
);

HomeLabDiscoveryPageLoadResult _page({
  List<SeerrDiscoverItem> items = const [],
}) => HomeLabDiscoveryPageLoadResult(
  section: _section,
  displayTitle: _section.title,
  items: items,
  page: 1,
  totalPages: 1,
  totalResults: items.length,
);

Widget _materialHarness(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Widget _tabHarness() {
  return MaterialApp(
    home: DefaultTabController(
      length: _tabs.length,
      child: const Scaffold(
        body: Column(
          children: [
            HomeLabDiscoveryTabStrip(tabs: _tabs),
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

Future<void> _pumpTvScreenTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump();
}

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    SharedPreferences.setMockInitialValues({});

    final store = PreferenceStore();
    await store.init();
    final preferences = UserPreferences(store);
    await store.flushPendingWrites();

    final userViews = _MockUserViewsRepository();
    when(
      () => userViews.getUserViews(),
    ).thenAnswer((_) async => const <AggregatedLibrary>[]);

    final pluginSync = _MockPluginSyncService();
    when(() => pluginSync.seerrAvailable).thenReturn(false);

    final seerrPreferences = _MockSeerrPreferences();
    when(() => seerrPreferences.labelOrDefault(any())).thenAnswer(
      (invocation) => invocation.positionalArguments.first as String,
    );
    when(() => seerrPreferences.isSeerrVariant).thenReturn(false);

    GetIt.instance
      ..registerSingleton<UserPreferences>(preferences)
      ..registerSingleton<UserRepository>(UserRepository())
      ..registerSingleton<UserViewsRepository>(userViews)
      ..registerSingleton<PluginSyncService>(pluginSync)
      ..registerSingleton<SeerrPreferences>(seerrPreferences)
      ..registerSingleton<PlaybackManager>(PlaybackManager());

    PlatformDetection.setInterfaceLayout(InterfaceLayout.automatic);
    PlatformDetection.setTvMode(true);
    HubFocusMemory.clearAll();
  });

  tearDown(() async {
    PlatformDetection.setTvMode(false);
    PlatformDetection.setInterfaceLayout(InterfaceLayout.automatic);
    HubFocusMemory.clearAll();
    await GetIt.instance.reset();
  });

  testWidgets('TV tab strip is reachable and changes tab by D-pad selection', (
    tester,
  ) async {
    await tester.pumpWidget(_tabHarness());
    await tester.pumpAndSettle();
    expect(find.text('MOVIES BODY'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(find.text('SERIES BODY'), findsOneWidget);
  });

  testWidgets('TV genuine-empty deep browse exposes remote Refresh', (
    tester,
  ) async {
    var forcedRefreshes = 0;
    final controller = HomeLabDiscoverySeeAllController(
      section: _section,
      maxEmptyPageReadAhead: 1,
      loadPage: (_, {page = 1, forceRefresh = false}) async {
        if (forceRefresh) {
          forcedRefreshes++;
          return _page(items: const [_item]);
        }
        return _page();
      },
    );

    await tester.pumpWidget(
      _materialHarness(HomeLabDiscoverySeeAllScreen(controller: controller)),
    );
    await _pumpTvScreenTransition(tester);

    final refresh = find.byKey(
      const ValueKey<String>('homelab-discovery-deep-refresh-empty'),
    );
    expect(refresh, findsOneWidget);
    expect(tester.widget<FilledButton>(refresh).autofocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await _pumpTvScreenTransition(tester);

    expect(forcedRefreshes, 1);
    expect(controller.state.items, const [_item]);
    expect(find.byType(HomeLabDiscoveryTvGrid), findsOneWidget);
  });

  testWidgets('TV deep-load failure autofocuses Retry and recovers by Select', (
    tester,
  ) async {
    var attempts = 0;
    final controller = HomeLabDiscoverySeeAllController(
      section: _section,
      maxEmptyPageReadAhead: 1,
      loadPage: (_, {page = 1, forceRefresh = false}) async {
        attempts++;
        if (attempts == 1) throw StateError('temporary TV failure');
        return _page(items: const [_item]);
      },
    );

    await tester.pumpWidget(
      _materialHarness(HomeLabDiscoverySeeAllScreen(controller: controller)),
    );
    await _pumpTvScreenTransition(tester);

    final retry = find.byKey(
      const ValueKey<String>('homelab-discovery-deep-retry'),
    );
    expect(retry, findsOneWidget);
    expect(tester.widget<FilledButton>(retry).autofocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await _pumpTvScreenTransition(tester);

    expect(attempts, 2);
    expect(controller.state.items, const [_item]);
    expect(find.byType(HomeLabDiscoveryTvGrid), findsOneWidget);
  });
}
