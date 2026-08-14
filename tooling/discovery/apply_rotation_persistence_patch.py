#!/usr/bin/env python3
"""Wire local per-user lane-rotation persistence into deep Discovery."""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VM = ROOT / "lib/data/viewmodels/seerr_deep_discovery_view_model.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_vm(text: str) -> str:
    if "SeerrDeepRotationLoader" in text and "_persistRotationHistory" in text:
        return text

    text = replace_once(
        text,
        "import '../services/seerr/seerr_discovery_rotation_history.dart';\n",
        "import '../services/seerr/seerr_discovery_rotation_history.dart';\n"
        "import '../services/seerr/seerr_discovery_rotation_store.dart';\n",
        "rotation store import",
    )

    text = replace_once(
        text,
        "typedef SeerrDeepBlockNsfw = bool Function();\n",
        "typedef SeerrDeepBlockNsfw = bool Function();\n"
        "typedef SeerrDeepRotationLoader =\n"
        "    Future<Map<String, SeerrDiscoveryRotationHistory>> Function(\n"
        "      String scope,\n"
        "    );\n"
        "typedef SeerrDeepRotationSaver =\n"
        "    Future<void> Function(\n"
        "      String scope,\n"
        "      Map<String, SeerrDiscoveryRotationHistory> histories,\n"
        "    );\n",
        "rotation typedefs",
    )

    text = replace_once(
        text,
        "  final SeerrDeepBlockNsfw _blockNsfw;\n",
        "  final SeerrDeepBlockNsfw _blockNsfw;\n"
        "  late final SeerrDeepRotationLoader _loadRotationHistory;\n"
        "  late final SeerrDeepRotationSaver _saveRotationHistory;\n",
        "rotation fields",
    )

    text = replace_once(
        text,
        "  final Map<String, SeerrDiscoveryRotationHistory> _rotationHistory = {};\n\n",
        "  final Map<String, SeerrDiscoveryRotationHistory> _rotationHistory = {};\n"
        "  String? _rotationHistoryScope;\n\n",
        "rotation scope field",
    )

    text = replace_once(
        text,
        "    required String serverId,\n"
        "    SeerrDiscoveryComposer composer = const SeerrDiscoveryComposer(),\n"
        "  }) : _loadCatalogue = catalogueService.load,\n",
        "    required String serverId,\n"
        "    SeerrDiscoveryRotationStore? rotationStore,\n"
        "    SeerrDiscoveryComposer composer = const SeerrDiscoveryComposer(),\n"
        "  }) : _loadCatalogue = catalogueService.load,\n",
        "production rotation constructor arg",
    )

    text = replace_once(
        text,
        "       _clearExternal = configuredLists.clear,\n"
        "       _composer = composer;\n\n",
        "       _clearExternal = configuredLists.clear,\n"
        "       _composer = composer {\n"
        "    final store = rotationStore ?? SeerrDiscoveryRotationStore();\n"
        "    _loadRotationHistory = store.load;\n"
        "    _saveRotationHistory = store.save;\n"
        "  }\n\n",
        "production rotation constructor body",
    )

    text = replace_once(
        text,
        "    SeerrDeepBlockNsfw blockNsfw = _neverBlockNsfw,\n"
        "    SeerrDeepCatalogueMerger mergeCatalogue = _identityCatalogue,\n",
        "    SeerrDeepBlockNsfw blockNsfw = _neverBlockNsfw,\n"
        "    SeerrDeepRotationLoader loadRotationHistory = _emptyRotationHistory,\n"
        "    SeerrDeepRotationSaver saveRotationHistory = _noopSaveRotationHistory,\n"
        "    SeerrDeepCatalogueMerger mergeCatalogue = _identityCatalogue,\n",
        "testing rotation callbacks",
    )

    text = replace_once(
        text,
        "       _clearExternal = clearExternal,\n"
        "       _composer = composer;\n\n"
        "  static bool _neverBlockNsfw() => false;\n",
        "       _clearExternal = clearExternal,\n"
        "       _composer = composer {\n"
        "    _loadRotationHistory = loadRotationHistory;\n"
        "    _saveRotationHistory = saveRotationHistory;\n"
        "  }\n\n"
        "  static bool _neverBlockNsfw() => false;\n",
        "testing rotation constructor body",
    )

    text = replace_once(
        text,
        "  static void _noopExternalClear() {}\n\n"
        "  Future<void> load() async {\n",
        "  static void _noopExternalClear() {}\n\n"
        "  static Future<Map<String, SeerrDiscoveryRotationHistory>>\n"
        "  _emptyRotationHistory(String scope) async => {};\n\n"
        "  static Future<void> _noopSaveRotationHistory(\n"
        "    String scope,\n"
        "    Map<String, SeerrDiscoveryRotationHistory> histories,\n"
        "  ) async {}\n\n"
        "  Future<void> load() async {\n",
        "rotation test defaults",
    )

    text = replace_once(
        text,
        "      _sessionSeed = await _loadSessionSeed();\n"
        "      if (generation != _generation) return;\n\n"
        "      final existing = _activeTabId;\n",
        "      _sessionSeed = await _loadSessionSeed();\n"
        "      if (generation != _generation) return;\n"
        "      await _restoreRotationHistory();\n"
        "      if (generation != _generation) return;\n\n"
        "      final existing = _activeTabId;\n",
        "restore rotation on initial load",
    )

    text = replace_once(
        text,
        "    history.commitSession(\n"
        "      rendered.where((row) => row.error == null).map((row) => row.section.id),\n"
        "    );\n"
        "    notifyListeners();\n"
        "  }\n\n"
        "  Future<SeerrDeepDiscoveryRow?> _loadSection(\n",
        "    history.commitSession(\n"
        "      rendered.where((row) => row.error == null).map((row) => row.section.id),\n"
        "    );\n"
        "    notifyListeners();\n"
        "    await _persistRotationHistory();\n"
        "  }\n\n"
        "  Future<void> _restoreRotationHistory() async {\n"
        "    if (_rotationHistoryScope == _sessionSeed) return;\n"
        "    try {\n"
        "      final restored = await _loadRotationHistory(_sessionSeed);\n"
        "      _rotationHistory\n"
        "        ..clear()\n"
        "        ..addAll(restored);\n"
        "      _rotationHistoryScope = _sessionSeed;\n"
        "    } catch (exception) {\n"
        "      debugPrint(\n"
        "        '[SeerrDeepDiscovery] Rotation restore failed: $exception',\n"
        "      );\n"
        "      _rotationHistory.clear();\n"
        "      _rotationHistoryScope = _sessionSeed;\n"
        "    }\n"
        "  }\n\n"
        "  Future<void> _persistRotationHistory() async {\n"
        "    try {\n"
        "      await _saveRotationHistory(_sessionSeed, _rotationHistory);\n"
        "    } catch (exception) {\n"
        "      debugPrint(\n"
        "        '[SeerrDeepDiscovery] Rotation persistence failed: $exception',\n"
        "      );\n"
        "    }\n"
        "  }\n\n"
        "  Future<SeerrDeepDiscoveryRow?> _loadSection(\n",
        "persist rotation after rendered session",
    )

    return text


def apply(check: bool) -> bool:
    original = VM.read_text(encoding="utf-8")
    patched = patch_vm(original)
    changed = patched != original
    if check:
        if changed:
            raise RuntimeError(f"{VM.relative_to(ROOT)} is not patched")
        return False
    if changed:
        VM.write_text(patched, encoding="utf-8")
    return changed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    changed = apply(args.check)
    if args.check:
        print("rotation_persistence_patch=present")
    else:
        print("rotation_persistence_patch=applied")
        if changed:
            print(f"changed={VM.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
