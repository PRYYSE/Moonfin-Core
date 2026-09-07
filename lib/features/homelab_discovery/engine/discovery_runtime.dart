import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../data/repositories/seerr_repository.dart';
import '../../../data/services/row_data_source.dart';
import '../../../preference/seerr_preferences.dart';
import '../bridge/moonfin_discovery_bridge.dart';
import '../catalogue/discovery_catalogue.dart';
import '../data/discovery_lane_loader.dart';
import '../data/discovery_membership_policy.dart';
import 'discovery_personalisation.dart';
import 'discovery_tab_controller.dart';

typedef HomeLabDiscoveryRuntimeLoad =
    Future<HomeLabDiscoveryRuntime> Function(
      HomeLabDiscoveryCatalogue catalogue,
    );

/// Owns the feature-local runtime objects needed by a rendered catalogue.
///
/// Core Moonfin DI remains untouched. The runtime consumes the stock active
/// server, Seerr repository and RowDataSource registrations and adapts them at
/// the Discovery boundary.
class HomeLabDiscoveryRuntime {
  final HomeLabDiscoveryCatalogue catalogue;
  final Map<String, HomeLabDiscoveryTabController> _controllers;
  final void Function()? _onDispose;
  bool _disposed = false;

  HomeLabDiscoveryRuntime._({
    required this.catalogue,
    required Map<String, HomeLabDiscoveryTabController> controllers,
    void Function()? onDispose,
  }) : _controllers = Map.unmodifiable(controllers),
       _onDispose = onDispose;

  HomeLabDiscoveryRuntime.forTesting({
    required this.catalogue,
    required Map<String, HomeLabDiscoveryTabController> controllers,
  }) : _controllers = Map.unmodifiable(controllers),
       _onDispose = null;

  static Future<HomeLabDiscoveryRuntime> create(
    HomeLabDiscoveryCatalogue catalogue,
  ) async {
    final getIt = GetIt.instance;
    final activeClient = getIt<MediaServerClient>();
    final repository = await getIt.getAsync<SeerrRepository>();
    final preferences = getIt<SeerrPreferences>();
    final bridge = MoonfinHomeLabDiscoveryBridge(
      repository: repository,
      client: activeClient,
    );
    final personalisation = HomeLabDiscoveryPersonalisation(
      serverId: activeClient.baseUrl,
      rowDataSource: getIt<RowDataSource>(),
    );
    final loader = HomeLabDiscoveryLaneLoader(
      fetchPage: bridge.fetchPage,
      personalisation: personalisation,
      include: (section, item) => HomeLabDiscoveryMembershipPolicy.include(
        item,
        section.availabilityMode,
        blockNsfw: preferences.blockNsfw,
      ),
    );
    final userKey = activeClient.userId?.trim();
    final sessionSeed =
        '${activeClient.baseUrl}|${userKey?.isEmpty ?? true ? 'anonymous' : userKey}';
    final controllers = <String, HomeLabDiscoveryTabController>{
      for (final tab in catalogue.tabs)
        tab.id: HomeLabDiscoveryTabController(
          tab: tab,
          loadLane: loader.load,
          sessionSeed: sessionSeed,
        ),
    };

    return HomeLabDiscoveryRuntime._(
      catalogue: catalogue,
      controllers: controllers,
      onDispose: () {
        personalisation.clear();
        bridge.close();
      },
    );
  }

  HomeLabDiscoveryTabController controllerFor(String tabId) {
    if (_disposed) {
      throw StateError('Home Lab Discovery runtime has been disposed');
    }
    final controller = _controllers[tabId];
    if (controller == null) {
      throw StateError('No Discovery controller registered for tab $tabId');
    }
    return controller;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _onDispose?.call();
  }
}
