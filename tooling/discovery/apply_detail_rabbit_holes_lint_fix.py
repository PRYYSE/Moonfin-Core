#!/usr/bin/env python3
"""Apply the strict analyser cleanups required by detail rabbit holes.

Nullable production years use Dart's null-aware map value syntax so the raw
metadata field is omitted when no year exists. The season synthetic ID string
is unchanged semantically.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ADAPTER = ROOT / "lib/data/services/seerr/seerr_detail_discovery_adapter.dart"
DETAIL_VM = ROOT / "lib/data/viewmodels/item_detail_view_model.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_year(text: str, indent: str, label: str) -> str:
    new = f"{indent}'ProductionYear': ?year,\n"
    if new in text:
        return text
    old_if = f"{indent}if (year != null) 'ProductionYear': year,\n"
    if old_if in text:
        return replace_once(text, old_if, new, label)
    old_plain = f"{indent}'ProductionYear': year,\n"
    if old_plain in text:
        return replace_once(text, old_plain, new, label)
    raise RuntimeError(f"{label}: production year marker not found")


def patch_adapter(text: str) -> str:
    return patch_year(text, "        ", "adapter nullable production year")


def patch_detail_vm(text: str) -> str:
    text = patch_year(text, "      ", "detail nullable production year")
    if "id: '$itemId:s${season.seasonNumber}'," not in text:
        text = replace_once(
            text,
            "              id: '${itemId}:s${season.seasonNumber}',\n",
            "              id: '$itemId:s${season.seasonNumber}',\n",
            "detail season interpolation",
        )
    return text


def apply(path: Path, transform, check: bool) -> bool:
    original = path.read_text(encoding="utf-8")
    updated = transform(original)
    changed = updated != original
    if check:
        if changed:
            raise RuntimeError(f"{path.relative_to(ROOT)} still needs lint cleanup")
        return False
    if changed:
        path.write_text(updated, encoding="utf-8")
    return changed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    changed = []
    for path, transform in ((ADAPTER, patch_adapter), (DETAIL_VM, patch_detail_vm)):
        if apply(path, transform, args.check):
            changed.append(str(path.relative_to(ROOT)))
    if args.check:
        print("detail_rabbit_holes_lint_fix=present")
    else:
        print("detail_rabbit_holes_lint_fix=applied")
        for path in changed:
            print(f"changed={path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
