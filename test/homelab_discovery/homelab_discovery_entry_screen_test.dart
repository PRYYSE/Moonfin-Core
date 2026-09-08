import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue_loader.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_see_all_controller.dart';
import 'package:moonfin/features/homelab_discovery/ui/discovery_routes.dart';
import 'package:moonfin/features/homelab_discovery/ui/homelab_discovery_entry_screen.dart';
import 'package:moonfin/ui/navigation/destinations.dart';

const section = HomeLabDiscoverySection(
  id: 'movies-row',
  title: 'Movies Row',
  minItems: 1,
  query: HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
);

const catalogue = HomeLabDiscoveryCatalogue(
  schemaVersion: 2,
  tabs: [
    HomeLabDiscoveryTab(id: 'movies', title: 'Movies', sections: [section]),
  ],
);

Widget appFor(HomeLabDiscoveryLoad load) {
  return MaterialApp(
    home: HomeLabDiscoveryEntryScreen(
      load: load,
      discoveryBuilder: (_, _) => const Text('CUSTOM'),
      fallbackBuilder: (_) => const Text('STOCK'),
    ),
  );
}

HomeLabDiscoverySeeAllController deepController() {
  return HomeLabDiscoverySeeAllController(
    section: section,
    loadPage: (
      candidate, {
      required page,
      required forceRefresh,
    }) async => HomeLabDiscoveryPageLoadResult(
      section: candidate,
      page: page,
      totalPages: 1,
      totalResults: 0,
      items: const <SeerrDiscoverItem>[],
    ),
  );
}

void main() {
  testWidgets('valid catalogue selects custom Discovery', (tester) async {
    await tester.pumpWidget(
      appFor(
        () async => const HomeLabDiscoveryLoadResult(
          catalogue: catalogue,
          source: HomeLabDiscoveryCatalogueSource.network,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CUSTOM'), findsOneWidget);
    expect(find.text('STOCK'), findsNothing);
  });

  testWidgets('unavailable catalogue selects stock Discovery', (tester) async {
    await tester.pumpWidget(
      appFor(
        () async => const HomeLabDiscoveryLoadResult(
          catalogue: null,
          source: HomeLabDiscoveryCatalogueSource.unavailable,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('STOCK'), findsOneWidget);
    expect(find.text('CUSTOM'), findsNothing);
  });

  test('section route is URL-safe and round-trips its section id', () {
    final location = HomeLabDiscoveryRoutes.section('anime:watch list/2026');
    final uri = Uri.parse(location);

    expect(uri.path, Destinations.seerrDiscover);
    expect(
      HomeLabDiscoveryRoutes.sectionId(uri),
      'anime:watch list/2026',
    );
    expect(HomeLabDiscoveryRoutes.sectionId(Uri.parse('/home')), isNull);
  });

  testWidgets(
    'payload deep route uses navigation history and restores landing without reload',
    (tester) async {
      var loadCalls = 0;
      final controller = deepController();
      late final GoRouter router;
      router = GoRouter(
        initialLocation: Destinations.seerrDiscover,
        routes: [
          GoRoute(
            path: Destinations.seerrDiscover,
            builder: (context, state) => HomeLabDiscoveryEntryScreen(
              load: () async {
                loadCalls++;
                return const HomeLabDiscoveryLoadResult(
                  catalogue: catalogue,
                  source: HomeLabDiscoveryCatalogueSource.network,
                );
              },
              discoveryBuilder: (context, loadedCatalogue) => Scaffold(
                body: TextButton(
                  onPressed: () => context.push<void>(
                    HomeLabDiscoveryRoutes.section(section.id),
                    extra: HomeLabDiscoverySeeAllRoutePayload(
                      sectionId: section.id,
                      catalogue: loadedCatalogue,
                      controller: controller,
                    ),
                  ),
                  child: const Text('OPEN DEEP'),
                ),
              ),
              seeAllBuilder: (_, _, sectionId, payload) => Scaffold(
                body: Text(
                  'DEEP:$sectionId:${payload == null ? 'reload' : 'payload'}',
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('OPEN DEEP'), findsOneWidget);
      expect(loadCalls, 1);

      await tester.tap(find.text('OPEN DEEP'));
      await tester.pumpAndSettle();
      expect(find.text('DEEP:movies-row:payload'), findsOneWidget);
      expect(loadCalls, 1);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('OPEN DEEP'), findsOneWidget);
      expect(loadCalls, 1);
    },
  );

  testWidgets('direct deep URL reloads catalogue and resolves section', (
    tester,
  ) async {
    var loadCalls = 0;
    final router = GoRouter(
      initialLocation: HomeLabDiscoveryRoutes.section(section.id),
      routes: [
        GoRoute(
          path: Destinations.seerrDiscover,
          builder: (context, state) => HomeLabDiscoveryEntryScreen(
            load: () async {
              loadCalls++;
              return const HomeLabDiscoveryLoadResult(
                catalogue: catalogue,
                source: HomeLabDiscoveryCatalogueSource.network,
              );
            },
            discoveryBuilder: (_, _) => const Text('LANDING'),
            seeAllBuilder: (_, _, sectionId, payload) => Text(
              'DIRECT:$sectionId:${payload == null ? 'reload' : 'payload'}',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('DIRECT:movies-row:reload'), findsOneWidget);
    expect(loadCalls, 1);
  });
}
