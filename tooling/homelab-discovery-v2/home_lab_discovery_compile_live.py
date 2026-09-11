#!/usr/bin/env python3
"""Compile Discovery v2 against the configured live Seerr safely.

The command is read-only against Jellyfin and Seerr. It reuses existing local
credentials without printing them, resolves semantic keyword/provider names to
current IDs, drops ambiguous or unavailable optional lanes, and atomically
writes the compiled catalogue plus diagnostics under the persistent Home Lab
Discovery root.

It does not install the catalogue or modify Moonbase/Jellyfin.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from home_lab_safe_auth import jellyfin_token  # noqa: E402
from home_lab_seerr_auth import seerr_get  # noqa: E402
import compile_home_lab_discovery_catalogue as compiler  # noqa: E402
import generate_home_lab_discovery_catalogue as generator  # noqa: E402

DEFAULT_JELLYFIN_URL = os.environ.get(
    "MOONFIN_JELLYFIN_URL", "http://127.0.0.1:8096"
).rstrip("/")
DEFAULT_ROOT = Path(
    os.environ.get("MOONFIN_DISCOVERY_ROOT", "/srv/appdata/moonfin/discovery")
)
DEFAULT_OUTPUT = DEFAULT_ROOT / "discovery.catalogue.json"
DEFAULT_CACHE = DEFAULT_ROOT / "semantic-resolution-cache.json"
DEFAULT_DIAGNOSTICS = DEFAULT_ROOT / "diagnostics.json"


def request_json(method: str, path: str, token: str) -> Any:
    """Call the local Jellyfin API without ever logging the bearer token."""
    target = f"{DEFAULT_JELLYFIN_URL}/{path.lstrip('/')}"
    request = urllib.request.Request(
        target,
        headers={
            "Accept": "application/json",
            "Authorization": f'MediaBrowser Token="{token}"',
            "User-Agent": "HomeLabDiscoveryCompiler/2.0",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read()
            return json.loads(raw.decode("utf-8")) if raw else None
    except urllib.error.HTTPError as exc:
        raise RuntimeError(
            f"Jellyfin {method} {path} returned HTTP {exc.code}."
        ) from None
    except (urllib.error.URLError, TimeoutError) as exc:
        raise RuntimeError(
            f"Jellyfin {method} {path} could not reach the configured server."
        ) from exc


def load_cache(path: Path) -> dict[str, Any]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
        return raw if isinstance(raw, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def atomic_write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(value, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, path)
    finally:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass


def authoring_semantics() -> tuple[
    dict[str, set[str]], dict[str, tuple[str, tuple[str, ...]]]
]:
    """Return keyword candidates and provider requirements by section ID."""
    catalogue = generator.build()
    keywords: dict[str, set[str]] = {}
    providers: dict[str, tuple[str, tuple[str, ...]]] = {}
    for tab in catalogue["tabs"]:
        for section in tab["sections"]:
            query = section["query"]
            for name in query.get("keywordNames") or []:
                key = compiler.normalise(str(name))
                candidates = {str(name)}
                candidates.update(compiler.KEYWORD_ALIASES.get(key, ()))
                keywords.setdefault(key, set()).update(candidates)
            for name in query.get("excludeKeywordNames") or []:
                key = compiler.normalise(str(name))
                candidates = {str(name)}
                candidates.update(compiler.KEYWORD_ALIASES.get(key, ()))
                keywords.setdefault(key, set()).update(candidates)
            provider_names = tuple(str(v) for v in query.get("providerNames") or [])
            if provider_names:
                providers[section["id"]] = (
                    str(query.get("mediaType") or "all"),
                    provider_names,
                )
    return keywords, providers


def _keyword_results(payload: Any) -> list[dict[str, Any]]:
    if not isinstance(payload, dict):
        return []
    raw = payload.get("results")
    if not isinstance(raw, list):
        return []
    return [item for item in raw if isinstance(item, dict)]


def resolve_keywords(
    token: str,
    requirements: dict[str, set[str]],
    cache: dict[str, Any],
    *,
    force_refresh: bool,
) -> tuple[dict[str, int], list[str]]:
    cached = cache.setdefault("keywords", {})
    lookup: dict[str, int] = {}
    unresolved: list[str] = []

    for requested_key in sorted(requirements):
        candidates = sorted(
            requirements[requested_key],
            key=lambda value: (
                compiler.normalise(value) != requested_key,
                len(value),
                value.lower(),
            ),
        )
        resolved_id: int | None = None

        if not force_refresh:
            value = cached.get(requested_key)
            if isinstance(value, int) and value > 0:
                resolved_id = value

        for candidate in candidates:
            candidate_key = compiler.normalise(candidate)
            if resolved_id is not None:
                break
            if not force_refresh:
                value = cached.get(candidate_key)
                if isinstance(value, int) and value > 0:
                    resolved_id = value
                    break

            encoded = urllib.parse.quote(candidate, safe="")
            payload = seerr_get(
                token,
                f"search/keyword?query={encoded}",
                request_json,
            )
            exact = [
                item
                for item in _keyword_results(payload)
                if compiler.normalise(str(item.get("name") or "")) == candidate_key
                and str(item.get("id") or "").isdigit()
            ]
            exact_ids = {int(item["id"]) for item in exact}
            if len(exact_ids) == 1:
                resolved_id = next(iter(exact_ids))
                cached[candidate_key] = resolved_id
                actual_name = str(exact[0].get("name") or "")
                if actual_name:
                    cached[compiler.normalise(actual_name)] = resolved_id

        if resolved_id is None:
            unresolved.append(requested_key)
            continue
        cached[requested_key] = resolved_id
        lookup[requested_key] = resolved_id
        for candidate in candidates:
            lookup.setdefault(compiler.normalise(candidate), resolved_id)

    return lookup, unresolved


def provider_map(token: str, media_type: str) -> dict[str, int]:
    endpoint = "movies" if media_type == "movie" else "tv"
    payload = seerr_get(
        token,
        f"watchproviders/{endpoint}?watchRegion=AU",
        request_json,
    )
    if not isinstance(payload, list):
        raise RuntimeError(
            f"Seerr watchproviders/{endpoint} returned an unexpected response."
        )
    result: dict[str, int] = {}
    for item in payload:
        if not isinstance(item, dict):
            continue
        name = compiler.normalise(str(item.get("name") or ""))
        raw_id = item.get("id")
        try:
            provider_id = int(raw_id)
        except (TypeError, ValueError):
            continue
        if name and provider_id > 0:
            result[name] = provider_id
    return result


def provider_union(movie: dict[str, int], tv: dict[str, int]) -> dict[str, int]:
    """Use only non-conflicting universal TMDb provider IDs."""
    result = dict(movie)
    for name, provider_id in tv.items():
        existing = result.get(name)
        if existing is None:
            result[name] = provider_id
        elif existing != provider_id:
            result.pop(name, None)
    return result


def provider_available(
    provider_name: str,
    media_type: str,
    movie: dict[str, int],
    tv: dict[str, int],
) -> bool:
    key = compiler.normalise(provider_name)
    candidate_names = (key, *compiler.PROVIDER_ALIASES.get(key, ()))
    selected = movie if media_type == "movie" else tv if media_type == "tv" else {}
    return any(
        compiler.normalise(candidate) in selected for candidate in candidate_names
    )


def prune_provider_availability(
    compiled: dict[str, Any],
    requirements: dict[str, tuple[str, tuple[str, ...]]],
    movie: dict[str, int],
    tv: dict[str, int],
) -> list[dict[str, Any]]:
    dropped: list[dict[str, Any]] = []
    for tab in compiled["tabs"]:
        retained: list[dict[str, Any]] = []
        for section in tab["sections"]:
            requirement = requirements.get(section["id"])
            if requirement is None:
                retained.append(section)
                continue
            media_type, names = requirement
            missing = [
                name
                for name in names
                if not provider_available(name, media_type, movie, tv)
            ]
            if missing:
                dropped.append(
                    {
                        "id": section["id"],
                        "reason": "provider-unavailable-in-AU-for-media-type",
                        "mediaType": media_type,
                        "providers": missing,
                    }
                )
            else:
                retained.append(section)
        tab["sections"] = retained
        tab["minimumLaneCount"] = min(
            int(tab["minimumLaneCount"]), max(1, len(retained))
        )
        tab["initialLaneBudget"] = min(
            int(tab["initialLaneBudget"]), max(1, len(retained))
        )
    return dropped


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--diagnostics", type=Path, default=DEFAULT_DIAGNOSTICS)
    parser.add_argument("--force-refresh", action="store_true")
    args = parser.parse_args()

    token = jellyfin_token()
    keyword_requirements, provider_requirements = authoring_semantics()
    cache = load_cache(args.cache)

    keyword_lookup, unresolved_keyword_names = resolve_keywords(
        token,
        keyword_requirements,
        cache,
        force_refresh=args.force_refresh,
    )
    movie_providers = provider_map(token, "movie")
    tv_providers = provider_map(token, "tv")
    combined_providers = provider_union(movie_providers, tv_providers)

    compiled, compile_diagnostics = compiler.compile_catalogue(
        keyword_lookup,
        combined_providers,
    )
    provider_drops = prune_provider_availability(
        compiled,
        provider_requirements,
        movie_providers,
        tv_providers,
    )

    compiled["catalogueVersion"] = "home-lab-v2-live-compiled"
    compiled["defaultRegion"] = "AU"
    compiled["compileDiagnostics"] = {
        "authoringLaneCount": 486,
        "compiledLaneCount": sum(
            len(tab["sections"]) for tab in compiled["tabs"]
        ),
        "unresolvedSemanticSectionCount": len(
            compile_diagnostics.get("droppedSections") or []
        ),
        "providerAvailabilityDropCount": len(provider_drops),
    }

    diagnostics = {
        "schemaVersion": compiled.get("schemaVersion"),
        "authoringLaneCount": 486,
        "compiledLaneCount": compiled["compileDiagnostics"]["compiledLaneCount"],
        "unresolvedKeywordNames": unresolved_keyword_names,
        "semanticDrops": compile_diagnostics.get("droppedSections") or [],
        "providerAvailabilityDrops": provider_drops,
        "tabCounts": {
            tab["id"]: len(tab["sections"]) for tab in compiled["tabs"]
        },
    }

    atomic_write_json(args.output, compiled)
    atomic_write_json(args.cache, cache)
    atomic_write_json(args.diagnostics, diagnostics)

    print(
        "Discovery catalogue compiled safely: "
        f"{diagnostics['compiledLaneCount']}/486 lanes; "
        f"unresolved_keywords={len(unresolved_keyword_names)}; "
        f"semantic_drops={len(diagnostics['semanticDrops'])}; "
        f"provider_drops={len(provider_drops)}"
    )
    print(f"catalogue={args.output}")
    print(f"diagnostics={args.diagnostics}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
