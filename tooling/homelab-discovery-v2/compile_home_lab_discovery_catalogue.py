#!/usr/bin/env python3
"""Compile the Home Lab Discovery authoring catalogue to executable schema v2.

Keyword/provider names are resolved from current server-produced lookup maps.
Reviewed semantic and personalisation overrides are applied only when their
source assumptions still match exactly. Anything unresolved fails closed and is
omitted with explicit diagnostics instead of silently becoming broad or
misleading.

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


# The authored catalogue intentionally remains stable at 486 lanes. This
# reviewed compile-time overlay converts its original For You placeholders into
# a truthful set that the current Flutter personal-source adapters can execute.
# Every row is guarded by its old ID + strategy so upstream authoring drift fails
# loudly instead of silently changing the meaning of personal recommendations.
REVIEWED_FOR_YOU_OVERRIDES = (
    (
        "for-you-because-you-watched",
        "recent-history",
        "for-you-movies-from-watch-history",
        "Movies Based on Your Watch History",
        "recent-history",
        "movie",
    ),
    (
        "for-you-more-like-your-favourites",
        "favourites",
        "for-you-series-from-watch-history",
        "Series Based on Your Watch History",
        "recent-history",
        "tv",
    ),
    (
        "for-you-inspired-by-your-watchlist",
        "watchlist",
        "for-you-inspired-by-favourites",
        "Inspired by Your Favourites",
        "favourites",
        "all",
    ),
    (
        "for-you-based-on-your-highest-ratings",
        "high-ratings",
        "for-you-inspired-by-watchlist",
        "Inspired by Your Watchlist",
        "watchlist",
        "all",
    ),
    (
        "for-you-more-from-things-you-like",
        "likes",
        "for-you-based-on-high-ratings",
        "Because You Rated These Highly",
        "high-ratings",
        "all",
    ),
    (
        "for-you-picked-from-your-taste",
        "mixed-positive",
        "for-you-based-on-likes",
        "Based on Things You Like",
        "likes",
        "all",
    ),
    (
        "for-you-highly-rated-and-unseen",
        "highly-rated-unseen",
        "for-you-highly-rated-unseen",
        "Highly Rated Picks You Haven't Seen",
        "highly-rated-unseen",
        "all",
    ),
    (
        "for-you-something-different",
        "novelty",
        "for-you-try-something-different",
        "Try Something Different",
        "novelty",
        "all",
    ),
    (
        "for-you-movies-for-you",
        "movie-affinity",
        "for-you-movies-you-might-like",
        "Movies You Might Like",
        "movie-affinity",
        "movie",
    ),
    (
        "for-you-series-for-you",
        "series-affinity",
        "for-you-series-you-might-like",
        "Series You Might Like",
        "series-affinity",
        "tv",
    ),
    (
        "for-you-anime-for-you",
        "anime-affinity",
        "for-you-anime-you-might-like",
        "Anime You Might Like",
        "anime-affinity",
        "all",
    ),
    (
        "for-you-short-picks-for-you",
        "short-runtime-affinity",
        "for-you-quick-picks",
        "Quick Picks for You",
        "short-runtime-affinity",
        "all",
    ),
    (
        "for-you-older-gems-for-you",
        "older-affinity",
        "for-you-older-gems",
        "Older Gems for You",
        "older-affinity",
        "all",
    ),
    (
        "for-you-recent-releases-for-you",
        "recent-affinity",
        "for-you-recent-picks",
        "Recent Picks for You",
        "recent-affinity",
        "all",
    ),
    (
        "for-you-worth-rewatching",
        "rewatch",
        "for-you-worth-rewatching",
        "Worth Rewatching",
        "rewatch",
        "all",
    ),
    (
        "for-you-continue-exploring",
        "recent-discovery-context",
        "for-you-based-on-your-taste",
        "Based on Your Taste",
        "mixed-positive",
        "all",
    ),
)


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


def apply_reviewed_semantic_overrides(catalogue: dict[str, Any]) -> None:
    """Translate reviewed compound semantics that upstream no longer names directly."""

    target_id = "anime-theme-romantic-comedy"
    for tab in catalogue.get("tabs") or []:
        for section in tab.get("sections") or []:
            if section.get("id") != target_id:
                continue

            query = section.get("query") or {}
            filters = dict(query.get("filters") or {})
            if (
                query.get("source") != "discoverTv"
                or query.get("mediaType") != "tv"
                or list(query.get("keywordNames") or []) != ["romantic comedy"]
                or filters.get("genre") != "16"
                or filters.get("language") != "ja"
            ):
                raise ValueError(
                    "Reviewed Romantic Comedy source semantics changed; "
                    "refusing to apply a stale override"
                )

            # TMDb removed the historical exact `romantic comedy` keyword.
            # `lighthearted romantic comedy` is narrower, so do not alias to it.
            # Preserve the broad authored meaning as Japanese Animation + Comedy
            # constrained by the still-exact broad `romance` keyword.
            filters["genre"] = "16,35"
            query["filters"] = filters
            query["keywordNames"] = ["romance"]
            return

    raise ValueError(f"Reviewed semantic target is missing: {target_id}")


def apply_reviewed_for_you_overrides(catalogue: dict[str, Any]) -> None:
    """Make For You truthful, useful with sparse personal data, and self-explanatory."""

    for tab in catalogue.get("tabs") or []:
        if tab.get("id") != "for-you":
            continue

        sections = list(tab.get("sections") or [])
        by_id = {str(section.get("id")): section for section in sections}
        expected_ids = {entry[0] for entry in REVIEWED_FOR_YOU_OVERRIDES}
        if len(sections) != len(REVIEWED_FOR_YOU_OVERRIDES) or set(by_id) != expected_ids:
            raise ValueError(
                "Reviewed For You authoring shape changed; refusing to apply a stale override"
            )

        for (
            old_id,
            expected_seed,
            new_id,
            new_title,
            new_seed,
            media_type,
        ) in REVIEWED_FOR_YOU_OVERRIDES:
            section = by_id[old_id]
            query = section.get("query") or {}
            if (
                query.get("source") != "personalised"
                or query.get("seedStrategy") != expected_seed
                or query.get("mediaType") != "all"
                or section.get("pool") != "personal"
                or int(section.get("minItems") or 0) != 8
            ):
                raise ValueError(
                    f"Reviewed For You source semantics changed for {old_id}; "
                    "refusing to apply a stale override"
                )

            section["id"] = new_id
            section["title"] = new_title
            section["minItems"] = 4
            query["seedStrategy"] = new_seed
            query["mediaType"] = media_type

        tab["minimumLaneCount"] = 4
        return

    raise ValueError("Reviewed For You tab is missing")


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
    apply_reviewed_semantic_overrides(catalogue)
    apply_reviewed_for_you_overrides(catalogue)
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

    for_you = next(
        (tab for tab in catalogue["tabs"] if tab.get("id") == "for-you"),
        None,
    )
    if for_you is None or len(for_you["sections"]) != 16:
        raise ValueError("Compiled For You must retain all 16 reviewed lanes")
    if int(for_you.get("minimumLaneCount") or 0) != 4:
        raise ValueError("Compiled For You minimum lane count must be 4")
    if any(int(section.get("minItems") or 0) != 4 for section in for_you["sections"]):
        raise ValueError("Every compiled For You lane must use minItems=4")

    expected = {
        new_id: (new_title, new_seed, media_type)
        for _, _, new_id, new_title, new_seed, media_type in REVIEWED_FOR_YOU_OVERRIDES
    }
    actual = {
        section["id"]: (
            section["title"],
            section["query"].get("seedStrategy"),
            section["query"].get("mediaType"),
        )
        for section in for_you["sections"]
    }
    if actual != expected:
        raise ValueError("Compiled For You semantics differ from the reviewed contract")


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
