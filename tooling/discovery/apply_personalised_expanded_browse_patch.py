#!/usr/bin/env python3
"""Enable full-screen See All for personalised Discovery lanes.

The expanded grid reuses the same user-scoped SeerrDiscoveryPersonalisationService
and the exact landing section ID, so it pages the same accepted Home recommendation
cache instead of generating a different recommendation slot.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VM = ROOT / "lib/data/viewmodels/seerr_browse_view_model.dart"
BROWSE = ROOT / "lib/ui/screens/seerr/seerr_browse_screen.dart"
DISCOVER = ROOT / "lib/ui/screens/seerr/seerr_discover_screen.dart"
DEEP_VM = ROOT / "lib/data/viewmodels/seerr_deep_discovery_view_model.dart"
ROUTER = ROOT / "lib/ui/navigation/app_router.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_vm(text: str) -> str:
    if "final SeerrDiscoveryPersonalisationService? personalisation;" in text:
        return text
    text = replace_once(
        text,
        "import '../services/seerr/seerr_discovery_configured_lists_service.dart';\n",
        "import '../services/seerr/seerr_discovery_configured_lists_service.dart';\n"
        "import '../services/seerr/seerr_discovery_personalisation_service.dart';\n",
        "browse VM personal import",
    )
    text = replace_once(
        text,
        "  final String? filterType;\n"
        "  final SeerrDiscoveryConfiguredListsService? configuredLists;\n\n",
        "  final String? filterType;\n"
        "  final String? sectionId;\n"
        "  final SeerrDiscoveryConfiguredListsService? configuredLists;\n"
        "  final SeerrDiscoveryPersonalisationService? personalisation;\n\n",
        "browse VM personal fields",
    )
    text = replace_once(
        text,
        "  bool get isExternalList =>\n"
        "      baseQuery?.source == SeerrDiscoverySource.externalList;\n"
        "  bool get supportsSort => !isExternalList;\n",
        "  bool get isExternalList =>\n"
        "      baseQuery?.source == SeerrDiscoverySource.externalList;\n"
        "  bool get isPersonalised =>\n"
        "      baseQuery?.source == SeerrDiscoverySource.personalised;\n"
        "  bool get supportsSort => !isExternalList && !isPersonalised;\n",
        "browse VM personal capabilities",
    )
    text = replace_once(
        text,
        "    this.filterType,\n"
        "    this.baseQuery,\n"
        "    this.configuredLists,\n"
        "  }) {\n",
        "    this.filterType,\n"
        "    this.baseQuery,\n"
        "    this.sectionId,\n"
        "    this.configuredLists,\n"
        "    this.personalisation,\n"
        "  }) {\n",
        "browse VM personal constructor",
    )
    text = replace_once(
        text,
        "    final deepQuery = baseQuery;\n"
        "    if (deepQuery != null) {\n"
        "      if (deepQuery.source == SeerrDiscoverySource.externalList) {\n",
        "    final deepQuery = baseQuery;\n"
        "    if (deepQuery != null) {\n"
        "      if (deepQuery.source == SeerrDiscoverySource.personalised) {\n"
        "        final service = personalisation;\n"
        "        if (service == null) {\n"
        "          throw StateError('Personalised Discovery service is unavailable');\n"
        "        }\n"
        "        final stableSectionId = sectionId?.trim();\n"
        "        if (stableSectionId == null || stableSectionId.isEmpty) {\n"
        "          throw StateError('Personalised Discovery route has no sectionId');\n"
        "        }\n"
        "        return service\n"
        "            .load(\n"
        "              SeerrDiscoverySection(\n"
        "                id: stableSectionId,\n"
        "                title: '',\n"
        "                query: deepQuery,\n"
        "                minItems: 1,\n"
        "                previewLimit: SeerrDiscoveryPersonalisationService.pageSize,\n"
        "                sessionDedup: false,\n"
        "              ),\n"
        "              page: page,\n"
        "            )\n"
        "            .then((result) => result.page);\n"
        "      }\n"
        "      if (deepQuery.source == SeerrDiscoverySource.externalList) {\n",
        "browse VM personal fetch",
    )
    return text


def patch_browse(text: str) -> str:
    if "this.sectionId," in text and "personalisation:" in text:
        return text
    text = replace_once(
        text,
        "import '../../../data/services/seerr/seerr_discovery_configured_lists_service.dart';\n",
        "import '../../../data/services/seerr/seerr_discovery_configured_lists_service.dart';\n"
        "import '../../../data/services/seerr/seerr_discovery_personalisation_service.dart';\n",
        "browse screen personal import",
    )
    text = replace_once(
        text,
        "  final String? filterType;\n"
        "  final SeerrDiscoveryQuery? baseQuery;\n\n",
        "  final String? filterType;\n"
        "  final String? sectionId;\n"
        "  final SeerrDiscoveryQuery? baseQuery;\n\n",
        "browse screen section field",
    )
    text = replace_once(
        text,
        "    this.mediaType,\n"
        "    this.filterType,\n"
        "    this.baseQuery,\n"
        "  });\n",
        "    this.mediaType,\n"
        "    this.filterType,\n"
        "    this.sectionId,\n"
        "    this.baseQuery,\n"
        "  });\n",
        "browse screen constructor",
    )
    text = replace_once(
        text,
        "      filterType: widget.filterType,\n"
        "      baseQuery: widget.baseQuery,\n"
        "      configuredLists:\n",
        "      filterType: widget.filterType,\n"
        "      baseQuery: widget.baseQuery,\n"
        "      sectionId: widget.sectionId,\n"
        "      configuredLists:\n",
        "browse screen section injection",
    )
    text = replace_once(
        text,
        "              ? GetIt.instance<SeerrDiscoveryConfiguredListsService>()\n"
        "              : null,\n"
        "    );\n",
        "              ? GetIt.instance<SeerrDiscoveryConfiguredListsService>()\n"
        "              : null,\n"
        "      personalisation:\n"
        "          widget.baseQuery?.source == SeerrDiscoverySource.personalised &&\n"
        "                  GetIt.instance.isRegistered<\n"
        "                    SeerrDiscoveryPersonalisationService\n"
        "                  >()\n"
        "              ? GetIt.instance<SeerrDiscoveryPersonalisationService>()\n"
        "              : null,\n"
        "    );\n",
        "browse screen personal service injection",
    )
    return text


def patch_discover(text: str) -> str:
    text = replace_once(
        text,
        "  bool _canExpand(SeerrDeepDiscoveryRow row) {\n"
        "    final source = row.section.query.source;\n"
        "    return row.section.expandable &&\n"
        "        source != SeerrDiscoverySource.personalised;\n"
        "  }\n",
        "  bool _canExpand(SeerrDeepDiscoveryRow row) => row.section.expandable;\n",
        "landing personalised See All capability",
    )
    text = replace_once(
        text,
        "      queryParameters: SeerrDiscoveryRouteCodec.encode(\n"
        "        row.section.query,\n"
        "        title: row.title,\n"
        "      ),\n",
        "      queryParameters: SeerrDiscoveryRouteCodec.encode(\n"
        "        row.section.query,\n"
        "        title: row.title,\n"
        "        sectionId: row.section.id,\n"
        "      ),\n",
        "landing route section identity",
    )
    return text


def patch_deep_vm(text: str) -> str:
    old = """  bool get canExpand =>
      section.expandable &&
      section.query.source != SeerrDiscoverySource.externalList;
"""
    new = """  bool get canExpand => section.expandable;
"""
    if new in text:
        return text
    return replace_once(text, old, new, "deep row expand capability")


def patch_router(text: str) -> str:
    if "sectionId: deepRoute?.sectionId," in text:
        return text
    return replace_once(
        text,
        "          filterType: deepRoute == null ? params['filterType'] : null,\n"
        "          baseQuery: deepRoute?.query,\n",
        "          filterType: deepRoute == null ? params['filterType'] : null,\n"
        "          sectionId: deepRoute?.sectionId,\n"
        "          baseQuery: deepRoute?.query,\n",
        "router personal section identity",
    )


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
        (VM, patch_vm),
        (BROWSE, patch_browse),
        (DISCOVER, patch_discover),
        (DEEP_VM, patch_deep_vm),
        (ROUTER, patch_router),
    ):
        if apply(path, transform, args.check):
            changed.append(str(path.relative_to(ROOT)))
    if args.check:
        print("personalised_expanded_browse_patch=present")
    else:
        print("personalised_expanded_browse_patch=applied")
        for path in changed:
            print(f"changed={path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
