#!/usr/bin/env python3
"""Apply the minimal upstream-file patch for the Home Lab hub prototype.

The hub implementation lives in isolated files. This patcher wires those files
into Moonfin's router/navigation and applies small deterministic prototype fixes
so future upstream rebases remain easy to review.
"""

from pathlib import Path

ROUTER = Path("lib/ui/navigation/app_router.dart")
LEFT_SIDEBAR = Path("lib/ui/widgets/left_sidebar.dart")
TOP_TOOLBAR = Path("lib/ui/widgets/top_toolbar.dart")
HUB_SCREEN = Path("lib/ui/screens/hubs/homelab_hub_screen.dart")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"Refusing to patch {label}: expected one anchor, found {count}. "
            "Upstream UI structure changed."
        )
    return text.replace(old, new, 1)


def patch_router() -> None:
    text = ROUTER.read_text(encoding="utf-8")

    text = replace_once(
        text,
        "import 'destinations.dart';\n",
        "import 'destinations.dart';\nimport 'homelab_hub_routes.dart';\n",
        "router import",
    )

    text = replace_once(
        text,
        "  routes: [\n    // Auth\n",
        "  routes: [\n    ...homelabHubRoutes(),\n\n    // Auth\n",
        "router route list",
    )

    ROUTER.write_text(text, encoding="utf-8")


def patch_left_sidebar() -> None:
    text = LEFT_SIDEBAR.read_text(encoding="utf-8")

    text = replace_once(
        text,
        "import '../navigation/destinations.dart';\n",
        "import '../navigation/destinations.dart';\n"
        "import '../navigation/homelab_hub_routes.dart';\n",
        "left sidebar hub import",
    )

    anchor = """                _SidebarItem(
                  key: const ValueKey('sidebar-search'),
"""
    insertion = """                _SidebarItem(
                  key: const ValueKey('sidebar-homelab-movies'),
                  icon: Icons.movie_rounded,
                  label: 'Movies',
                  baseColor: nextMainSidebarColor(),
                  showLabel: _showLabels,
                  onPressed: () {
                    _onNavigate();
                    if (_isActive(HomelabHubRoutes.movies)) {
                      _exitSidebarToContent();
                      return;
                    }
                    _markNavigationAwayFromSidebar();
                    context.navigateTopLevel(HomelabHubRoutes.movies);
                  },
                ),
                _SidebarItem(
                  key: const ValueKey('sidebar-homelab-tv'),
                  icon: Icons.tv_rounded,
                  label: 'TV',
                  baseColor: nextMainSidebarColor(),
                  showLabel: _showLabels,
                  onPressed: () {
                    _onNavigate();
                    if (_isActive(HomelabHubRoutes.tv)) {
                      _exitSidebarToContent();
                      return;
                    }
                    _markNavigationAwayFromSidebar();
                    context.navigateTopLevel(HomelabHubRoutes.tv);
                  },
                ),
                _SidebarItem(
                  key: const ValueKey('sidebar-homelab-anime'),
                  icon: Icons.auto_awesome_rounded,
                  label: 'Anime',
                  baseColor: nextMainSidebarColor(),
                  showLabel: _showLabels,
                  onPressed: () {
                    _onNavigate();
                    if (_isActive(HomelabHubRoutes.anime)) {
                      _exitSidebarToContent();
                      return;
                    }
                    _markNavigationAwayFromSidebar();
                    context.navigateTopLevel(HomelabHubRoutes.anime);
                  },
                ),
""" + anchor

    text = replace_once(
        text,
        anchor,
        insertion,
        "left sidebar hub buttons",
    )

    LEFT_SIDEBAR.write_text(text, encoding="utf-8")


def patch_top_toolbar() -> None:
    text = TOP_TOOLBAR.read_text(encoding="utf-8")

    text = replace_once(
        text,
        "import '../navigation/destinations.dart';\n",
        "import '../navigation/destinations.dart';\n"
        "import '../navigation/homelab_hub_routes.dart';\n",
        "top toolbar hub import",
    )

    anchor = """                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: ExpandableIconButton(
                    key: const ValueKey('toolbar_search'),
"""
    insertion = """                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: ExpandableIconButton(
                    key: const ValueKey('toolbar_homelab_movies'),
                    forceExpanded: alwaysExpanded,
                    icon: Icons.movie_rounded,
                    label: 'Movies',
                    baseColor: nextNavColor(),
                    onPressed: () {
                      if (_isActive(HomelabHubRoutes.movies)) return;
                      context.navigateTopLevel(HomelabHubRoutes.movies);
                    },
                  ),
                ),
                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: ExpandableIconButton(
                    key: const ValueKey('toolbar_homelab_tv'),
                    forceExpanded: alwaysExpanded,
                    icon: Icons.tv_rounded,
                    label: 'TV',
                    baseColor: nextNavColor(),
                    onPressed: () {
                      if (_isActive(HomelabHubRoutes.tv)) return;
                      context.navigateTopLevel(HomelabHubRoutes.tv);
                    },
                  ),
                ),
                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: ExpandableIconButton(
                    key: const ValueKey('toolbar_homelab_anime'),
                    forceExpanded: alwaysExpanded,
                    icon: Icons.auto_awesome_rounded,
                    label: 'Anime',
                    baseColor: nextNavColor(),
                    onPressed: () {
                      if (_isActive(HomelabHubRoutes.anime)) return;
                      context.navigateTopLevel(HomelabHubRoutes.anime);
                    },
                  ),
                ),
""" + anchor

    text = replace_once(
        text,
        anchor,
        insertion,
        "top toolbar hub buttons",
    )

    TOP_TOOLBAR.write_text(text, encoding="utf-8")


def patch_hub_screen() -> None:
    text = HUB_SCREEN.read_text(encoding="utf-8")

    text = replace_once(
        text,
        "import '../../../preference/user_preferences.dart';\n",
        "import '../../../preference/user_preferences.dart';\n"
        "import '../../../util/platform_detection.dart';\n",
        "hub platform import",
    )

    old_movies = """    if (widget.kind == HomelabHubKind.movies) {
      final pages = await Future.wait([
        repo.getTrendingMovies(limit: 20),
        repo.getTopMovies(limit: 20),
        repo.getUpcomingMovies(page: 1),
      ]);
      return [
        _DiscoverHubRow(
          title: 'Trending Movies',
          mediaType: 'movie',
          items: pages[0].results,
        ),
        _DiscoverHubRow(
          title: 'Top Rated Movies',
          mediaType: 'movie',
          items: pages[1].results,
        ),
        _DiscoverHubRow(
          title: 'Upcoming Movies',
          mediaType: 'movie',
          items: pages[2].results,
        ),
      ];
    }
"""
    new_movies = """    if (widget.kind == HomelabHubKind.movies) {
      // Use the generic Seerr discover endpoints here. They are available on
      // the same Moonbase proxy path already proven by the Anime hub and avoid
      // one unsupported convenience endpoint taking the whole page down.
      final pages = await Future.wait([
        repo.discoverMovies(page: 1, sortBy: 'popularity.desc'),
        repo.discoverMovies(page: 1, sortBy: 'vote_average.desc'),
      ]);
      return [
        _DiscoverHubRow(
          title: 'Popular Movies',
          mediaType: 'movie',
          items: pages[0].results,
        ),
        _DiscoverHubRow(
          title: 'Top Rated Movies',
          mediaType: 'movie',
          items: pages[1].results,
        ),
      ];
    }
"""
    text = replace_once(text, old_movies, new_movies, "movie discovery rows")

    old_tv = """    if (widget.kind == HomelabHubKind.tv) {
      final pages = await Future.wait([
        repo.getTrendingTv(limit: 20),
        repo.getTopTv(limit: 20),
        repo.getUpcomingTv(page: 1),
      ]);
      return [
        _DiscoverHubRow(
          title: 'Trending TV',
          mediaType: 'tv',
          items: pages[0].results,
        ),
        _DiscoverHubRow(
          title: 'Top Rated TV',
          mediaType: 'tv',
          items: pages[1].results,
        ),
        _DiscoverHubRow(
          title: 'Upcoming TV',
          mediaType: 'tv',
          items: pages[2].results,
        ),
      ];
    }
"""
    new_tv = """    if (widget.kind == HomelabHubKind.tv) {
      final pages = await Future.wait([
        repo.discoverTv(page: 1, sortBy: 'popularity.desc'),
        repo.discoverTv(page: 1, sortBy: 'vote_average.desc'),
      ]);
      return [
        _DiscoverHubRow(
          title: 'Popular TV',
          mediaType: 'tv',
          items: pages[0].results,
        ),
        _DiscoverHubRow(
          title: 'Top Rated TV',
          mediaType: 'tv',
          items: pages[1].results,
        ),
      ];
    }
"""
    text = replace_once(text, old_tv, new_tv, "tv discovery rows")

    old_insets = """    final navbarPosition = _prefs.get(UserPreferences.navbarPosition);
    final topInset = navbarPosition == NavbarPosition.top
        ? TopToolbar.baseHeightFor(context) + 12
        : 20.0;
"""
    new_insets = """    final navbarPosition = _prefs.get(UserPreferences.navbarPosition);
    final topInset = navbarPosition == NavbarPosition.top
        ? TopToolbar.baseHeightFor(context) + 12
        : 20.0;
    final hasPersistentLeftRail = navbarPosition == NavbarPosition.left &&
        (PlatformDetection.isTV ||
            PlatformDetection.isDesktop ||
            (PlatformDetection.isWeb && !PlatformDetection.useMobileUi));
    final leftInset = hasPersistentLeftRail ? 92.0 : 20.0;
"""
    text = replace_once(text, old_insets, new_insets, "hub sidebar inset")

    text = replace_once(
        text,
        "                padding: EdgeInsets.fromLTRB(20, topInset, 20, 40),\n",
        "                padding: EdgeInsets.fromLTRB(leftInset, topInset, 20, 40),\n",
        "hub list padding",
    )

    old_header_nav = """          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HubNavButton(
                label: 'Home',
                selected: false,
                onPressed: () => context.go(Destinations.home),
              ),
              for (final destination in HomelabHubKind.values)
                _HubNavButton(
                  label: destination.title,
                  selected: destination == kind,
                  onPressed: () {
                    if (destination != kind) context.go(destination.route);
                  },
                ),
            ],
          ),
          if (kind == HomelabHubKind.anime) ...[
            const SizedBox(height: 12),
            Text(
              'Prototype discovery filter: Japanese-language Animation. '
              'MDBList-backed seasonal and curated rows come next.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColorScheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          ],
"""
    text = replace_once(text, old_header_nav, "", "temporary hub header navigation")

    HUB_SCREEN.write_text(text, encoding="utf-8")


def main() -> None:
    patch_router()
    patch_left_sidebar()
    patch_top_toolbar()
    patch_hub_screen()
    print("Home Lab hub router, navigation, and prototype fixes applied.")


if __name__ == "__main__":
    main()
