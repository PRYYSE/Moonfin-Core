#!/usr/bin/env python3
"""Generate a fail-closed stable-release/Home-Lab impact report from local Git refs."""

from __future__ import annotations

import argparse
import json
import subprocess
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

AREAS = (
    "dependencies/build tooling",
    "navigation/routing",
    "authentication/session handling",
    "Jellyfin APIs/models",
    "Seerr/Moonbase integration",
    "playback",
    "Web",
    "Android mobile/tablet",
    "Android TV / Google TV",
    "Smart-TV/webOS",
    "application/package identity and versioning",
    "Home Lab Discovery catalogue/compiler/schema",
    "other",
)


def git(repo: Path, *args: str, check: bool = True) -> str:
    proc = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if check and proc.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed in {repo}: {proc.stderr.strip()}")
    return proc.stdout.strip()


def resolve(repo: Path, ref: str) -> str:
    return git(repo, "rev-parse", f"{ref}^{{commit}}")


def require_ancestor(repo: Path, base: str, ref: str, label: str) -> None:
    proc = subprocess.run(
        ["git", "-C", str(repo), "merge-base", "--is-ancestor", base, ref],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"Accepted source base {base} is not an ancestor of {label} {ref}. "
            "Stop and reconcile the baseline rather than generating a misleading report."
        )


def changed_entries(repo: Path, base: str, ref: str) -> list[tuple[str, str, str | None]]:
    raw = git(repo, "diff", "--name-status", "--find-renames", base, ref)
    entries: list[tuple[str, str, str | None]] = []
    if not raw:
        return entries
    for line in raw.splitlines():
        parts = line.split("\t")
        status = parts[0]
        if status.startswith(("R", "C")) and len(parts) >= 3:
            entries.append((status, parts[2], parts[1]))
        elif len(parts) >= 2:
            entries.append((status, parts[1], None))
        else:
            raise RuntimeError(f"Unexpected git diff --name-status line: {line!r}")
    return entries


def entry_paths(entry: tuple[str, str, str | None]) -> set[str]:
    _, path, old_path = entry
    paths = {path}
    if old_path:
        paths.add(old_path)
    return paths


def classify(path: str) -> str:
    p = path.lower()
    name = Path(path).name.lower()
    if (
        "homelab_discovery" in p
        or "homelab-discovery-v2" in p
        or "discovery_catalogue" in p
        or "discovery-catalogue" in p
    ):
        return "Home Lab Discovery catalogue/compiler/schema"
    if "seerr" in p or "moonbase" in p:
        return "Seerr/Moonbase integration"
    if any(token in p for token in ("app_router", "/router", "/route", "navigation")):
        return "navigation/routing"
    if any(token in p for token in ("auth", "session", "login", "credential")):
        return "authentication/session handling"
    if "jellyfin" in p or "/api/" in p or "/models/" in p or "/model/" in p:
        return "Jellyfin APIs/models"
    if any(token in p for token in ("playback", "player", "video_player", "audio_player")):
        return "playback"
    if any(token in p for token in ("androidtv", "android_tv", "leanback", "/tv/")):
        return "Android TV / Google TV"
    if p.startswith("android/") or "mobile" in p or "tablet" in p:
        return "Android mobile/tablet"
    if p.startswith("web/") or "web.dart" in p or "web_" in name:
        return "Web"
    if (
        p.startswith("packages/app/")
        or p.startswith("packages/build-webos/")
        or "webos" in p
        or "tizen" in p
        or "enact" in p
    ):
        return "Smart-TV/webOS"
    if name in {
        "pubspec.yaml", "package.json", "package-lock.json", "build.gradle",
        "build.gradle.kts", "settings.gradle", "settings.gradle.kts", "gradle.properties",
    } or p.startswith((".github/", "gradle/", "tool/", "scripts/")):
        return "dependencies/build tooling"
    if any(token in p for token in ("appinfo.json", "manifest", "version", "signing")):
        return "application/package identity and versioning"
    return "other"


def count_areas(entries: Iterable[tuple[str, str, str | None]]) -> Counter[str]:
    result: Counter[str] = Counter()
    for _, path, _ in entries:
        result[classify(path)] += 1
    return result


def format_entry(entry: tuple[str, str, str | None]) -> str:
    status, path, old_path = entry
    if old_path:
        return f"`{status}` `{old_path}` -> `{path}`"
    return f"`{status}` `{path}`"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--component", choices=("core", "smart_tv"), required=True)
    parser.add_argument("--repo", default=".")
    parser.add_argument("--upstream-ref", required=True)
    parser.add_argument("--upstream-release-tag", required=True)
    parser.add_argument("--overlay-ref", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--github-output")
    args = parser.parse_args()

    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    component = config[args.component]
    repo = Path(args.repo).resolve()
    if not (repo / ".git").exists():
        raise RuntimeError(f"Not a Git repository: {repo}")

    base = component["accepted_base_sha"]
    accepted_release_tag = component["accepted_release_tag"]
    upstream_release_tag = args.upstream_release_tag
    upstream = resolve(repo, args.upstream_ref)
    overlay = resolve(repo, args.overlay_ref)
    resolve(repo, base)
    require_ancestor(repo, base, upstream, "stable upstream release")
    require_ancestor(repo, base, overlay, "Home Lab overlay")

    upstream_entries = changed_entries(repo, base, upstream)
    overlay_entries = changed_entries(repo, base, overlay)
    upstream_paths = set().union(*(entry_paths(e) for e in upstream_entries)) if upstream_entries else set()
    overlay_paths = set().union(*(entry_paths(e) for e in overlay_entries)) if overlay_entries else set()
    overlap_paths = upstream_paths & overlay_paths
    overlap_entries = [e for e in overlay_entries if entry_paths(e) & overlap_paths]

    upstream_counts = count_areas(upstream_entries)
    overlay_counts = count_areas(overlay_entries)
    overlap_counts = Counter(classify(path) for path in overlap_paths)
    upstream_commits = int(git(repo, "rev-list", "--count", f"{base}..{upstream}") or "0")
    update_available = upstream_release_tag != accepted_release_tag

    lines = [
        f"# Home Lab Stable Upstream Impact - {component['label']}",
        "",
        f"Generated: `{datetime.now(timezone.utc).isoformat()}`",
        "",
        f"- upstream repository: `{component['upstream_repository']}`",
        f"- accepted stable release tag: `{accepted_release_tag}`",
        f"- latest stable release tag: `{upstream_release_tag}`",
        f"- accepted source base: `{base}`",
        f"- latest stable release commit: `{upstream}`",
        f"- Home Lab overlay repository: `{component['overlay_repository']}`",
        f"- observed overlay head: `{overlay}`",
        f"- commits from accepted source base to latest stable release: **{upstream_commits}**",
        f"- stable update available: **{'YES' if update_available else 'NO'}**",
        f"- overlapping upstream/Home Lab paths requiring explicit review: **{len(overlap_paths)}**",
        "",
        "## Impact classification",
        "",
        "| Area | Stable release changed paths | Home Lab changed paths | Overlap |",
        "| --- | ---: | ---: | ---: |",
    ]
    for area in AREAS:
        lines.append(f"| {area} | {upstream_counts[area]} | {overlay_counts[area]} | {overlap_counts[area]} |")

    lines.extend(["", "## Files changed by both stable upstream and Home Lab", ""])
    if overlap_entries:
        for entry in sorted(overlap_entries, key=lambda item: item[1]):
            lines.append(f"- {format_entry(entry)}")
    else:
        lines.append("- None detected by path intersection.")

    lines.extend(["", "## Stable release changes", ""])
    if upstream_entries:
        for entry in sorted(upstream_entries, key=lambda item: item[1]):
            lines.append(f"- {format_entry(entry)}")
    else:
        lines.append("- No path changes from the accepted source base to the latest stable release.")

    lines.extend([
        "", "## Update handling contract", "",
        "- Stable release tags decide whether an update is available; unreleased upstream-main drift is not promoted as an update.",
        "- The accepted source base remains the ancestry/diff anchor even when it is a later commit on the same accepted release lineage.",
        "- This report is detection/impact evidence only; it does not merge, deploy, promote or alter signing identity.",
        f"- Create the isolated update branch with prefix `{component['update_branch_prefix']}` from the chosen new official release.",
        "- Explicitly review every overlapping path above even if Git reports no textual conflict.",
        f"- Reapply only the narrow Home Lab overlay and run `{component['release_workflow']}` before physical/live acceptance.",
    ])
    if args.component == "smart_tv":
        lines.extend([
            f"- Preserve rollback branch `{component['rollback_branch']}` and candidate `{component['rollback_candidate_sha']}`.",
            f"- Preserve webOS app ID `{config['protected_identity']['webos_application_id']}`.",
        ])
    else:
        lines.append(
            f"- Preserve production Android signing certificate SHA-256 `{config['protected_identity']['android_production_certificate_sha256']}`."
        )

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")

    if args.github_output:
        with Path(args.github_output).open("a", encoding="utf-8") as fh:
            fh.write(f"update_available={'true' if update_available else 'false'}\n")
            fh.write(f"accepted_release_tag={accepted_release_tag}\n")
            fh.write(f"upstream_release_tag={upstream_release_tag}\n")
            fh.write(f"upstream_head={upstream}\n")
            fh.write(f"overlay_head={overlay}\n")
            fh.write(f"upstream_commits={upstream_commits}\n")
            fh.write(f"upstream_changed_paths={len(upstream_paths)}\n")
            fh.write(f"overlay_changed_paths={len(overlay_paths)}\n")
            fh.write(f"overlap_paths={len(overlap_paths)}\n")

    print(
        f"{component['label']}: stable_update_available={str(update_available).lower()} "
        f"accepted_tag={accepted_release_tag} latest_tag={upstream_release_tag} "
        f"upstream_commits={upstream_commits} overlap_paths={len(overlap_paths)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
