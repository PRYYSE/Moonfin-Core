#!/usr/bin/env python3
"""Idempotent wrapper for personalised expanded Discovery browse.

v2's source transforms are retained; only the Discovery-screen transform is
made safely re-runnable so CI can apply then immediately verify the exact same
checkout with --check.
"""

from __future__ import annotations

import apply_personalised_expanded_browse_patch_v2 as base


def patch_discover(text: str) -> str:
    capability_new = (
        "  bool _canExpand(SeerrDeepDiscoveryRow row) => "
        "row.section.expandable;\n"
    )
    route_new = "        sectionId: row.section.id,\n"

    if capability_new not in text:
        text = base.replace_once(
            text,
            "  bool _canExpand(SeerrDeepDiscoveryRow row) {\n"
            "    final source = row.section.query.source;\n"
            "    return row.section.expandable &&\n"
            "        source != SeerrDiscoverySource.personalised;\n"
            "  }\n",
            capability_new,
            "landing personalised See All capability",
        )

    if route_new not in text:
        text = base.replace_once(
            text,
            "      queryParameters: SeerrDiscoveryRouteCodec.encode(\n"
            "        row.section.query,\n"
            "        title: row.title,\n"
            "      ),\n",
            "      queryParameters: SeerrDiscoveryRouteCodec.encode(\n"
            "        row.section.query,\n"
            "        title: row.title,\n"
            "        sectionId: row.section.id,\n"
            "      ),\n",
            "landing route section identity",
        )
    return text


base.patch_discover = patch_discover


if __name__ == "__main__":
    raise SystemExit(base.main())
