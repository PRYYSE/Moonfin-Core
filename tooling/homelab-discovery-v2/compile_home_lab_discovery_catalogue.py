#!/usr/bin/env python3
"""Compile the Home Lab Discovery authoring catalogue to executable schema v2.

Keyword/provider names are resolved from current server-produced lookup maps.
Reviewed semantic external-list placeholders are converted to normal executable
Discovery queries. Anything unresolved fails closed and is omitted with
explicit diagnostics instead of silently becoming a broad/misleading query.

Expected lookup inputs may be either:
  {"name": 123, ...}
or a list containing objects with `name` and `id` keys.
"""

from __future__ import annotations

import argparse
import copy
import json
import re
from pathlib import Path
from typing import Any

import generate_home_lab_discovery_catalogue as authoring
import resolve_home_lab_discovery_external_lists as external_lists


def normalise(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", value.lower()).strip()


def load_lookup(path: Path | None) -> dict[str, int]:
    if path is None:
        return {}
    raw = json.loads(path.read_text(encoding="utf-8"))
    lookup: dict[str, int] = {}
    if isinstance(raw, dict):
        for name, value in raw.items():
            if isinstance(value, dict):
                value = value.get("id")
            if value is not None:
                lookup[normalise(str(name))] = int(value)
        return lookup
    if isinstance(raw, list):
        for item in raw:
            if (
                not isinstance(item, dict)
                or item.get("name") is None
                or item.get("id") is None
            ):
                continue
            lookup[normalise(str(item["name"]))] = int(item["id"])
        return lookup
    raise ValueError(f"Unsupported lookup shape in {path}")


# Aliases are deliberately conservative. Every candidate is still resolved by
# an exact-normalised Seerr/TMDb keyword result. They only bridge author-friendly
# labels/plurals to equivalent upstream taxonomy names; they never permit fuzzy
# first-result selection.
KEYWORD_ALIASES = {
    "space deep space": ("space", "outer space"),
    "robots androids": ("robot", "android"),
    "aliens first contact": ("alien", "first contact"),
    "detectives investigations": ("detective", "investigation"),
    "espionage spies": ("spy", "espionage"),
    "mystery detective": ("detective", "mystery"),
    "cooking food": ("cooking", "food"),
    "music bands": ("music", "band"),
    "post apocalyptic": ("post-apocalyptic future", "post apocalypse"),
    "post apocalyptic series": ("post-apocalyptic future", "post apocalypse"),
    "dystopian futures": ("dystopia", "dystopian future"),
    "serial killers": ("serial killer",),
    "survival stories": ("survival",),
    "based on a true story": ("based on true story",),
    "based on true events": ("based on true story",),
    "road movies": ("road movie",),
    "superheroes": ("superhero",),
    "video games": ("video game",),
    "sports": ("sport",),
    "superpowers": ("super power", "superpower"),
    "idols": ("idol",),
    "academy award": ("academy awards",),
}

PROVIDER_ALIASES = {
    "amazon prime video": ("amazon prime video", "prime video"),
    "disney plus": ("disney plus", "disney+"),
    "apple tv plus": ("apple tv plus", "apple tv+"),
    "paramount plus": ("paramount plus", "paramount+"),
    "abc iview": ("abc iview", "abc iview free"),
}


def resolve_one(
    name: str,
    lookup: dict[str, int],
    aliases: dict[str, tuple[str, ...]],
) -> int | None:
    key = normalise(name)
    candidates = (key, *aliases.get(key, ()))
    for candidate in candidates:
        found = lookup.get(normalise(candidate))
        if found is not None:
            return found
    return None


def resolve_many(
    names: list[str],
    lookup: dict[str, int],
    aliases: dict[str, tuple[str, ...]],
) -> tuple[list[int], list[str]]:
    ids: list[int] = []
    unresolved: list[str] = []
    for name in names:
        resolved = resolve_one(name, lookup, aliases)
        if resolved is None:
            unresolved.append(name)
        elif resolved not in ids:
            ids.append(resolved)
    return ids, unresolved


def _resolve_external_section(section: dict[str, Any]) -> str | None:
    query = section["query"]
    if query.get("source") != "externalList":
        return None

    list_id = query.get("listId")
    resolution = external_lists.resolve(list_id)
    if resolution is None:
        return f"externalList:{list_id or 'missing-id'}"

    title = resolution.get("title")
    if isinstance(title, str) and title.strip():
        section["title"] = title.strip()
    section["query"] = resolution["query"]
    return "resolved"


def compile_catalogue(
    keyword_lookup: dict[str, int],
    provider_lookup: dict[str, int],
) -> tuple[dict[str, Any], dict[str, Any]]:
    catalogue = copy.deepcopy(authoring.build())
    diagnostics: dict[str, Any] = {
        "droppedSections": [],
        "resolvedKeywordSections": 0,
        "resolvedProviderSections": 0,
        "resolvedExternalListSections": 0,
        "remainingSections": {},
    }

    for tab in catalogue["tabs"]:
        compiled_sections: list[dict[str, Any]] = []
        for section in tab["sections"]:
            external_state = _resolve_external_section(section)
            if external_state not in (None, "resolved"):
                diagnostics["droppedSections"].append(
                    {"id": section["id"], "unresolved": [external_state]}
                )
                continue
            if external_state == "resolved":
                diagnostics["resolvedExternalListSections"] += 1

            query = section["query"]
            filters = dict(query.get("filters") or {})
            unresolved: list[str] = []

            keyword_names = list(query.get("keywordNames") or [])
            if keyword_names:
                ids, missing = resolve_many(
                    keyword_names,
                    keyword_lookup,
                    KEYWORD_ALIASES,
                )
                unresolved.extend(f"keyword:{name}" for name in missing)
                if not missing:
                    filters["keywords"] = ",".join(str(value) for value in ids)
                    diagnostics["resolvedKeywordSections"] += 1
                query.pop("keywordNames", None)

            exclude_names = list(query.get("excludeKeywordNames") or [])
            if exclude_names:
                ids, missing = resolve_many(
                    exclude_names,
                    keyword_lookup,
                    KEYWORD_ALIASES,
                )
                unresolved.extend(f"excludeKeyword:{name}" for name in missing)
                if not missing:
                    filters["excludeKeywords"] = ",".join(
                        str(value) for value in ids
                    )
                query.pop("excludeKeywordNames", None)

            provider_names = list(query.get("providerNames") or [])
            if provider_names:
                ids, missing = resolve_many(
                    provider_names,
                    provider_lookup,
                    PROVIDER_ALIASES,
                )
                unresolved.extend(f"provider:{name}" for name in missing)
                if not missing:
                    # Current Seerr WatchProviderSelector serialises multiple
                    # provider IDs with `|` and pairs them with watchRegion.
                    filters["watchProviders"] = "|".join(
                        str(value) for value in ids
                    )
                    filters.setdefault(
                        "watchRegion",
                        catalogue.get("defaultRegion", "AU"),
                    )
                    diagnostics["resolvedProviderSections"] += 1
                query.pop("providerNames", None)

            if unresolved:
                diagnostics["droppedSections"].append(
                    {"id": section["id"], "unresolved": unresolved}
                )
                continue

            if filters:
                query["filters"] = filters
            elif "filters" in query:
                query.pop("filters")
            compiled_sections.append(section)

        tab["sections"] = compiled_sections
        diagnostics["remainingSections"][tab["id"]] = len(compiled_sections)
        # A missing optional semantic pool must not make the tab schema invalid.
        tab["minimumLaneCount"] = min(
            int(tab["minimumLaneCount"]),
            max(1, len(compiled_sections)),
        )
        tab["initialLaneBudget"] = min(
            int(tab["initialLaneBudget"]),
            max(1, len(compiled_sections)),
        )

    catalogue["catalogueVersion"] = "home-lab-v2-compiled"
    catalogue["compileDiagnostics"] = {
        "resolvedKeywordSections": diagnostics["resolvedKeywordSections"],
        "resolvedProviderSections": diagnostics["resolvedProviderSections"],
        "resolvedExternalListSections": diagnostics[
            "resolvedExternalListSections"
        ],
        "droppedSectionCount": len(diagnostics["droppedSections"]),
    }
    _validate_compiled(catalogue)
    return catalogue, diagnostics


def _validate_compiled(catalogue: dict[str, Any]) -> None:
    section_ids: set[str] = set()
    for tab in catalogue["tabs"]:
        if not tab["sections"]:
            raise ValueError(f"Compilation removed every section from {tab['id']}")
        for section in tab["sections"]:
            section_id = section["id"]
            if section_id in section_ids:
                raise ValueError(f"Duplicate compiled section id: {section_id}")
            section_ids.add(section_id)
            query = section["query"]
            if (
                query.get("keywordNames")
                or query.get("excludeKeywordNames")
                or query.get("providerNames")
            ):
                raise ValueError(f"Unresolved semantic fields remain in {section_id}")
            if query.get("source") == "externalList":
                raise ValueError(f"Unresolved externalList remains in {section_id}")
            if query.get("listProvider") or query.get("listId"):
                raise ValueError(f"Opaque list metadata remains in {section_id}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--keyword-map",
        type=Path,
        help="Current exact Seerr/TMDb keyword name-to-id map",
    )
    parser.add_argument(
        "--provider-map",
        type=Path,
        help="Current AU watch-provider name-to-id map",
    )
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--diagnostics", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    catalogue, diagnostics = compile_catalogue(
        load_lookup(args.keyword_map),
        load_lookup(args.provider_map),
    )

    if args.check:
        print(json.dumps(diagnostics, indent=2))
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(catalogue, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    if args.diagnostics:
        args.diagnostics.parent.mkdir(parents=True, exist_ok=True)
        args.diagnostics.write_text(
            json.dumps(diagnostics, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
