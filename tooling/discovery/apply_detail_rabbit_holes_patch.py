#!/usr/bin/env python3
"""Merge Seerr Similar + Recommendations into Moonfin's native detail carousel.

The patch keeps Jellyfin/RowDataSource recommendations and Seerr discovery in
separate source state so concurrent completion order cannot discard either.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VM = ROOT / "lib/data/viewmodels/item_detail_view_model.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch(text: str) -> str:
    if "_rebuildDetailRabbitHoles" in text:
        return text

    text = replace_once(
        text,
        "import '../services/row_data_source.dart';\n",
        "import '../services/row_data_source.dart';\n"
        "import '../services/seerr/seerr_detail_discovery_adapter.dart';\n",
        "detail adapter import",
    )

    text = replace_once(
        text,
        "  List<AggregatedItem> _similar = const [];\n"
        "  List<AggregatedItem> get similar => _similar;\n",
        "  List<AggregatedItem> _similar = const [];\n"
        "  List<AggregatedItem> _librarySimilar = const [];\n"
        "  List<AggregatedItem> get similar => _similar;\n",
        "separate library similar state",
    )

    text = replace_once(
        text,
        "  /// Resolves the Seerr side of a library item, if there is one to resolve.\n",
        "  void _setLibrarySimilar(List<AggregatedItem> items) {\n"
        "    _librarySimilar = List.unmodifiable(items);\n"
        "    _rebuildDetailRabbitHoles();\n"
        "  }\n\n"
        "  void _rebuildDetailRabbitHoles([SeerrMediaDetailState? state]) {\n"
        "    final seerrState = state ?? _seerr?.state;\n"
        "    if (seerrState == null || seerrState.tmdbId == 0) {\n"
        "      _similar = _librarySimilar;\n"
        "    } else {\n"
        "      _similar = SeerrDetailDiscoveryAdapter.mergeIntoExisting(\n"
        "        existing: _librarySimilar,\n"
        "        state: seerrState,\n"
        "        blockNsfw: GetIt.instance<SeerrPreferences>().blockNsfw,\n"
        "      );\n"
        "    }\n"
        "    notifyListeners();\n"
        "  }\n\n"
        "  /// Resolves the Seerr side of a library item, if there is one to resolve.\n",
        "rabbit hole merge helpers",
    )

    text = replace_once(
        text,
        "      await vm.load(\n"
        "        lookupId,\n"
        "        item.type == 'Series' ? 'tv' : 'movie',\n"
        "        title: item.name,\n"
        "      );\n"
        "    } catch (_) {}\n",
        "      await vm.load(\n"
        "        lookupId,\n"
        "        item.type == 'Series' ? 'tv' : 'movie',\n"
        "        title: item.name,\n"
        "      );\n"
        "      _rebuildDetailRabbitHoles(vm.state);\n"
        "    } catch (_) {}\n",
        "local Seerr overlay rabbit holes",
    )

    text = replace_once(
        text,
        "    _seasons = _seerrSeasons(state);\n"
        "    _state = ItemDetailState.ready;\n"
        "    notifyListeners();\n",
        "    _seasons = _seerrSeasons(state);\n"
        "    _state = ItemDetailState.ready;\n"
        "    _rebuildDetailRabbitHoles(state);\n",
        "Seerr-only rabbit holes",
    )

    text = replace_once(
        text,
        "    _playlistItems = const [];\n"
        "    notifyListeners();\n",
        "    _playlistItems = const [];\n"
        "    _librarySimilar = const [];\n"
        "    _similar = const [];\n"
        "    notifyListeners();\n",
        "reset detail rabbit holes",
    )

    text = replace_once(
        text,
        "        if (recommended.isNotEmpty) {\n"
        "          _similar = recommended;\n"
        "          notifyListeners();\n"
        "          return;\n"
        "        }\n",
        "        if (recommended.isNotEmpty) {\n"
        "          _setLibrarySimilar(recommended);\n"
        "          return;\n"
        "        }\n",
        "custom recommendation merge",
    )

    text = replace_once(
        text,
        "      final items = (data['Items'] as List?) ?? [];\n"
        "      _similar = _mapItems(items);\n"
        "      notifyListeners();\n"
        "    } catch (_) {}\n"
        "  }\n\n"
        "  Future<void> _loadRatings() async {\n",
        "      final items = (data['Items'] as List?) ?? [];\n"
        "      _setLibrarySimilar(_mapItems(items));\n"
        "    } catch (_) {}\n"
        "  }\n\n"
        "  Future<void> _loadRatings() async {\n",
        "Jellyfin similar merge",
    )
    return text


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    original = VM.read_text(encoding="utf-8")
    updated = patch(original)
    changed = updated != original
    if args.check:
        if changed:
            raise RuntimeError(f"{VM.relative_to(ROOT)} is not patched")
        print("detail_rabbit_holes_patch=present")
        return 0
    if changed:
        VM.write_text(updated, encoding="utf-8")
        print(f"changed={VM.relative_to(ROOT)}")
    print("detail_rabbit_holes_patch=applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
