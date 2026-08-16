#!/usr/bin/env python3
"""Apply the final Home Lab Discovery presentation/rollout polish once.

This intentionally does not touch recommendation scoring, route semantics or
catalogue contents. It fixes the visually cramped Discovery tab rail and the
three ownership hazards found during the first live For You hotfix rollout.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCREEN = ROOT / "lib/ui/screens/seerr/seerr_discover_screen.dart"
ROLLOUT = ROOT / "tooling/discovery/home_lab_for_you_hotfix_rollout.sh"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one source marker, found {count}")
    return text.replace(old, new, 1)


def patch_screen(text: str) -> str:
    text = replace_once(
        text,
        "        itemExtent: 150 * desktopScale,\n"
        "        itemSpacing: 12 * desktopScale,\n"
        "        height: 60 * desktopScale,\n",
        "        itemExtent: 150 * desktopScale,\n"
        "        itemSpacing: 16 * desktopScale,\n"
        "        height: 60 * desktopScale,\n",
        "Discovery tab inter-pill spacing",
    )
    text = replace_once(
        text,
        "            alignment: Alignment.center,\n"
        "            child: Row(\n"
        "              mainAxisAlignment: MainAxisAlignment.center,\n"
        "              mainAxisSize: MainAxisSize.min,\n"
        "              children: [\n"
        "                if (browseAll) ...[\n",
        "            alignment: Alignment.center,\n"
        "            padding: EdgeInsets.symmetric(horizontal: 16 * desktopScale),\n"
        "            child: Row(\n"
        "              mainAxisAlignment: MainAxisAlignment.center,\n"
        "              mainAxisSize: MainAxisSize.min,\n"
        "              children: [\n"
        "                if (browseAll) ...[\n",
        "Discovery tab internal horizontal padding",
    )
    return text


def patch_rollout(text: str) -> str:
    text = replace_once(
        text,
        '  output="$("${P[@]}" env \\\n    MOONFIN_JELLYFIN_URL="$BASE_URL" \\\n',
        '  output="$("${P[@]}" env \\\n    PYTHONDONTWRITEBYTECODE=1 \\\n    MOONFIN_JELLYFIN_URL="$BASE_URL" \\\n',
        "runtime verifier bytecode ownership",
    )
    text = replace_once(
        text,
        '  git -C "$REPO" worktree remove --force "$WORKTREE" >/dev/null 2>&1 || rm -rf "$WORKTREE"\n',
        '  git -C "$REPO" worktree remove --force "$WORKTREE" >/dev/null 2>&1 || "${P[@]}" rm -rf "$WORKTREE"\n',
        "stale worktree privileged cleanup",
    )
    text = replace_once(
        text,
        'printf \'%s\\n\' "$PREVIOUS_WEB_SHA" > "$BACKUP/source-commit.txt"\n',
        'printf \'%s\\n\' "$PREVIOUS_WEB_SHA" | "${P[@]}" tee "$BACKUP/source-commit.txt" >/dev/null\n',
        "backup metadata privileged write",
    )
    return text


def apply(path: Path, transform) -> bool:
    before = path.read_text(encoding="utf-8")
    after = transform(before)
    if after == before:
        return False
    path.write_text(after, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    if args.check:
        screen = SCREEN.read_text(encoding="utf-8")
        rollout = ROLLOUT.read_text(encoding="utf-8")
        if "itemSpacing: 16 * desktopScale" not in screen:
            raise SystemExit("final tab spacing is not applied")
        if "horizontal: 16 * desktopScale" not in screen:
            raise SystemExit("final tab internal padding is not applied")
        if "PYTHONDONTWRITEBYTECODE=1" not in rollout:
            raise SystemExit("rollout bytecode ownership fix is not applied")
        if '"${P[@]}" rm -rf "$WORKTREE"' not in rollout:
            raise SystemExit("rollout worktree cleanup fix is not applied")
        if 'tee "$BACKUP/source-commit.txt"' not in rollout:
            raise SystemExit("rollout backup metadata fix is not applied")
        print("FINAL DISCOVERY POLISH CHECK PASS")
        return 0

    changed = []
    if apply(SCREEN, patch_screen):
        changed.append(str(SCREEN.relative_to(ROOT)))
    if apply(ROLLOUT, patch_rollout):
        changed.append(str(ROLLOUT.relative_to(ROOT)))

    print("FINAL DISCOVERY POLISH APPLY PASS")
    if changed:
        for path in changed:
            print(f"changed={path}")
    else:
        print("changed=none")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
