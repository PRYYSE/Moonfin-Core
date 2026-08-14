#!/usr/bin/env python3
"""Make refinement active/empty semantics match emitted Seerr filters."""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / "lib/data/services/seerr/seerr_discovery_browse_refinements.dart"
OLD_EMPTY = """  bool get isEmpty =>
      genreIds.isEmpty &&
      yearFrom == null &&
      yearTo == null &&
      minimumRating == null &&
      minimumVotes == null &&
      runtimeMin == null &&
      runtimeMax == null &&
      (originalLanguage == null || originalLanguage!.trim().isEmpty);
"""
NEW_EMPTY = """  bool get isEmpty => activeCount == 0;
"""
OLD_RUNTIME = """    if (runtimeMin != null || runtimeMax != null) count++;
"""
NEW_RUNTIME = """    if ((runtimeMin != null && runtimeMin! > 0) ||
        (runtimeMax != null && runtimeMax! > 0)) {
      count++;
    }
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    text = TARGET.read_text(encoding="utf-8")
    changed = False
    if OLD_EMPTY in text:
        text = text.replace(OLD_EMPTY, NEW_EMPTY, 1)
        changed = True
    elif NEW_EMPTY not in text:
        raise SystemExit("refinement_semantics_fix=unexpected_empty_state_source")

    if OLD_RUNTIME in text:
        text = text.replace(OLD_RUNTIME, NEW_RUNTIME, 1)
        changed = True
    elif NEW_RUNTIME not in text:
        raise SystemExit("refinement_semantics_fix=unexpected_runtime_source")

    if args.check:
        if changed:
            raise SystemExit("refinement_semantics_fix=required")
        print("refinement_semantics_fix=present")
        return 0

    if changed:
        TARGET.write_text(text, encoding="utf-8")
    print("refinement_semantics_fix=applied" if changed else "refinement_semantics_fix=present")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
