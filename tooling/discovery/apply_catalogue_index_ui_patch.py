#!/usr/bin/env python3
"""Wire the full Discovery catalogue index into Flutter navigation/UI."""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DESTINATIONS = ROOT / "lib/ui/navigation/destinations.dart"
ROUTER = ROOT / "lib/ui/navigation/app_router.dart"
DISCOVER = ROOT / "lib/ui/screens/seerr/seerr_discover_screen.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_destinations(text: str) -> str:
    marker = "  static const seerrCatalogue = '/seerr/catalogue';\n"
    if marker in text:
        return text
    return replace_once(
        text,
        "  static const seerrBrowse = '/seerr/browse';\n",
        "  static const seerrBrowse = '/seerr/browse';\n" + marker,
        "Seerr catalogue destination",
    )


def patch_router(text: str) -> str:
    if "SeerrDiscoveryCatalogueScreen(" in text:
        return text
    text = replace_once(
        text,
        "import '../screens/seerr/seerr_discover_screen.dart';\n",
        "import '../screens/seerr/seerr_discover_screen.dart';\n"
        "import '../screens/seerr/seerr_discovery_catalogue_screen.dart';\n",
        "catalogue screen import",
    )
    return replace_once(
        text,
        "    GoRoute(\n"
        "      path: Destinations.seerrRequests,\n",
        "    GoRoute(\n"
        "      path: Destinations.seerrCatalogue,\n"
        "      builder: (context, state) => SeerrDiscoveryCatalogueScreen(\n"
        "        tabId: state.uri.queryParameters['tab'] ?? 'movies',\n"
        "      ),\n"
        "    ),\n"
        "    GoRoute(\n"
        "      path: Destinations.seerrRequests,\n",
        "catalogue route",
    )


def patch_discover(text: str) -> str:
    if "__browse_all_catalogue__" in text and "_openCatalogueIndex" in text:
        return text

    text = replace_once(
        text,
        "  void _focusActiveTab() {\n",
        "  void _openCatalogueIndex() {\n"
        "    final tabId = _viewModel?.activeTabId;\n"
        "    if (tabId == null || tabId.isEmpty) return;\n"
        "    context.push(\n"
        "      Uri(\n"
        "        path: Destinations.seerrCatalogue,\n"
        "        queryParameters: {'tab': tabId},\n"
        "      ).toString(),\n"
        "    );\n"
        "  }\n\n"
        "  void _focusActiveTab() {\n",
        "catalogue index opener",
    )

    text = replace_once(
        text,
        "    final desktopScale = GetIt.instance<UserPreferences>()\n"
        "        .get(UserPreferences.desktopUiScale)\n"
        "        .scaleFactor;\n"
        "    return SizedBox(\n",
        "    final desktopScale = GetIt.instance<UserPreferences>()\n"
        "        .get(UserPreferences.desktopUiScale)\n"
        "        .scaleFactor;\n"
        "    const browseAllId = '__browse_all_catalogue__';\n"
        "    final tabItems = <SeerrDiscoveryTab>[\n"
        "      ...vm.tabs,\n"
        "      const SeerrDiscoveryTab(\n"
        "        id: browseAllId,\n"
        "        title: 'All Categories',\n"
        "        sections: [],\n"
        "        initialLaneBudget: 1,\n"
        "        minimumLaneCount: 1,\n"
        "      ),\n"
        "    ];\n"
        "    return SizedBox(\n",
        "catalogue action tab item",
    )

    text = replace_once(
        text,
        "        items: vm.tabs,\n",
        "        items: tabItems,\n",
        "catalogue tab row items",
    )

    text = replace_once(
        text,
        "        onTap: (_, tab) => unawaited(_selectDiscoveryTab(tab)),\n",
        "        onTap: (_, tab) {\n"
        "          if (tab.id == browseAllId) {\n"
        "            _openCatalogueIndex();\n"
        "          } else {\n"
        "            unawaited(_selectDiscoveryTab(tab));\n"
        "          }\n"
        "        },\n",
        "catalogue tab action",
    )

    text = replace_once(
        text,
        "          final active = tab.id == vm.activeTabId;\n"
        "          final accent = AppColorScheme.accent;\n",
        "          final active = tab.id == vm.activeTabId;\n"
        "          final browseAll = tab.id == browseAllId;\n"
        "          final accent = AppColorScheme.accent;\n",
        "catalogue action tile state",
    )

    text = replace_once(
        text,
        "            child: Text(\n"
        "              tab.title,\n"
        "              maxLines: 1,\n"
        "              overflow: TextOverflow.ellipsis,\n"
        "              style: Theme.of(context).textTheme.labelLarge?.copyWith(\n"
        "                color: AppColorScheme.onSurface,\n"
        "                fontWeight: active ? FontWeight.w700 : FontWeight.w600,\n"
        "              ),\n"
        "            ),\n",
        "            child: Row(\n"
        "              mainAxisAlignment: MainAxisAlignment.center,\n"
        "              mainAxisSize: MainAxisSize.min,\n"
        "              children: [\n"
        "                if (browseAll) ...[\n"
        "                  Icon(\n"
        "                    Icons.grid_view_rounded,\n"
        "                    size: 17 * desktopScale,\n"
        "                    color: AppColorScheme.onSurface,\n"
        "                  ),\n"
        "                  SizedBox(width: 6 * desktopScale),\n"
        "                ],\n"
        "                Flexible(\n"
        "                  child: Text(\n"
        "                    tab.title,\n"
        "                    maxLines: 1,\n"
        "                    overflow: TextOverflow.ellipsis,\n"
        "                    style: Theme.of(context).textTheme.labelLarge?.copyWith(\n"
        "                      color: AppColorScheme.onSurface,\n"
        "                      fontWeight: active || browseAll\n"
        "                          ? FontWeight.w700\n"
        "                          : FontWeight.w600,\n"
        "                    ),\n"
        "                  ),\n"
        "                ),\n"
        "              ],\n"
        "            ),\n",
        "catalogue action visual",
    )
    return text


def apply(path: Path, transform, check: bool) -> bool:
    original = path.read_text(encoding="utf-8")
    patched = transform(original)
    changed = patched != original
    if check:
        if changed:
            raise RuntimeError(f"{path.relative_to(ROOT)} is not patched")
        return False
    if changed:
        path.write_text(patched, encoding="utf-8")
    return changed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    changed = []
    for path, transform in (
        (DESTINATIONS, patch_destinations),
        (ROUTER, patch_router),
        (DISCOVER, patch_discover),
    ):
        if apply(path, transform, args.check):
            changed.append(str(path.relative_to(ROOT)))
    if args.check:
        print("catalogue_index_ui_patch=present")
    else:
        print("catalogue_index_ui_patch=applied")
        for path in changed:
            print(f"changed={path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
