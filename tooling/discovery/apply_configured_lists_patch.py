#!/usr/bin/env python3
"""Wire configured external-list discovery into the deep VM and DI."""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VM = ROOT / "lib/data/viewmodels/seerr_deep_discovery_view_model.dart"
DI = ROOT / "lib/di/modules/app_module.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_vm(text: str) -> str:
    if "SeerrDiscoveryConfiguredListsService configuredLists" in text:
        return text

    text = replace_once(
        text,
        "import '../services/seerr/seerr_discovery_composer.dart';\n",
        "import '../services/seerr/seerr_discovery_composer.dart';\n"
        "import '../services/seerr/seerr_discovery_configured_lists_service.dart';\n",
        "vm configured list import",
    )
    text = replace_once(
        text,
        "typedef SeerrDeepBlockNsfw = bool Function();\n",
        "typedef SeerrDeepBlockNsfw = bool Function();\n"
        "typedef SeerrDeepCatalogueMerger = SeerrDiscoveryCatalogue Function(\n"
        "  SeerrDiscoveryCatalogue catalogue,\n"
        ");\n"
        "typedef SeerrDeepExternalFetcher = Future<SeerrDiscoverPage> Function(\n"
        "  SeerrDiscoverySection section,\n"
        "  int page, {\n"
        "  bool forceRefresh,\n"
        "});\n"
        "typedef SeerrDeepExternalClearer = void Function();\n",
        "vm external typedefs",
    )
    text = replace_once(
        text,
        "  final SeerrDeepBlockNsfw _blockNsfw;\n"
        "  final SeerrDiscoveryComposer _composer;\n",
        "  final SeerrDeepBlockNsfw _blockNsfw;\n"
        "  final SeerrDeepCatalogueMerger _mergeCatalogue;\n"
        "  final SeerrDeepExternalFetcher _fetchExternal;\n"
        "  final SeerrDeepExternalClearer _clearExternal;\n"
        "  final SeerrDiscoveryComposer _composer;\n",
        "vm external fields",
    )
    text = replace_once(
        text,
        "    required SeerrDiscoveryPersonalisationService personalisation,\n"
        "    required SeerrPreferences preferences,\n"
        "    required String serverId,\n",
        "    required SeerrDiscoveryPersonalisationService personalisation,\n"
        "    required SeerrDiscoveryConfiguredListsService configuredLists,\n"
        "    required SeerrPreferences preferences,\n"
        "    required String serverId,\n",
        "vm production constructor args",
    )
    text = replace_once(
        text,
        "        _blockNsfw = (() => preferences.blockNsfw),\n"
        "        _composer = composer;\n",
        "        _blockNsfw = (() => preferences.blockNsfw),\n"
        "        _mergeCatalogue = configuredLists.mergeIntoCatalogue,\n"
        "        _fetchExternal = ((section, page, {forceRefresh = false}) =>\n"
        "            configuredLists.load(\n"
        "              section,\n"
        "              page: page,\n"
        "              forceRefresh: forceRefresh,\n"
        "            )),\n"
        "        _clearExternal = configuredLists.clear,\n"
        "        _composer = composer;\n",
        "vm production configured initialisers",
    )
    text = replace_once(
        text,
        "    SeerrDeepBlockNsfw blockNsfw = _neverBlockNsfw,\n"
        "    SeerrDiscoveryComposer composer = const SeerrDiscoveryComposer(),\n",
        "    SeerrDeepBlockNsfw blockNsfw = _neverBlockNsfw,\n"
        "    SeerrDeepCatalogueMerger mergeCatalogue = _identityCatalogue,\n"
        "    SeerrDeepExternalFetcher fetchExternal = _unsupportedExternal,\n"
        "    SeerrDeepExternalClearer clearExternal = _noopExternalClear,\n"
        "    SeerrDiscoveryComposer composer = const SeerrDiscoveryComposer(),\n",
        "vm test constructor args",
    )
    text = replace_once(
        text,
        "        _loadSessionSeed = loadSessionSeed,\n"
        "        _blockNsfw = blockNsfw,\n"
        "        _composer = composer;\n\n"
        "  static bool _neverBlockNsfw() => false;\n",
        "        _loadSessionSeed = loadSessionSeed,\n"
        "        _blockNsfw = blockNsfw,\n"
        "        _mergeCatalogue = mergeCatalogue,\n"
        "        _fetchExternal = fetchExternal,\n"
        "        _clearExternal = clearExternal,\n"
        "        _composer = composer;\n\n"
        "  static bool _neverBlockNsfw() => false;\n\n"
        "  static SeerrDiscoveryCatalogue _identityCatalogue(\n"
        "    SeerrDiscoveryCatalogue catalogue,\n"
        "  ) => catalogue;\n\n"
        "  static Future<SeerrDiscoverPage> _unsupportedExternal(\n"
        "    SeerrDiscoverySection section,\n"
        "    int page, {\n"
        "    bool forceRefresh = false,\n"
        "  }) async =>\n"
        "      throw StateError('External Discovery list is not configured');\n\n"
        "  static void _noopExternalClear() {}\n",
        "vm test external initialisers",
    )
    text = text.replace(
        "      _catalogue = result.catalogue;\n",
        "      _catalogue = _mergeCatalogue(result.catalogue);\n",
    )
    if text.count("_catalogue = _mergeCatalogue(result.catalogue);") != 2:
        raise RuntimeError("vm catalogue merger: expected load and refresh replacements")

    text = replace_once(
        text,
        "  Future<void> refresh() async {\n"
        "    _refreshNonce++;\n",
        "  Future<void> refresh() async {\n"
        "    _refreshNonce++;\n"
        "    _clearExternal();\n",
        "vm refresh external clear",
    )
    text = replace_once(
        text,
        "      } else if (row.section.query.source == SeerrDiscoverySource.externalList) {\n"
        "        _rows[rowIndex] = row.copyWith(isLoading: false);\n"
        "        notifyListeners();\n"
        "        return;\n"
        "      } else {\n",
        "      } else if (row.section.query.source == SeerrDiscoverySource.externalList) {\n"
        "        page = await _fetchExternal(row.section, nextPage);\n"
        "      } else {\n",
        "vm external load more",
    )
    text = replace_once(
        text,
        "    if (section.query.source == SeerrDiscoverySource.externalList) {\n"
        "      // Curated list IDs are server configuration references. Until a matching\n"
        "      // configured list exists, fail this optional lane closed rather than\n"
        "      // broadening it into unrelated TMDb discovery.\n"
        "      return null;\n"
        "    }\n",
        "    if (section.query.source == SeerrDiscoverySource.externalList) {\n"
        "      try {\n"
        "        final page = await _fetchExternal(section, 1);\n"
        "        final items = page.results\n"
        "            .where((item) => _include(section, item))\n"
        "            .toList(growable: false);\n"
        "        if (items.length < section.minItems) return null;\n"
        "        return SeerrDeepDiscoveryRow(\n"
        "          section: section,\n"
        "          title: section.title,\n"
        "          items: items.take(section.previewLimit).toList(growable: false),\n"
        "          page: page.page,\n"
        "          totalPages: page.totalPages,\n"
        "        );\n"
        "      } catch (exception) {\n"
        "        return SeerrDeepDiscoveryRow(\n"
        "          section: section,\n"
        "          title: section.title,\n"
        "          error: exception.toString(),\n"
        "        );\n"
        "      }\n"
        "    }\n",
        "vm external initial load",
    )
    return text


def patch_di(text: str) -> str:
    if "SeerrDiscoveryConfiguredListsService" in text:
        return text
    text = replace_once(
        text,
        "import '../../data/services/seerr/seerr_discovery_catalogue_service.dart';\n",
        "import '../../data/services/seerr/seerr_discovery_catalogue_service.dart';\n"
        "import '../../data/services/seerr/seerr_discovery_configured_lists_service.dart';\n",
        "di configured lists import",
    )
    text = replace_once(
        text,
        "  unregister<SeerrDiscoveryPersonalisationService>();\n"
        "  unregister<SeerrDiscoveryCatalogueService>();\n",
        "  unregister<SeerrDiscoveryPersonalisationService>();\n"
        "  unregister<SeerrDiscoveryConfiguredListsService>();\n"
        "  unregister<SeerrDiscoveryCatalogueService>();\n",
        "di configured lists unregister",
    )
    text = replace_once(
        text,
        "  _getIt.registerLazySingleton<SeerrDiscoveryPersonalisationService>(\n",
        "  _getIt.registerLazySingleton<SeerrDiscoveryConfiguredListsService>(\n"
        "    () => SeerrDiscoveryConfiguredListsService(\n"
        "      preferences: _getIt<UserPreferences>(),\n"
        "      externalLists: _getIt<CustomExternalListsService>(),\n"
        "    ),\n"
        "  );\n"
        "  _getIt.registerLazySingleton<SeerrDiscoveryPersonalisationService>(\n",
        "di configured lists registration",
    )
    text = replace_once(
        text,
        "      personalisation: _getIt<SeerrDiscoveryPersonalisationService>(),\n"
        "      preferences: _getIt<SeerrPreferences>(),\n",
        "      personalisation: _getIt<SeerrDiscoveryPersonalisationService>(),\n"
        "      configuredLists: _getIt<SeerrDiscoveryConfiguredListsService>(),\n"
        "      preferences: _getIt<SeerrPreferences>(),\n",
        "di configured lists deep vm arg",
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
    for path, transform in ((VM, patch_vm), (DI, patch_di)):
        if apply(path, transform, args.check):
            changed.append(str(path.relative_to(ROOT)))
    if args.check:
        print("configured_lists_patch=present")
    else:
        print("configured_lists_patch=applied")
        for path in changed:
            print(f"changed={path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
