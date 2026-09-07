#!/usr/bin/env python3
"""Resolve Home Lab semantic external-list placeholders into executable queries.

The authoring catalogue is allowed to describe curated concepts with stable
Home Lab IDs. Production clients are not allowed to execute opaque/fuzzy list
IDs. This module translates only explicitly reviewed IDs into normal Discovery
queries; unknown IDs return None so the compiler can fail closed.
"""

from __future__ import annotations

import copy
from typing import Any, Iterable


def q(
    source: str,
    media_type: str,
    *,
    sort: str = "popularity.desc",
    filters: dict[str, str] | None = None,
    keywords: Iterable[str] = (),
) -> dict[str, Any]:
    result: dict[str, Any] = {
        "source": source,
        "mediaType": media_type,
        "sortBy": sort,
    }
    if filters:
        result["filters"] = dict(filters)
    if keywords:
        result["keywordNames"] = list(keywords)
    return result


def anime_tv(
    *,
    sort: str = "popularity.desc",
    filters: dict[str, str] | None = None,
    keywords: Iterable[str] = (),
) -> dict[str, Any]:
    merged = {"genre": "16", "language": "ja"}
    if filters:
        merged.update(filters)
    return q("discoverTv", "tv", sort=sort, filters=merged, keywords=keywords)


def anime_movie(
    *,
    sort: str = "popularity.desc",
    filters: dict[str, str] | None = None,
    keywords: Iterable[str] = (),
) -> dict[str, Any]:
    merged = {"genre": "16", "language": "ja"}
    if filters:
        merged.update(filters)
    return q(
        "discoverMovies",
        "movie",
        sort=sort,
        filters=merged,
        keywords=keywords,
    )


# Stable TMDB company IDs for the nine studio concepts that have an exact,
# reviewed company mapping. Sunrise is deliberately not guessed: the modern
# corporate identity and historical studio catalogue do not map cleanly to one
# verified company ID, so that placeholder is compiled to a truthful semantic
# concept below instead.
_STUDIO_COMPANY_IDS = {
    "anime-studio-studio-ghibli-films": ("Studio Ghibli Films", "10342", "movie"),
    "anime-studio-kyoto-animation-spotlight": ("Kyoto Animation Spotlight", "5438", "tv"),
    "anime-studio-mappa-spotlight": ("MAPPA Spotlight", "21444", "tv"),
    "anime-studio-ufotable-spotlight": ("ufotable Spotlight", "5887", "tv"),
    "anime-studio-bones-spotlight": ("Bones Spotlight", "2849", "tv"),
    "anime-studio-madhouse-spotlight": ("Madhouse Spotlight", "3464", "tv"),
    "anime-studio-production-i-g-spotlight": ("Production I.G Spotlight", "529", "tv"),
    "anime-studio-trigger-spotlight": ("Trigger Spotlight", "50908", "tv"),
    "anime-studio-wit-studio-spotlight": ("Wit Studio Spotlight", "31058", "tv"),
}


def _studio_resolution(title: str, company_id: str, media_type: str) -> dict[str, Any]:
    filters = {"studio": company_id, "voteCountGte": "5"}
    query = (
        anime_movie(sort="vote_average.desc", filters=filters)
        if media_type == "movie"
        else anime_tv(sort="vote_average.desc", filters=filters)
    )
    return {"title": title, "query": query}


EXTERNAL_LIST_RESOLUTIONS: dict[str, dict[str, Any]] = {
    list_id: _studio_resolution(title, company_id, media_type)
    for list_id, (title, company_id, media_type) in _STUDIO_COMPANY_IDS.items()
}

EXTERNAL_LIST_RESOLUTIONS.update(
    {
        # Do not claim an exact historical Sunrise company mapping without one.
        "anime-studio-sunrise-spotlight": {
            "title": "Classic Mecha Anime Spotlight",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={
                    "firstAirDateGte": "1970-01-01",
                    "firstAirDateLte": "2010-12-31",
                    "voteCountGte": "10",
                },
                keywords=("mecha",),
            ),
        },
        # "Anime-influenced" is subjective and cannot be proven from TMDB
        # metadata alone. Compile it to an accurately labelled collection.
        "anime-international-influenced": {
            "title": "English-Language Animation Spotlight",
            "query": q(
                "discoverTv",
                "tv",
                sort="vote_average.desc",
                filters={
                    "genre": "16",
                    "language": "en",
                    "voteAverageGte": "7.0",
                    "voteCountGte": "50",
                },
            ),
        },
        "anime-seasonal-staff-picks": {
            "title": "Seasonal Anime Standouts",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={
                    "firstAirDateGte": "$monthsAgo:4",
                    "firstAirDateLte": "$today",
                    "voteAverageGte": "7.2",
                    "voteCountGte": "20",
                },
            ),
        },
        "anime-essential-anime-starter-pack": {
            "title": "Essential Anime Starter Pack",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={"voteAverageGte": "8.0", "voteCountGte": "500"},
            ),
        },
        "anime-modern-anime-essentials": {
            "title": "Modern Anime Essentials",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={
                    "firstAirDateGte": "2010-01-01",
                    "voteAverageGte": "8.0",
                    "voteCountGte": "150",
                },
            ),
        },
        "anime-classic-anime-essentials": {
            "title": "Classic Anime Essentials",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={
                    "firstAirDateLte": "2009-12-31",
                    "voteAverageGte": "7.8",
                    "voteCountGte": "75",
                },
            ),
        },
        "anime-best-anime-movies": {
            "title": "Best Anime Movies",
            "query": anime_movie(
                sort="vote_average.desc",
                filters={"voteAverageGte": "7.5", "voteCountGte": "50"},
            ),
        },
        "anime-best-sports-anime": {
            "title": "Best Sports Anime",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={"voteAverageGte": "7.2", "voteCountGte": "20"},
                keywords=("sports",),
            ),
        },
        "anime-best-mecha-anime": {
            "title": "Best Mecha Anime",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={"voteAverageGte": "7.2", "voteCountGte": "20"},
                keywords=("mecha",),
            ),
        },
        "anime-best-romance-anime": {
            "title": "Best Romance Anime",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={"voteAverageGte": "7.2", "voteCountGte": "20"},
                keywords=("romance",),
            ),
        },
        "anime-best-psychological-anime": {
            "title": "Best Psychological Anime",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={"voteAverageGte": "7.3", "voteCountGte": "20"},
                keywords=("psychological",),
            ),
        },
        "anime-best-sci-fi-anime": {
            "title": "Best Sci-Fi Anime",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={
                    "genre": "16,10765",
                    "voteAverageGte": "7.3",
                    "voteCountGte": "30",
                },
            ),
        },
        "anime-best-fantasy-anime": {
            "title": "Best Fantasy Anime",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={"voteAverageGte": "7.3", "voteCountGte": "30"},
                keywords=("fantasy",),
            ),
        },
        "anime-best-comedy-anime": {
            "title": "Best Comedy Anime",
            "query": anime_tv(
                sort="vote_average.desc",
                filters={
                    "genre": "16,35",
                    "voteAverageGte": "7.2",
                    "voteCountGte": "30",
                },
            ),
        },
    }
)


def resolve(list_id: str | None) -> dict[str, Any] | None:
    if list_id is None:
        return None
    resolution = EXTERNAL_LIST_RESOLUTIONS.get(str(list_id))
    return copy.deepcopy(resolution) if resolution is not None else None


def semantic_names() -> tuple[list[str], list[str]]:
    """Return semantic names introduced by resolutions for synthetic tests."""
    keywords: list[str] = []
    providers: list[str] = []
    for resolution in EXTERNAL_LIST_RESOLUTIONS.values():
        query = resolution["query"]
        keywords.extend(query.get("keywordNames") or [])
        keywords.extend(query.get("excludeKeywordNames") or [])
        providers.extend(query.get("providerNames") or [])
    return keywords, providers
