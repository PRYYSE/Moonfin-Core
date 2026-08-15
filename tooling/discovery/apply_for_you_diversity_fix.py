#!/usr/bin/env python3
"""Apply the screenshot-driven For You diversity/presentation fix exactly once."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VM = ROOT / "lib/data/viewmodels/seerr_deep_discovery_view_model.dart"
SCREEN = ROOT / "lib/ui/screens/seerr/seerr_discover_screen.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one marker, found {count}")
    return text.replace(old, new, 1)


def patch_vm() -> None:
    text = VM.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "import '../services/seerr/seerr_discovery_personalisation_service.dart';\n",
        "import '../services/seerr/seerr_discovery_personalisation_service.dart';\n"
        "import '../services/seerr/seerr_discovery_personal_presentation.dart';\n",
        "personal presentation import",
    )

    old = """    final session = _sessions.putIfAbsent(tab.id, SeerrDiscoverySession.new);\n    final rendered = <SeerrDeepDiscoveryRow>[];\n    for (final candidate in loaded.whereType<SeerrDeepDiscoveryRow>()) {\n      if (candidate.error != null) {\n        if (candidate.section.isAnchor) rendered.add(candidate);\n        continue;\n      }\n      var items = candidate.items;\n      if (candidate.section.sessionDedup && items.isNotEmpty) {\n        items = session.filterFresh<SeerrDiscoverItem>(\n          group: candidate.section.dedupGroup,\n          sharedGroup: 'tab:${tab.id}',\n          items: items,\n          identity: (item) => _identity(candidate.section, item),\n          minimumRetained: candidate.section.minItems,\n        );\n      }\n      if (items.length < candidate.section.minItems) continue;\n      rendered.add(candidate.copyWith(items: items));\n    }\n"""
    new = """    final session = _sessions.putIfAbsent(tab.id, SeerrDiscoverySession.new);\n    final rendered = <SeerrDeepDiscoveryRow>[];\n    final usedPersonalTitles = <String>{};\n    final surfacedPersonalFamilies = <String>{};\n    for (final candidate in loaded.whereType<SeerrDeepDiscoveryRow>()) {\n      if (candidate.error != null) {\n        if (candidate.section.isAnchor) rendered.add(candidate);\n        continue;\n      }\n      var items = candidate.items;\n      if (candidate.section.sessionDedup && items.isNotEmpty) {\n        items = session.filterFresh<SeerrDiscoverItem>(\n          group: candidate.section.dedupGroup,\n          sharedGroup: 'tab:${tab.id}',\n          items: items,\n          identity: (item) => _identity(candidate.section, item),\n          minimumRetained: candidate.section.minItems,\n        );\n      }\n      if (candidate.isPersonalised && items.isNotEmpty) {\n        items = SeerrDiscoveryPersonalPresentation.diversifyPreview(\n          items,\n          minimumRetained: candidate.section.minItems,\n          previouslySurfacedFamilies: surfacedPersonalFamilies,\n        );\n      }\n      if (items.length < candidate.section.minItems) continue;\n\n      final title = candidate.isPersonalised\n          ? SeerrDiscoveryPersonalPresentation.displayTitle(\n              candidate.section,\n              candidate.title,\n              usedTitles: usedPersonalTitles,\n            )\n          : candidate.title;\n      rendered.add(candidate.copyWith(items: items, title: title));\n    }\n"""
    text = replace_once(text, old, new, "For You render policy")
    VM.write_text(text, encoding="utf-8")


def patch_screen() -> None:
    text = SCREEN.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "      height: 62 * desktopScale,\n",
        "      height: 70 * desktopScale,\n",
        "tab outer height",
    )
    text = replace_once(
        text,
        "        itemSpacing: 8 * desktopScale,\n        height: 54 * desktopScale,\n",
        "        itemSpacing: 12 * desktopScale,\n        height: 60 * desktopScale,\n",
        "tab spacing",
    )
    text = replace_once(
        text,
        "          20 * desktopScale,\n          4 * desktopScale,\n          20 * desktopScale,\n          4 * desktopScale,\n",
        "          24 * desktopScale,\n          5 * desktopScale,\n          24 * desktopScale,\n          5 * desktopScale,\n",
        "tab rail padding",
    )
    SCREEN.write_text(text, encoding="utf-8")


def main() -> int:
    patch_vm()
    patch_screen()
    print("For You diversity/presentation patch applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
