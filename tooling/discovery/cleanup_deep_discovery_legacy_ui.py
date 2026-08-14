#!/usr/bin/env python3
"""Remove legacy Seerr category widgets made obsolete by deep Discovery.

Run after apply_deep_discovery_ui_patch.py. The new catalogue represents genre,
network and studio discovery as normal media lanes/category indexes, so keeping
the old special row builders only creates dead analyser warnings.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCREEN = ROOT / "lib/ui/screens/seerr/seerr_discover_screen.dart"


def remove_between(text: str, start: str, end: str, label: str) -> str:
    start_index = text.find(start)
    if start_index < 0:
        return text
    end_index = text.find(end, start_index)
    if end_index < 0:
        raise RuntimeError(f"{label}: end marker not found")
    return text[:start_index] + text[end_index:]


def clean(text: str) -> str:
    # The old category cards were the only users of CachedNetworkImage and the
    # old view model. The deep landing page renders SeerrDeepDiscoveryRow media
    # cards exclusively, so both imports become obsolete with those builders.
    text = text.replace(
        "import 'package:cached_network_image/cached_network_image.dart';\n",
        "",
    )
    text = text.replace(
        "import '../../../data/viewmodels/seerr_discover_view_model.dart';\n",
        "",
    )

    text = remove_between(
        text,
        "  Widget _buildGenreRow(",
        "  static String? _yearFromItem",
        "legacy category row builders",
    )
    text = remove_between(
        text,
        "class _GenreCard extends StatefulWidget",
        "class _RequestsEntryButton extends StatefulWidget",
        "legacy category cards",
    )
    return text


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    original = SCREEN.read_text(encoding="utf-8")
    cleaned = clean(original)
    changed = cleaned != original
    if args.check:
        if changed:
            raise SystemExit("deep_discovery_legacy_cleanup=required")
        print("deep_discovery_legacy_cleanup=present")
        return 0

    if changed:
        SCREEN.write_text(cleaned, encoding="utf-8")
    print("deep_discovery_legacy_cleanup=applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
