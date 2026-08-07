#!/usr/bin/env python3
"""Apply the minimal upstream-file patch for the Home Lab hub prototype.

The hub implementation lives in isolated files. This patcher only wires those
files into Moonfin's router and existing navigation chrome so future upstream
rebases remain deterministic and easy to review.
"""

from pathlib import Path

ROUTER = Path("lib/ui/navigation/app_router.dart")
LEFT_SIDEBAR = Path("lib/ui/widgets/left_sidebar.dart")
TOP_TOOLBAR = Path("lib/ui/widgets/top_toolbar.dart")


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


def main() -> None:
    patch_router()
    patch_left_sidebar()
    patch_top_toolbar()
    print("Home Lab hub router and navigation patch applied.")


if __name__ == "__main__":
    main()
