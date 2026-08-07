import 'package:go_router/go_router.dart';

import '../screens/hubs/homelab_hub_screen.dart';
import 'homelab_hub_definition.dart';

/// Home Lab prototype routes for dedicated streaming-style content hubs.
///
/// Kept outside the upstream router so the fork patch stays small and easy to
/// rebase. Once the prototype is proven, these routes can be promoted into the
/// normal Moonfin navigation model.
List<RouteBase> homelabHubRoutes() => [
      GoRoute(
        path: HomelabHubRoutes.movies,
        builder: (context, state) =>
            const HomelabHubScreen(kind: HomelabHubKind.movies),
      ),
      GoRoute(
        path: HomelabHubRoutes.tv,
        builder: (context, state) =>
            const HomelabHubScreen(kind: HomelabHubKind.tv),
      ),
      GoRoute(
        path: HomelabHubRoutes.anime,
        builder: (context, state) =>
            const HomelabHubScreen(kind: HomelabHubKind.anime),
      ),
    ];
