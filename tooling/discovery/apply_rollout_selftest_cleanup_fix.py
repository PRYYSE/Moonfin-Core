#!/usr/bin/env python3
"""Fix rollout --self-test temp cleanup under bash `set -u`.

The original EXIT trap referenced a function-local variable after the function
returned. Expand the temp path into the trap immediately, then clear the trap
after successful explicit cleanup.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / "tooling/discovery/home_lab_discovery_release_rollout.sh"

OLD = '''  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  prepare_candidate "$tmp/candidate"
  local full_sha
  full_sha="$(awk 'NR == 1 {print $1}' "$tmp/candidate/$ASSET.sha256")"
  [[ "$full_sha" =~ ^[0-9a-fA-F]{64}$ ]] || die "invalid full candidate checksum"
  say "DISCOVERY ROLLOUT SELF-TEST PASS"
  say "source_sha=$SOURCE_SHA"
  say "artifact_ref=$ARTIFACT_REF"
  say "artifact_sha256=$full_sha"
'''

NEW = '''  local tmp quoted_tmp
  tmp="$(mktemp -d)"
  printf -v quoted_tmp '%q' "$tmp"
  trap "rm -rf -- $quoted_tmp" EXIT
  prepare_candidate "$tmp/candidate"
  local full_sha
  full_sha="$(awk 'NR == 1 {print $1}' "$tmp/candidate/$ASSET.sha256")"
  [[ "$full_sha" =~ ^[0-9a-fA-F]{64}$ ]] || die "invalid full candidate checksum"
  say "DISCOVERY ROLLOUT SELF-TEST PASS"
  say "source_sha=$SOURCE_SHA"
  say "artifact_ref=$ARTIFACT_REF"
  say "artifact_sha256=$full_sha"
  rm -rf -- "$tmp"
  trap - EXIT
'''


def patch(text: str) -> str:
    if "printf -v quoted_tmp '%q' \"$tmp\"" in text:
        return text
    count = text.count(OLD)
    if count != 1:
        raise RuntimeError(f"expected exactly one self-test cleanup block, found {count}")
    return text.replace(OLD, NEW, 1)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    original = TARGET.read_text(encoding="utf-8")
    updated = patch(original)
    changed = updated != original
    if args.check:
        if changed:
            raise RuntimeError("rollout self-test cleanup fix is not applied")
        print("rollout_selftest_cleanup_fix=present")
        return 0
    if changed:
        TARGET.write_text(updated, encoding="utf-8")
        print(f"changed={TARGET.relative_to(ROOT)}")
    print("rollout_selftest_cleanup_fix=applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
