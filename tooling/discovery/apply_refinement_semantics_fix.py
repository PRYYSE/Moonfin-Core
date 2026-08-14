#!/usr/bin/env python3
"""Make refinement empty-state semantics match emitted Seerr filters."""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / "lib/data/services/seerr/seerr_discovery_browse_refinements.dart"
OLD = """  bool get isEmpty =>
      genreIds.isEmpty &&
      yearFrom == null &&
      yearTo == null &&
      minimumRating == null &&
      minimumVotes == null &&
      runtimeMin == null &&
      runtimeMax == null &&
      (originalLanguage == null || originalLanguage!.trim().isEmpty);
"""
NEW = """  bool get isEmpty => activeCount == 0;
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    text = TARGET.read_text(encoding="utf-8")
    if NEW in text:
        print("refinement_semantics_fix=present")
        return 0
    if OLD not in text:
        raise SystemExit("refinement_semantics_fix=unexpected_source")
    if args.check:
        raise SystemExit("refinement_semantics_fix=required")
    TARGET.write_text(text.replace(OLD, NEW, 1), encoding="utf-8")
    print("refinement_semantics_fix=applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
