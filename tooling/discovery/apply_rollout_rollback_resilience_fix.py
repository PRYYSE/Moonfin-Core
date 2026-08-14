#!/usr/bin/env python3
"""Harden the outer rollout rollback if Jellyfin is already stopped.

The exact-source server rollback helper discovers the running Jellyfin
container. If a frontend-swap error happens after the rollout has stopped that
container but before it is restarted, start the already-known container first,
then invoke the existing full-plugin rollback.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / "tooling/discovery/home_lab_discovery_release_rollout.sh"

OLD = '''rollback_live() {
  [[ -n "$BACKUP" && -d "$BACKUP" ]] || return 0
  say "Rolling back the exact pre-Discovery Moonfin plugin state..."
  bash "$WORKTREE/tooling/discovery/home_lab_discovery_server_job.sh" \\
    rollback "$BACKUP"
}
'''

NEW = '''rollback_live() {
  [[ -n "$BACKUP" && -d "$BACKUP" ]] || return 0
  say "Rolling back the exact pre-Discovery Moonfin plugin state..."
  if [[ -n "$JELLYFIN" ]]; then
    docker_cmd start "$JELLYFIN" >/dev/null 2>&1 || true
  fi
  bash "$WORKTREE/tooling/discovery/home_lab_discovery_server_job.sh" \\
    rollback "$BACKUP"
}
'''


def patch(text: str) -> str:
    if 'docker_cmd start "$JELLYFIN" >/dev/null 2>&1 || true' in text:
        return text
    count = text.count(OLD)
    if count != 1:
        raise RuntimeError(f"expected exactly one rollback block, found {count}")
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
            raise RuntimeError("rollout rollback resilience fix is not applied")
        print("rollout_rollback_resilience_fix=present")
        return 0
    if changed:
        TARGET.write_text(updated, encoding="utf-8")
        print(f"changed={TARGET.relative_to(ROOT)}")
    print("rollout_rollback_resilience_fix=applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
