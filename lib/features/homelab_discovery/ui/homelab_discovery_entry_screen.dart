import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/media_server_client_factory.dart';
import '../../../ui/screens/seerr/seerr_discover_screen.dart';
import '../catalogue/discovery_catalogue.dart';
import '../catalogue/discovery_catalogue_loader.dart';
import 'homelab_discovery_screen.dart';

typedef HomeLabDiscoveryLoad = Future<HomeLabDiscoveryLoadResult> Function();
typedef HomeLabDiscoveryBuilder = Widget Function(
  BuildContext context,
  HomeLabDiscoveryCatalogue catalogue,
);

class HomeLabDiscoveryEntryScreen extends StatefulWidget {
  final HomeLabDiscoveryLoad? load;
  final HomeLabDiscoveryBuilder? discoveryBuilder;
  final WidgetBuilder? fallbackBuilder;

  const HomeLabDiscoveryEntryScreen({
    super.key,
    this.load,
    this.discoveryBuilder,
    this.fallbackBuilder,
  });

  @override
  State<HomeLabDiscoveryEntryScreen> createState() =>
      _HomeLabDiscoveryEntryScreenState();
}

class _HomeLabDiscoveryEntryScreenState
    extends State<HomeLabDiscoveryEntryScreen> {
  late final Future<HomeLabDiscoveryLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = (widget.load ?? _loadDefault)();
  }

  Future<HomeLabDiscoveryLoadResult> _loadDefault() async {
    try {
      final baseUrl = GetIt.instance<MediaServerClientFactory>()
          .getActiveClient()
          .baseUrl;
      if (baseUrl.trim().isEmpty) {
        return const HomeLabDiscoveryLoadResult(
          catalogue: null,
          source: HomeLabDiscoveryCatalogueSource.unavailable,
        );
      }
      final preferences = await SharedPreferences.getInstance();
      final cache = SharedPreferencesHomeLabDiscoveryCatalogueCache.forBaseUrl(
        preferences,
        baseUrl,
      );
      return HomeLabDiscoveryCatalogueLoader.network(
        baseUrl: baseUrl,
        cache: cache,
      ).load();
    } catch (error) {
      return HomeLabDiscoveryLoadResult(
        catalogue: null,
        source: HomeLabDiscoveryCatalogueSource.unavailable,
        networkError: error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeLabDiscoveryLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final catalogue = snapshot.data?.catalogue;
        if (catalogue != null) {
          final builder = widget.discoveryBuilder ??
              (context, catalogue) =>
                  HomeLabDiscoveryScreen(catalogue: catalogue);
          return builder(context, catalogue);
        }

        return (widget.fallbackBuilder ??
            (context) => const SeerrDiscoverScreen())(context);
      },
    );
  }
}
