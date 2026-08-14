#!/usr/bin/env python3
"""Wire rich browse refinements into the already formatted deep browse UI."""

from __future__ import annotations

import argparse
from pathlib import Path

import apply_rich_browse_filters_patch as v1

ROOT = Path(__file__).resolve().parents[2]
VM = ROOT / "lib/data/viewmodels/seerr_browse_view_model.dart"
SCREEN = ROOT / "lib/ui/screens/seerr/seerr_browse_screen.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_screen(text: str) -> str:
    if "_showRefinementDialog" in text:
        return text

    text = replace_once(
        text,
        "import '../../../data/services/seerr/seerr_api_models.dart';\n"
        "import '../../../data/services/seerr/seerr_discovery_schema.dart';\n",
        "import '../../../data/services/seerr/seerr_api_models.dart';\n"
        "import '../../../data/services/seerr/seerr_discovery_browse_refinements.dart';\n"
        "import '../../../data/services/seerr/seerr_discovery_schema.dart';\n",
        "screen refinement model import",
    )
    text = replace_once(
        text,
        "import '../../navigation/destinations.dart';\n",
        "import '../../navigation/destinations.dart';\n"
        "import 'seerr_discovery_refinement_dialog.dart';\n",
        "screen dialog import",
    )
    text = replace_once(
        text,
        "            onSort: () => _showSortDialog(context),\n"
        "            onSettings: () => _showSettingsDialog(context),\n",
        "            onSort: () => _showSortDialog(context),\n"
        "            showRefine: _vm?.supportsRichRefinements ?? false,\n"
        "            refinementCount: _vm?.refinementCount ?? 0,\n"
        "            onRefine: () => _showRefinementDialog(context),\n"
        "            onSettings: () => _showSettingsDialog(context),\n",
        "screen header args",
    )
    text = replace_once(
        text,
        "  void _showSortDialog(BuildContext context) {\n"
        "    showFocusRestoringDialog(\n"
        "      context: context,\n"
        "      builder: (_) => _SeerrSortDialog(vm: _vm!),\n"
        "    );\n"
        "  }\n\n"
        "  void _showSettingsDialog(BuildContext context) {\n",
        "  void _showSortDialog(BuildContext context) {\n"
        "    showFocusRestoringDialog(\n"
        "      context: context,\n"
        "      builder: (_) => _SeerrSortDialog(vm: _vm!),\n"
        "    );\n"
        "  }\n\n"
        "  Future<void> _showRefinementDialog(BuildContext context) async {\n"
        "    final vm = _vm;\n"
        "    if (vm == null || !vm.supportsRichRefinements) return;\n"
        "    final result = await showFocusRestoringDialog<\n"
        "        SeerrDiscoveryBrowseRefinements>(\n"
        "      context: context,\n"
        "      builder: (_) => SeerrDiscoveryRefinementDialog(\n"
        "        mediaType: vm.mediaType,\n"
        "        initial: vm.refinements,\n"
        "      ),\n"
        "    );\n"
        "    if (result != null) vm.setRefinements(result);\n"
        "  }\n\n"
        "  void _showSettingsDialog(BuildContext context) {\n",
        "screen refinement method",
    )
    text = replace_once(
        text,
        "  final VoidCallback onHome;\n"
        "  final VoidCallback onSort;\n"
        "  final VoidCallback onSettings;\n",
        "  final VoidCallback onHome;\n"
        "  final VoidCallback onSort;\n"
        "  final bool showRefine;\n"
        "  final int refinementCount;\n"
        "  final VoidCallback onRefine;\n"
        "  final VoidCallback onSettings;\n",
        "header fields",
    )
    text = replace_once(
        text,
        "    required this.onHome,\n"
        "    required this.onSort,\n"
        "    required this.onSettings,\n",
        "    required this.onHome,\n"
        "    required this.onSort,\n"
        "    required this.showRefine,\n"
        "    required this.refinementCount,\n"
        "    required this.onRefine,\n"
        "    required this.onSettings,\n",
        "header constructor",
    )
    text = replace_once(
        text,
        "              _ToolbarButton(icon: Icons.sort, onTap: onSort),\n"
        "              const SizedBox(width: 4),\n"
        "              _ToolbarButton(icon: Icons.settings, onTap: onSettings),\n",
        "              _ToolbarButton(icon: Icons.sort, onTap: onSort),\n"
        "              if (showRefine) ...[\n"
        "                const SizedBox(width: 4),\n"
        "                Stack(\n"
        "                  clipBehavior: Clip.none,\n"
        "                  children: [\n"
        "                    _ToolbarButton(icon: Icons.tune, onTap: onRefine),\n"
        "                    if (refinementCount > 0)\n"
        "                      Positioned(\n"
        "                        right: -4,\n"
        "                        top: -4,\n"
        "                        child: Container(\n"
        "                          padding: const EdgeInsets.symmetric(\n"
        "                            horizontal: 5,\n"
        "                            vertical: 2,\n"
        "                          ),\n"
        "                          decoration: BoxDecoration(\n"
        "                            color: _seerrAccent,\n"
        "                            borderRadius: BorderRadius.circular(10),\n"
        "                          ),\n"
        "                          child: Text(\n"
        "                            refinementCount.toString(),\n"
        "                            style: const TextStyle(\n"
        "                              fontSize: 10,\n"
        "                              fontWeight: FontWeight.w700,\n"
        "                            ),\n"
        "                          ),\n"
        "                        ),\n"
        "                      ),\n"
        "                  ],\n"
        "                ),\n"
        "              ],\n"
        "              const SizedBox(width: 4),\n"
        "              _ToolbarButton(icon: Icons.settings, onTap: onSettings),\n",
        "toolbar refine control",
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
    for path, transform in ((VM, v1.patch_vm), (SCREEN, patch_screen)):
        if apply(path, transform, args.check):
            changed.append(str(path.relative_to(ROOT)))
    if args.check:
        print("rich_browse_filters_patch_v2=present")
    else:
        print("rich_browse_filters_patch_v2=applied")
        for path in changed:
            print(f"changed={path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
