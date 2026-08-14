#!/usr/bin/env python3
"""Read-only runtime gate for the Home Lab Discovery server foundation."""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
TOOLING = HERE.parent
if str(TOOLING) not in sys.path:
    sys.path.insert(0, str(TOOLING))

from home_lab_safe_auth import jellyfin_token  # noqa: E402

BASE_URL = os.environ.get(
    "MOONFIN_JELLYFIN_URL", "http://127.0.0.1:8096"
).rstrip("/")
EXPECTED_WEB_COMMIT = os.environ.get(
    "MOONFIN_EXPECTED_WEB_COMMIT",
    "9be74475d0ff7dfed6a573a5f8a9e5225b8331e6",
).strip()


def get_json(path: str, token: str | None = None) -> Any:
    headers = {
        "Accept": "application/json",
        "User-Agent": "HomeLabDiscoveryRuntimeGate/1.0",
    }
    if token:
        headers["Authorization"] = f'MediaBrowser Token="{token}"'
    request = urllib.request.Request(
        f"{BASE_URL}/{path.lstrip('/')}",
        headers=headers,
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read()
            return json.loads(raw.decode("utf-8")) if raw else None
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"GET {path} returned HTTP {exc.code}") from None
    except (urllib.error.URLError, TimeoutError) as exc:
        raise RuntimeError(f"GET {path} could not reach Jellyfin") from exc


def main() -> int:
    token = jellyfin_token()

    ping = get_json("/Moonfin/Ping", token)
    if not isinstance(ping, dict) or ping.get("installed") is not True:
        raise RuntimeError("Moonfin Ping did not report the plugin installed")
    if ping.get("seerrEnabled") is not True:
        raise RuntimeError("Moonfin Ping no longer reports Seerr enabled")

    catalogue = get_json("/Moonfin/Discovery/Catalogue", token)
    if not isinstance(catalogue, dict):
        raise RuntimeError("Discovery Catalogue did not return an object")
    if int(catalogue.get("schemaVersion") or 0) != 2:
        raise RuntimeError("Discovery Catalogue schemaVersion is not 2")
    tabs = catalogue.get("tabs")
    if not isinstance(tabs, list):
        raise RuntimeError("Discovery Catalogue tabs are missing")
    expected_tabs = {
        "for-you",
        "movies",
        "series",
        "anime",
        "new-upcoming",
        "lists",
    }
    actual_tabs = {
        str(tab.get("id"))
        for tab in tabs
        if isinstance(tab, dict) and tab.get("id") is not None
    }
    if actual_tabs != expected_tabs:
        raise RuntimeError(
            f"Discovery tab IDs changed unexpectedly: {sorted(actual_tabs)}"
        )
    lane_count = sum(
        len(tab.get("sections") or []) for tab in tabs if isinstance(tab, dict)
    )
    # Semantic tags/providers are intentionally allowed to drop when current
    # Seerr metadata cannot resolve them. A healthy compile should still remain
    # far larger than the visible session and the original small scaffold.
    if lane_count < 300:
        raise RuntimeError(
            f"Compiled Discovery catalogue is unexpectedly shallow: {lane_count} lanes"
        )

    manifest = get_json("/Moonfin/Web/homelab-build-manifest.json")
    if not isinstance(manifest, dict):
        raise RuntimeError("Moonfin Web build manifest is missing")
    actual_web_commit = str(manifest.get("sourceCommit") or "").strip()
    if actual_web_commit != EXPECTED_WEB_COMMIT:
        raise RuntimeError(
            "Accepted Moonfin Web source commit changed: "
            f"expected {EXPECTED_WEB_COMMIT}, got {actual_web_commit or '<missing>'}"
        )
    if manifest.get("theme") != "home_lab_streaming":
        raise RuntimeError("Accepted Moonfin Web theme changed")

    print("DISCOVERY SERVER FOUNDATION PASS")
    print(f"moonbase_version={ping.get('version')}")
    print(f"compiled_lanes={lane_count}")
    print(f"web_source_commit={actual_web_commit}")
    print("seerr_enabled=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
