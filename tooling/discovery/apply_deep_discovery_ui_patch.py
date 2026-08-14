#!/usr/bin/env python3
"""Apply the focused deep-Discovery UI integration to Moonfin-Core.

The patch intentionally keeps the existing Seerr screen's backdrop, cards,
Requests entry, detail routing and D-pad focus behaviour. It only swaps the
landing data model to the server-driven deep VM, adds the destination tab rail,
and teaches the existing browse route to accept an exact Discovery query.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DISCOVER = ROOT / "lib/ui/screens/seerr/seerr_discover_screen.dart"
BROWSE = ROOT / "lib/ui/screens/seerr/seerr_browse_screen.dart"
ROUTER = ROOT / "lib/ui/navigation/app_router.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_browse(text: str) -> str:
    if "final SeerrDiscoveryQuery? baseQuery;" in text:
        return text
    text = replace_once(
        text,
        "import '../../../data/services/seerr/seerr_api_models.dart';\n"
        "import '../../../data/viewmodels/seerr_browse_view_model.dart';",
        "import '../../../data/services/seerr/seerr_api_models.dart';\n"
        "import '../../../data/services/seerr/seerr_discovery_schema.dart';\n"
        "import '../../../data/viewmodels/seerr_browse_view_model.dart';",
        "browse import",
    )
    text = replace_once(
        text,
        "  final String? filterType;\n\n"
        "  const SeerrBrowseScreen({\n"
        "    super.key,\n"
        "    this.filterId,\n"
        "    this.filterName,\n"
        "    this.mediaType,\n"
        "    this.filterType,\n"
        "  });",
        "  final String? filterType;\n"
        "  final SeerrDiscoveryQuery? baseQuery;\n\n"
        "  const SeerrBrowseScreen({\n"
        "    super.key,\n"
        "    this.filterId,\n"
        "    this.filterName,\n"
        "    this.mediaType,\n"
        "    this.filterType,\n"
        "    this.baseQuery,\n"
        "  });",
        "browse constructor",
    )
    text = replace_once(
        text,
        "      filterId: widget.filterId,\n"
        "      mediaType: widget.mediaType ?? 'movie',\n"
        "      filterType: widget.filterType,\n"
        "    );",
        "      filterId: widget.filterId,\n"
        "      mediaType: widget.baseQuery?.mediaType ?? widget.mediaType ?? 'movie',\n"
        "      filterType: widget.filterType,\n"
        "      baseQuery: widget.baseQuery,\n"
        "    );",
        "browse view model",
    )
    return text


def patch_router(text: str) -> str:
    if "SeerrDiscoveryRouteCodec.decode(params)" in text:
        return text
    text = replace_once(
        text,
        "import '../../data/services/connectivity_service.dart';",
        "import '../../data/services/connectivity_service.dart';\n"
        "import '../../data/services/seerr/seerr_discovery_route_codec.dart';",
        "router import",
    )
    text = replace_once(
        text,
        "    GoRoute(\n"
        "      path: Destinations.seerrBrowse,\n"
        "      builder: (context, state) {\n"
        "        final params = state.uri.queryParameters;\n"
        "        return SeerrBrowseScreen(\n"
        "          filterId: params['filterId'],\n"
        "          filterName: params['filterName'],\n"
        "          mediaType: params['mediaType'],\n"
        "          filterType: params['filterType'],\n"
        "        );\n"
        "      },\n"
        "    ),",
        "    GoRoute(\n"
        "      path: Destinations.seerrBrowse,\n"
        "      builder: (context, state) {\n"
        "        final params = state.uri.queryParameters;\n"
        "        final deepRoute = params.containsKey('source')\n"
        "            ? SeerrDiscoveryRouteCodec.decode(params)\n"
        "            : null;\n"
        "        return SeerrBrowseScreen(\n"
        "          filterId: deepRoute == null ? params['filterId'] : null,\n"
        "          filterName: deepRoute?.title ?? params['filterName'],\n"
        "          mediaType: deepRoute?.query.mediaType ?? params['mediaType'],\n"
        "          filterType: deepRoute == null ? params['filterType'] : null,\n"
        "          baseQuery: deepRoute?.query,\n"
        "        );\n"
        "      },\n"
        "    ),",
        "router Seerr browse route",
    )
    return text


def patch_discover(text: str) -> str:
    if "SeerrDeepDiscoveryViewModel? _viewModel;" in text:
        return text

    text = replace_once(
        text,
        "import '../../../data/services/seerr/seerr_api_models.dart';\n"
        "import '../../../data/viewmodels/seerr_discover_view_model.dart';",
        "import '../../../data/services/seerr/seerr_api_models.dart';\n"
        "import '../../../data/services/seerr/seerr_discovery_route_codec.dart';\n"
        "import '../../../data/services/seerr/seerr_discovery_schema.dart';\n"
        "import '../../../data/viewmodels/seerr_deep_discovery_view_model.dart';\n"
        "import '../../../data/viewmodels/seerr_discover_view_model.dart';",
        "discover imports",
    )
    text = replace_once(
        text,
        "  SeerrDiscoverViewModel? _viewModel;",
        "  SeerrDeepDiscoveryViewModel? _viewModel;",
        "discover VM type",
    )
    text = replace_once(
        text,
        "  final _requestsEntryFocusNode = FocusNode(debugLabel: 'seerrRequestsEntry');\n"
        "  int _badgeCount = 0;",
        "  final _requestsEntryFocusNode = FocusNode(debugLabel: 'seerrRequestsEntry');\n"
        "  final _tabRowKey = GlobalKey<LockedFocusRowState>();\n"
        "  final _tabScrollController = ScrollController();\n"
        "  int _badgeCount = 0;",
        "discover tab state",
    )
    text = replace_once(
        text,
        "    final vm = await GetIt.instance.getAsync<SeerrDiscoverViewModel>();",
        "    final vm = await GetIt.instance.getAsync<SeerrDeepDiscoveryViewModel>();",
        "discover VM init",
    )
    text = replace_once(
        text,
        "    _scrollController.dispose();\n"
        "    for (final controller in _rowScrollControllers.values) {",
        "    _scrollController.dispose();\n"
        "    _tabScrollController.dispose();\n"
        "    for (final controller in _rowScrollControllers.values) {",
        "discover tab controller dispose",
    )

    old_vertical = """    } else if (isUp && targetIndex == -1) {
      _restoreNavbarToNormalPosition();
      // The requests entry sits between the rows and the navbar.
      if (_requestsEntryFocusNode.context != null) {
        _requestsEntryFocusNode.requestFocus();
        return true;
      }
      final prefs = GetIt.instance<UserPreferences>();
      final navbarPosition = prefs.get(UserPreferences.navbarPosition);
      if (navbarPosition == NavbarPosition.top) {
        NavigationLayout.focusNavbarNotifier.value?.call();
      }
      return true;
    }
"""
    new_vertical = """    } else if (isUp && targetIndex == -1) {
      _restoreNavbarToNormalPosition();
      _focusActiveTab();
      return true;
    }
"""
    text = replace_once(text, old_vertical, new_vertical, "discover row-up navigation")

    old_key = """    // The requests entry sits between the rows and the navbar.
    if (_requestsEntryFocusNode.context != null) {
      _restoreNavbarToNormalPosition();
      _requestsEntryFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    _restoreNavbarToNormalPosition();
    NavigationLayout.focusNavbarNotifier.value?.call();
    return KeyEventResult.handled;
"""
    new_key = """    _restoreNavbarToNormalPosition();
    _focusActiveTab();
    return KeyEventResult.handled;
"""
    text = replace_once(text, old_key, new_key, "discover first-row Up")

    text = replace_once(
        text,
        "  void _onPrefsChanged() {\n"
        "    _viewModel?.applyRowConfig();\n"
        "  }",
        "  void _onPrefsChanged() {\n"
        "    if (mounted) setState(() {});\n"
        "  }",
        "discover prefs listener",
    )
    old_focusable = """  bool _rowHasFocusableContent(SeerrDiscoverRow row) {
    if (row.isGenreRow) return row.genres.isNotEmpty;
    if (row.isNetworkRow) return row.networks.isNotEmpty;
    if (row.isStudioRow) return row.studios.isNotEmpty;
    return row.items.isNotEmpty;
  }
"""
    new_focusable = """  bool _rowHasFocusableContent(SeerrDeepDiscoveryRow row) =>
      row.items.isNotEmpty;
"""
    text = replace_once(text, old_focusable, new_focusable, "discover focusable row")

    text = replace_once(
        text,
        "                  onDown: () => _initialFocusNode.requestFocus(),",
        "                  onDown: _focusActiveTab,",
        "requests Down navigation",
    )

    # Add the tab rail as the first list item and shift the existing row index
    # into logical row coordinates. This preserves the existing visual scroll,
    # first-row focus and backdrop behaviour.
    text = replace_once(
        text,
        "      itemCount: rows.length,\n"
        "      scrollCacheExtent: const ScrollCacheExtent.pixels(600.0),\n"
        "      itemBuilder: (context, index) {\n"
        "        final row = rows[index];",
        "      itemCount: rows.length + 1,\n"
        "      scrollCacheExtent: const ScrollCacheExtent.pixels(600.0),\n"
        "      itemBuilder: (context, listIndex) {\n"
        "        if (listIndex == 0) return _buildDiscoveryTabs();\n"
        "        final rowIndex = listIndex - 1;\n"
        "        final row = rows[rowIndex];",
        "discover list tab insertion",
    )

    old_row_builder = """        final isFirstFocusableRow = index == _firstFocusableVisibleIndex;
        final autofocusRow = isFirstFocusableRow && _wantsInitialFocus;
        final firstNode = autofocusRow ? _initialFocusNode : null;
        Widget rowWidget;
        if (row.isGenreRow) {
          rowWidget = _buildGenreRow(
            row,
            index,
            isFirstVisibleRow: isFirstFocusableRow,
            autofocusFirst: autofocusRow,
            firstFocusNode: firstNode,
          );
        } else if (row.isNetworkRow) {
          rowWidget = _buildNetworkRow(
            row,
            index,
            isFirstVisibleRow: isFirstFocusableRow,
            autofocusFirst: autofocusRow,
            firstFocusNode: firstNode,
          );
        } else if (row.isStudioRow) {
          rowWidget = _buildStudioRow(
            row,
            index,
            isFirstVisibleRow: isFirstFocusableRow,
            autofocusFirst: autofocusRow,
            firstFocusNode: firstNode,
          );
        } else {
          rowWidget = _buildMediaRow(
            row,
            index,
            isFirstVisibleRow: isFirstFocusableRow,
            autofocusFirst: autofocusRow,
            firstFocusNode: firstNode,
          );
        }
"""
    new_row_builder = """        final isFirstFocusableRow =
            rowIndex == _firstFocusableVisibleIndex;
        final autofocusRow = isFirstFocusableRow && _wantsInitialFocus;
        final firstNode = autofocusRow ? _initialFocusNode : null;
        final rowWidget = _buildMediaRow(
          row,
          rowIndex,
          isFirstVisibleRow: isFirstFocusableRow,
          autofocusFirst: autofocusRow,
          firstFocusNode: firstNode,
        );
"""
    text = replace_once(text, old_row_builder, new_row_builder, "discover media-only rows")
    text = replace_once(
        text,
        "                if (index == _firstFocusableVisibleIndex) {",
        "                if (rowIndex == _firstFocusableVisibleIndex) {",
        "discover ensure-visible row index",
    )

    text = replace_once(
        text,
        "  Widget _buildRowContainer({\n"
        "    required String title,\n"
        "    required double rowHeight,\n"
        "    required bool isLoading,\n"
        "    required bool hasItems,\n"
        "    required ScrollController scrollController,\n"
        "    required Widget child,\n"
        "  }) {",
        "  Widget _buildRowContainer({\n"
        "    required String title,\n"
        "    required double rowHeight,\n"
        "    required bool isLoading,\n"
        "    required bool hasItems,\n"
        "    required ScrollController scrollController,\n"
        "    required Widget child,\n"
        "    Widget? trailing,\n"
        "  }) {",
        "discover row container signature",
    )
    text = replace_once(
        text,
        "      showControls: showControls,\n"
        "      builder: (context, controller) {",
        "      showControls: showControls,\n"
        "      trailing: trailing,\n"
        "      builder: (context, controller) {",
        "discover row container trailing",
    )
    text = replace_once(
        text,
        "  Widget _buildMediaRow(\n"
        "    SeerrDiscoverRow row,",
        "  Widget _buildMediaRow(\n"
        "    SeerrDeepDiscoveryRow row,",
        "discover media row type",
    )
    text = replace_once(
        text,
        "        onLeftEdge: _onRowLeftEdge,\n"
        "        onVerticalNavigation: (isUp) => _onRowVerticalNavigation(rowIndex, isUp),",
        "        onLeftEdge: _onRowLeftEdge,\n"
        "        onRightEdge: _canExpand(row) ? () => _openExpandedRow(row) : null,\n"
        "        onVerticalNavigation: (isUp) => _onRowVerticalNavigation(rowIndex, isUp),",
        "discover See All right edge",
    )
    text = replace_once(
        text,
        "      scrollController: _getRowScroll(rowIndex),\n"
        "      child: child,\n"
        "    );\n"
        "  }\n\n"
        "  Widget _buildGenreRow(",
        "      scrollController: _getRowScroll(rowIndex),\n"
        "      trailing: _canExpand(row)\n"
        "          ? TextButton(\n"
        "              onPressed: () => _openExpandedRow(row),\n"
        "              child: const Text('See All'),\n"
        "            )\n"
        "          : null,\n"
        "      child: child,\n"
        "    );\n"
        "  }\n\n"
        "  Widget _buildGenreRow(",
        "discover See All header",
    )

    helpers = r'''
  bool _canExpand(SeerrDeepDiscoveryRow row) {
    final source = row.section.query.source;
    return row.section.expandable &&
        source != SeerrDiscoverySource.personalised &&
        source != SeerrDiscoverySource.externalList;
  }

  void _openExpandedRow(SeerrDeepDiscoveryRow row) {
    if (!_canExpand(row)) return;
    final uri = Uri(
      path: Destinations.seerrBrowse,
      queryParameters: SeerrDiscoveryRouteCodec.encode(
        row.section.query,
        title: row.title,
      ),
    );
    context.push(uri.toString());
  }

  void _focusActiveTab() {
    final vm = _viewModel;
    final state = _tabRowKey.currentState;
    if (vm == null || state == null || vm.tabs.isEmpty) {
      _requestsEntryFocusNode.requestFocus();
      return;
    }
    final index = vm.tabs.indexWhere((tab) => tab.id == vm.activeTabId);
    state.requestFocusAt(index < 0 ? 0 : index);
  }

  bool _onTabVerticalNavigation(bool isUp) {
    if (isUp) {
      if (_requestsEntryFocusNode.context != null) {
        _requestsEntryFocusNode.requestFocus();
      } else {
        NavigationLayout.focusNavbarNotifier.value?.call();
      }
      return true;
    }
    if (_viewModel?.rows.isNotEmpty ?? false) {
      _getRowKey(0).currentState?.requestFocusAt(0);
    }
    return true;
  }

  Future<void> _selectDiscoveryTab(SeerrDiscoveryTab tab) async {
    final vm = _viewModel;
    if (vm == null || vm.activeTabId == tab.id) return;
    _selectionDebounce?.cancel();
    _backdropDebounce?.cancel();
    if (mounted) {
      setState(() {
        _selectedItem = null;
        _backdropUrl = null;
        _isFirstRowFocused = false;
      });
    }
    for (final controller in _rowScrollControllers.values) {
      if (controller.hasClients) controller.jumpTo(0);
    }
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    await vm.selectTab(tab.id);
  }

  Widget _buildDiscoveryTabs() {
    final vm = _viewModel;
    if (vm == null || vm.tabs.isEmpty) return const SizedBox.shrink();
    final desktopScale = GetIt.instance<UserPreferences>()
        .get(UserPreferences.desktopUiScale)
        .scaleFactor;
    return SizedBox(
      height: 62 * desktopScale,
      child: LockedFocusRow<SeerrDiscoveryTab>(
        key: _tabRowKey,
        items: vm.tabs,
        hubKey: 'seerr_deep_discovery_tabs',
        controller: _tabScrollController,
        itemExtent: 150 * desktopScale,
        itemSpacing: 8 * desktopScale,
        height: 54 * desktopScale,
        padding: EdgeInsets.fromLTRB(
          20 * desktopScale,
          4 * desktopScale,
          20 * desktopScale,
          4 * desktopScale,
        ),
        onLeftEdge: _onRowLeftEdge,
        onVerticalNavigation: _onTabVerticalNavigation,
        onTap: (_, tab) => unawaited(_selectDiscoveryTab(tab)),
        itemBuilder: (context, tab, index, isFocused) {
          final active = tab.id == vm.activeTabId;
          final accent = AppColorScheme.accent;
          final surface = Theme.of(context).colorScheme.surface;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: active
                  ? accent.withValues(alpha: 0.20)
                  : surface.withValues(alpha: isFocused ? 0.72 : 0.45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isFocused || active
                    ? accent.withValues(alpha: isFocused ? 0.95 : 0.55)
                    : AppColorScheme.onSurface.withValues(alpha: 0.12),
                width: isFocused ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              tab.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColorScheme.onSurface,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
          );
        },
      ),
    );
  }

'''
    marker = "  Widget _buildRowContainer({\n"
    if marker not in text:
        raise RuntimeError("discover helpers: row container marker not found")
    text = text.replace(marker, helpers + marker, 1)
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
        (BROWSE, patch_browse),
        (ROUTER, patch_router),
        (DISCOVER, patch_discover),
    ):
        if apply(path, transform, args.check):
            changed.append(str(path.relative_to(ROOT)))

    if args.check:
        print("deep_discovery_ui_patch=present")
    else:
        print("deep_discovery_ui_patch=applied")
        for path in changed:
            print(f"changed={path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
