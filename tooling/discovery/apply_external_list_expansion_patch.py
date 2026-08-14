#!/usr/bin/env python3
"""Enable full-screen See All for configured external Discovery lists.

The landing List row and expanded grid share the same configured-list cache and
source order. Rich TMDb refinements/sorting stay disabled for external lists.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SERVICE = ROOT / "lib/data/services/seerr/seerr_discovery_configured_lists_service.dart"
VM = ROOT / "lib/data/viewmodels/seerr_browse_view_model.dart"
BROWSE = ROOT / "lib/ui/screens/seerr/seerr_browse_screen.dart"
DISCOVER = ROOT / "lib/ui/screens/seerr/seerr_discover_screen.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_service(text: str) -> str:
    if "Future<SeerrDiscoverPage> loadQuery(" in text:
        return text
    marker = "  void clear() => _itemsByStableId.clear();\n"
    addition = """  Future<SeerrDiscoverPage> loadQuery(
    SeerrDiscoveryQuery query, {
    int page = 1,
    bool forceRefresh = false,
  }) {
    if (query.source != SeerrDiscoverySource.externalList) {
      throw ArgumentError.value(
        query.source,
        'query.source',
        'Configured Lists only execute externalList queries',
      );
    }
    final stableId = query.listId;
    if (stableId == null || stableId.isEmpty) {
      throw StateError('Configured external-list query has no listId');
    }
    return load(
      SeerrDiscoverySection(
        id: 'expanded-configured-list',
        title: 'Configured List',
        query: query,
        minItems: 1,
        previewLimit: pageSize,
        pool: 'configured-lists',
        dedupGroup: 'configured-lists-expanded',
        sessionDedup: false,
      ),
      page: page,
      forceRefresh: forceRefresh,
    );
  }

"""
    return replace_once(text, marker, addition + marker, "configured list loadQuery")


def patch_vm(text: str) -> str:
    if "final SeerrDiscoveryConfiguredListsService? configuredLists;" in text:
        return text
    text = replace_once(
        text,
        "import '../services/seerr/seerr_discovery_browse_refinements.dart';\n",
        "import '../services/seerr/seerr_discovery_browse_refinements.dart';\n"
        "import '../services/seerr/seerr_discovery_configured_lists_service.dart';\n",
        "browse VM external import",
    )
    text = replace_once(
        text,
        "  final String? filterType;\n\n"
        "  /// Exact immutable base query from a deep-Discovery landing lane.\n",
        "  final String? filterType;\n"
        "  final SeerrDiscoveryConfiguredListsService? configuredLists;\n\n"
        "  /// Exact immutable base query from a deep-Discovery landing lane.\n",
        "browse VM external field",
    )
    text = replace_once(
        text,
        "  bool get supportsRichRefinements =>\n"
        "      baseQuery?.source == SeerrDiscoverySource.discoverMovies ||\n"
        "      baseQuery?.source == SeerrDiscoverySource.discoverTv;\n\n"
        "  List<SeerrSortOption> get sortOptions => getSortOptionsFor(mediaType);\n",
        "  bool get isExternalList =>\n"
        "      baseQuery?.source == SeerrDiscoverySource.externalList;\n"
        "  bool get supportsSort => !isExternalList;\n"
        "  bool get supportsRichRefinements =>\n"
        "      baseQuery?.source == SeerrDiscoverySource.discoverMovies ||\n"
        "      baseQuery?.source == SeerrDiscoverySource.discoverTv;\n\n"
        "  List<SeerrSortOption> get sortOptions => getSortOptionsFor(mediaType);\n",
        "browse VM external capabilities",
    )
    text = replace_once(
        text,
        "    this.filterType,\n"
        "    this.baseQuery,\n"
        "  }) {\n",
        "    this.filterType,\n"
        "    this.baseQuery,\n"
        "    this.configuredLists,\n"
        "  }) {\n",
        "browse VM constructor",
    )
    text = replace_once(
        text,
        "  void setSortBy(SeerrSortOption option) {\n"
        "    final safeValue = SeerrDiscoverySortPolicy.normalise(option.value);\n",
        "  void setSortBy(SeerrSortOption option) {\n"
        "    if (!supportsSort) return;\n"
        "    final safeValue = SeerrDiscoverySortPolicy.normalise(option.value);\n",
        "browse VM disable external sort",
    )
    text = replace_once(
        text,
        "    final deepQuery = baseQuery;\n"
        "    if (deepQuery != null) {\n"
        "      final refined = supportsRichRefinements\n",
        "    final deepQuery = baseQuery;\n"
        "    if (deepQuery != null) {\n"
        "      if (deepQuery.source == SeerrDiscoverySource.externalList) {\n"
        "        final lists = configuredLists;\n"
        "        if (lists == null) {\n"
        "          throw StateError('Configured external-list service is unavailable');\n"
        "        }\n"
        "        return lists.loadQuery(deepQuery, page: page);\n"
        "      }\n"
        "      final refined = supportsRichRefinements\n",
        "browse VM external fetch",
    )
    return text


def patch_browse(text: str) -> str:
    if "configuredLists:" in text:
        return text
    text = replace_once(
        text,
        "import '../../../data/services/seerr/seerr_discovery_browse_refinements.dart';\n",
        "import '../../../data/services/seerr/seerr_discovery_browse_refinements.dart';\n"
        "import '../../../data/services/seerr/seerr_discovery_configured_lists_service.dart';\n",
        "browse external import",
    )
    text = replace_once(
        text,
        "      filterType: widget.filterType,\n"
        "      baseQuery: widget.baseQuery,\n"
        "    );\n",
        "      filterType: widget.filterType,\n"
        "      baseQuery: widget.baseQuery,\n"
        "      configuredLists:\n"
        "          widget.baseQuery?.source == SeerrDiscoverySource.externalList &&\n"
        "                  GetIt.instance.isRegistered<\n"
        "                    SeerrDiscoveryConfiguredListsService\n"
        "                  >()\n"
        "              ? GetIt.instance<SeerrDiscoveryConfiguredListsService>()\n"
        "              : null,\n"
        "    );\n",
        "browse external service injection",
    )
    text = replace_once(
        text,
        "            onHome: () => context.go(Destinations.home),\n"
        "            onSort: () => _showSortDialog(context),\n"
        "            showRefine: _vm?.supportsRichRefinements ?? false,\n",
        "            onHome: () => context.go(Destinations.home),\n"
        "            showSort: _vm?.supportsSort ?? true,\n"
        "            onSort: () => _showSortDialog(context),\n"
        "            showRefine: _vm?.supportsRichRefinements ?? false,\n",
        "browse header showSort arg",
    )
    text = replace_once(
        text,
        "  final VoidCallback onHome;\n"
        "  final VoidCallback onSort;\n"
        "  final bool showRefine;\n",
        "  final VoidCallback onHome;\n"
        "  final bool showSort;\n"
        "  final VoidCallback onSort;\n"
        "  final bool showRefine;\n",
        "browse header showSort field",
    )
    text = replace_once(
        text,
        "    required this.onHome,\n"
        "    required this.onSort,\n"
        "    required this.showRefine,\n",
        "    required this.onHome,\n"
        "    required this.showSort,\n"
        "    required this.onSort,\n"
        "    required this.showRefine,\n",
        "browse header showSort constructor",
    )
    text = replace_once(
        text,
        "              _ToolbarButton(icon: Icons.sort, onTap: onSort),\n"
        "              if (showRefine) ...[\n",
        "              if (showSort)\n"
        "                _ToolbarButton(icon: Icons.sort, onTap: onSort),\n"
        "              if (showRefine) ...[\n",
        "browse hide external sort button",
    )
    return text


def patch_discover(text: str) -> str:
    old = """    return row.section.expandable &&
        source != SeerrDiscoverySource.personalised &&
        source != SeerrDiscoverySource.externalList;
"""
    new = """    return row.section.expandable &&
        source != SeerrDiscoverySource.personalised;
"""
    if new in text:
        return text
    return replace_once(text, old, new, "landing external See All")


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
        (SERVICE, patch_service),
        (VM, patch_vm),
        (BROWSE, patch_browse),
        (DISCOVER, patch_discover),
    ):
        if apply(path, transform, args.check):
            changed.append(str(path.relative_to(ROOT)))
    if args.check:
        print("external_list_expansion_patch=present")
    else:
        print("external_list_expansion_patch=applied")
        for path in changed:
            print(f"changed={path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
