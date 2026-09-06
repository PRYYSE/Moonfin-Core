#!/usr/bin/env python3
"""Apply/check the single upstream route integration used by Discovery v2.

This intentionally owns exactly one Moonfin core file. It is idempotent and
fails on upstream drift rather than guessing a replacement.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROUTER = Path("lib/ui/navigation/app_router.dart")

STOCK_IMPORT = "import '../screens/seerr/seerr_discover_screen.dart';"
CUSTOM_IMPORT = (
    "import '../../features/homelab_discovery/ui/"
    "homelab_discovery_entry_screen.dart';"
)

STOCK_ROUTE = """    GoRoute(
      path: Destinations.seerrDiscover,
      builder: (context, state) => const SeerrDiscoverScreen(),
    ),"""
CUSTOM_ROUTE = """    GoRoute(
      path: Destinations.seerrDiscover,
      builder: (context, state) => const HomeLabDiscoveryEntryScreen(),
    ),"""


def classify(text: str) -> str:
    stock_import = STOCK_IMPORT in text
    custom_import = CUSTOM_IMPORT in text
    stock_route = STOCK_ROUTE in text
    custom_route = CUSTOM_ROUTE in text

    if stock_import and stock_route and not custom_import and not custom_route:
        return "stock"
    if custom_import and custom_route and not stock_import and not stock_route:
        return "custom"
    return "drift"


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()

    text = ROUTER.read_text(encoding="utf-8")
    state = classify(text)

    if args.check:
        if state != "custom":
            raise SystemExit(
                f"Discovery v2 route overlay missing or drifted (state={state})"
            )
        print("Discovery v2 route overlay: PASS")
        return 0

    if state == "custom":
        print("Discovery v2 route overlay already applied")
        return 0
    if state != "stock":
        raise SystemExit(
            "Refusing to patch app_router.dart: upstream route/import pattern drifted"
        )

    updated = text.replace(STOCK_IMPORT, CUSTOM_IMPORT, 1).replace(
        STOCK_ROUTE, CUSTOM_ROUTE, 1
    )
    if classify(updated) != "custom":
        raise SystemExit("Discovery v2 route overlay postcondition failed")

    ROUTER.write_text(updated, encoding="utf-8")
    print("Discovery v2 route overlay applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
