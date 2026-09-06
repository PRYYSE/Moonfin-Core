import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue_loader.dart';
import 'package:moonfin/features/homelab_discovery/ui/homelab_discovery_entry_screen.dart';

const catalogue = HomeLabDiscoveryCatalogue(
  schemaVersion: 2,
  tabs: [HomeLabDiscoveryTab(id: 'movies', title: 'Movies', sections: [])],
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
}
