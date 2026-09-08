import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ui/screens/seerr/seerr_discover_screen.dart';
import '../catalogue/discovery_catalogue.dart';
import '../catalogue/discovery_catalogue_loader.dart';
import 'discovery_routes.dart';
import 'homelab_discovery_screen.dart';
import 'homelab_discovery_see_all_entry.dart';

typedef HomeLabDiscoveryLoad = Future<HomeLabDiscoveryLoadResult> Function();
typedef HomeLabDiscoveryBuilder =
    Widget Function(BuildContext context, HomeLabDiscoveryCatalogue catalogue);
typedef HomeLabDiscoverySeeAllBuilder =
    Widget Function(
      BuildContext context,
      HomeLabDiscoveryCatalogue catalogue,
      String sectionId,
      HomeLabDiscoverySeeAllRoutePayload? payload,
    );

class HomeLabDiscoveryEntryScreen extends StatefulWidget {
  final HomeLabDiscoveryLoad? load;
  final HomeLabDiscoveryBuilder? discoveryBuilder;
  final HomeLabDiscoverySeeAllBuilder? seeAllBuilder;
  final WidgetBuilder? fallbackBuilder;

  const HomeLabDiscoveryEntryScreen({
    super.key,
    this.load,
    this.discoveryBuilder,
    this.seeAllBuilder,
    this.fallbackBuilder,
  });

  @override
  State<HomeLabDiscoveryEntryScreen> createState() =>
      _HomeLabDiscoveryEntryScreenState();
}

class _HomeLabDiscoveryEntryScreenState
    extends State<HomeLabDiscoveryEntryScreen> {
  Future<HomeLabDiscoveryLoadResult>? _loadFuture;
  Uri? _routeUri;
  String? _sectionId;
  HomeLabDiscoverySeeAllRoutePayload? _routePayload;
  bool _routeStateResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRouteState();
  }

  @override
  void didUpdateWidget(covariant HomeLabDiscoveryEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.load != widget.load) {
      // GoRouter rebuilds this route with a new builder closure when the
      // section query changes. Resolve the current route first so entering a
      // payload-backed deep route does not launch an unnecessary catalogue
      // request that is immediately discarded.
      _routeStateResolved = false;
      _syncRouteState();
    }
  }

  void _syncRouteState() {
    Uri? uri;
    Object? extra;
    try {
      final state = GoRouterState.of(context);
      uri = state.uri;
      extra = state.extra;
    } catch (_) {
      // Widget tests and embedders may host the entry screen without GoRouter.
    }

    final sectionId = HomeLabDiscoveryRoutes.sectionId(uri);
    final candidatePayload = extra is HomeLabDiscoverySeeAllRoutePayload
        ? extra
        : null;
    final payload = candidatePayload?.matches(sectionId) == true
        ? candidatePayload
        : null;

    if (_routeStateResolved &&
        _routeUri == uri &&
        _sectionId == sectionId &&
        identical(_routePayload, payload)) {
      return;
    }

    _routeStateResolved = true;
    _routeUri = uri;
    _sectionId = sectionId;
    _routePayload = payload;
    _loadFuture = payload == null ? (widget.load ?? _loadDefault)() : null;
  }

  Future<HomeLabDiscoveryLoadResult> _loadDefault() async {
    try {
      final baseUrl = GetIt.instance<MediaServerClient>().baseUrl;
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
    final payload = _routePayload;
    if (payload != null) {
      return _buildSeeAll(
        context,
        payload.catalogue,
        payload.sectionId,
        payload,
      );
    }

    final future = _loadFuture;
    if (future == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<HomeLabDiscoveryLoadResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final catalogue = snapshot.data?.catalogue;
        if (catalogue != null) {
          final sectionId = _sectionId;
          if (sectionId != null) {
            return _buildSeeAll(context, catalogue, sectionId, null);
          }

          final builder =
              widget.discoveryBuilder ??
              (context, catalogue) =>
                  HomeLabDiscoveryScreen(catalogue: catalogue);
          return builder(context, catalogue);
        }

        return (widget.fallbackBuilder ??
            (context) => const SeerrDiscoverScreen())(context);
      },
    );
  }

  Widget _buildSeeAll(
    BuildContext context,
    HomeLabDiscoveryCatalogue catalogue,
    String sectionId,
    HomeLabDiscoverySeeAllRoutePayload? payload,
  ) {
    final builder = widget.seeAllBuilder;
    if (builder != null) {
      return builder(context, catalogue, sectionId, payload);
    }
    return HomeLabDiscoverySeeAllEntry(
      key: ValueKey<String>('homelab-discovery-see-all-entry-$sectionId'),
      catalogue: catalogue,
      sectionId: sectionId,
      controller: payload?.controller,
    );
  }
}
