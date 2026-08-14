#!/usr/bin/env python3
"""Build the Home Lab Seerr Discovery schema-v2 authoring catalogue.

This file intentionally contains no credentials and does not call external
services. Human-readable keyword/provider names are compiled later by the
server catalogue compiler into exact current Seerr/TMDb IDs.

The generated catalogue is much larger than a normal visible session. Clients
use the rotation composer to select a balanced subset while every deterministic
lane remains expandable into the full filtered collection.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Iterable

SCHEMA_VERSION = 2

MOVIE_GENRES = {
    "Action": "28",
    "Adventure": "12",
    "Animation": "16",
    "Comedy": "35",
    "Crime": "80",
    "Documentary": "99",
    "Drama": "18",
    "Family": "10751",
    "Fantasy": "14",
    "History": "36",
    "Horror": "27",
    "Music & Musicals": "10402",
    "Mystery": "9648",
    "Romance": "10749",
    "Science Fiction": "878",
    "TV Movies": "10770",
    "Thriller": "53",
    "War": "10752",
    "Western": "37",
}

TV_GENRES = {
    "Action & Adventure": "10759",
    "Animation": "16",
    "Comedy": "35",
    "Crime": "80",
    "Documentary": "99",
    "Drama": "18",
    "Family": "10751",
    "Kids": "10762",
    "Mystery": "9648",
    "News": "10763",
    "Reality": "10764",
    "Sci-Fi & Fantasy": "10765",
    "Soap": "10766",
    "Talk": "10767",
    "War & Politics": "10768",
    "Western": "37",
}

MOVIE_STUDIOS = {
    "Disney": "2",
    "20th Century Studios": "127928",
    "Sony Pictures": "34",
    "Warner Bros. Pictures": "174",
    "Universal": "33",
    "Paramount": "4",
    "Pixar": "3",
    "DreamWorks": "521",
    "Marvel Studios": "420",
    "DC": "9993",
    "A24": "41077",
}

SERIES_NETWORKS = {
    "Netflix": "213",
    "Disney+": "2739",
    "Prime Video": "1024",
    "Apple TV+": "2552",
    "Hulu": "453",
    "HBO": "49",
    "Discovery+": "4353",
    "ABC": "2",
    "FOX": "19",
    "Cinemax": "359",
    "AMC": "174",
    "Showtime": "67",
    "Starz": "318",
    "The CW": "71",
    "NBC": "6",
    "CBS": "16",
    "Paramount+": "4330",
    "BBC One": "4",
    "Cartoon Network": "56",
    "Adult Swim": "80",
    "Nickelodeon": "13",
    "Peacock": "3353",
}

AU_PROVIDERS = [
    "Netflix",
    "Amazon Prime Video",
    "Disney Plus",
    "Apple TV Plus",
    "BINGE",
    "Stan",
    "Paramount Plus",
    "Shudder",
    "SBS On Demand",
    "ABC iview",
]

LANGUAGES = [
    ("Korean", "ko"),
    ("Japanese", "ja"),
    ("French", "fr"),
    ("Spanish-Language", "es"),
    ("Hindi", "hi"),
    ("Chinese-Language", "zh"),
    ("Italian", "it"),
    ("German-Language", "de"),
    ("Swedish", "sv"),
    ("Danish", "da"),
]


def slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")


def query(
    source: str,
    media_type: str,
    *,
    sort_by: str = "popularity.desc",
    filters: dict[str, str] | None = None,
    keywords: Iterable[str] = (),
    exclude_keywords: Iterable[str] = (),
    providers: Iterable[str] = (),
    seed_strategy: str | None = None,
    list_provider: str | None = None,
    list_id: str | None = None,
) -> dict[str, Any]:
    result: dict[str, Any] = {
        "source": source,
        "mediaType": media_type,
        "sortBy": sort_by,
    }
    if filters:
        result["filters"] = dict(filters)
    if keywords:
        result["keywordNames"] = list(keywords)
    if exclude_keywords:
        result["excludeKeywordNames"] = list(exclude_keywords)
    if providers:
        result["providerNames"] = list(providers)
    if seed_strategy:
        result["seedStrategy"] = seed_strategy
    if list_provider:
        result["listProvider"] = list_provider
    if list_id:
        result["listId"] = list_id
    return result


def lane(
    lane_id: str,
    title: str,
    lane_query: dict[str, Any],
    *,
    pool: str,
    priority: str = "normal",
    weight: float = 1.0,
    cooldown: int = 1,
    min_items: int = 8,
    preview_limit: int = 20,
    dedup_group: str | None = None,
    availability: str = "all",
    tags: Iterable[str] = (),
    subtitle: str | None = None,
) -> dict[str, Any]:
    result: dict[str, Any] = {
        "id": lane_id,
        "title": title,
        "query": lane_query,
        "presentation": "carousel",
        "expandable": True,
        "previewLimit": preview_limit,
        "dedupGroup": dedup_group or pool,
        "sessionDedup": True,
        "pool": pool,
        "priority": priority,
        "weight": weight,
        "cooldownSessions": cooldown,
        "minItems": min_items,
        "availabilityMode": availability,
    }
    if tags:
        result["tags"] = list(tags)
    if subtitle:
        result["subtitle"] = subtitle
    return result


def personal_lane(lane_id: str, title: str, strategy: str, media_type: str = "all") -> dict[str, Any]:
    return lane(
        lane_id,
        title,
        query("personalised", media_type, seed_strategy=strategy),
        pool="personal",
        priority="high" if strategy in {"recent-history", "favourites", "watchlist"} else "normal",
        cooldown=0,
        availability="all",
        tags=("personal",),
    )


def movie_lanes() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []

    anchors = [
        ("trending", "Trending Movies", query("trending", "movie")),
        ("popular", "Popular Movies", query("discoverMovies", "movie")),
        ("acclaimed", "Critically Acclaimed", query("discoverMovies", "movie", sort_by="vote_average.desc", filters={"voteAverageGte": "7.5", "voteCountGte": "1000"})),
        ("audience", "Audience Favourites", query("discoverMovies", "movie", sort_by="vote_average.desc", filters={"voteAverageGte": "7.0", "voteCountGte": "5000"})),
        ("new-releases", "New Releases", query("discoverMovies", "movie", filters={"primaryReleaseDateGte": "$monthsAgo:6", "primaryReleaseDateLte": "$today"})),
        ("fresh-month", "Fresh This Month", query("discoverMovies", "movie", filters={"primaryReleaseDateGte": "$monthsAgo:1", "primaryReleaseDateLte": "$today"})),
        ("current", "Current Releases", query("discoverMovies", "movie", filters={"primaryReleaseDateGte": "$monthsAgo:2", "primaryReleaseDateLte": "$monthsFromNow:1"})),
        ("coming-soon", "Coming Soon", query("upcomingMovies", "movie")),
        ("anticipated", "Highly Anticipated", query("discoverMovies", "movie", filters={"primaryReleaseDateGte": "$today", "primaryReleaseDateLte": "$yearsFromNow:2", "voteCountGte": "20"})),
        ("recently-added", "Recently Added Movies", query("personalised", "movie", seed_strategy="recently-added")),
    ]
    for key, title, q in anchors:
        rows.append(lane(f"movies-{key}", title, q, pool="movie-anchor", priority="anchor", cooldown=0, dedup_group="movies-main"))

    discovery = [
        ("hidden-gems", "Hidden Gems", {"voteAverageGte": "7.0", "voteCountGte": "150", "voteCountLte": "1500"}, "vote_average.desc"),
        ("deep-cuts", "Deep Cuts", {"voteAverageGte": "6.8", "voteCountGte": "50", "voteCountLte": "500"}, "vote_average.desc"),
        ("underseen-masterpieces", "Underseen Masterpieces", {"voteAverageGte": "7.8", "voteCountGte": "100", "voteCountLte": "1000"}, "vote_average.desc"),
        ("crowd-pleasers", "Crowd-Pleasing Picks", {"voteAverageGte": "6.8", "voteCountGte": "10000"}, "popularity.desc"),
        ("critics-corner", "Critics' Corner", {"voteAverageGte": "8.0", "voteCountGte": "1000"}, "vote_average.desc"),
        ("great-not-obvious", "Great but Not Obvious", {"voteAverageGte": "7.2", "voteCountGte": "500", "voteCountLte": "3000"}, "vote_average.desc"),
        ("polarising", "Polarising Movies", {"voteCountGte": "500"}, "popularity.desc"),
        ("modern-classics", "Modern Classics", {"primaryReleaseDateGte": "2000-01-01", "voteAverageGte": "7.5", "voteCountGte": "3000"}, "vote_average.desc"),
        ("cult-favourites", "Cult Favourites", {"voteCountGte": "100"}, "popularity.desc"),
        ("one-to-watch", "One to Watch", {"primaryReleaseDateGte": "$yearsAgo:2", "voteAverageGte": "7.0", "voteCountGte": "100", "voteCountLte": "3000"}, "vote_average.desc"),
    ]
    for key, title, filters, sort_by in discovery:
        keywords = ("cult film",) if key == "cult-favourites" else ()
        rows.append(lane(f"movies-{key}", title, query("discoverMovies", "movie", sort_by=sort_by, filters=filters, keywords=keywords), pool="movie-discovery", dedup_group="movies-deep"))

    runtimes = [
        ("under-90", "Under 90 Minutes", {"withRuntimeLte": "90", "voteAverageGte": "6.0"}),
        ("short-brilliant", "Short and Brilliant", {"withRuntimeLte": "105", "voteAverageGte": "6.8", "voteCountGte": "150"}),
        ("easy-two-hour", "Easy Two-Hour Watch", {"withRuntimeGte": "90", "withRuntimeLte": "125"}),
        ("long-worth-it", "Long but Worth It", {"withRuntimeGte": "125", "withRuntimeLte": "160", "voteAverageGte": "7.0"}),
        ("epic-night", "Epic Movie Night", {"withRuntimeGte": "150", "voteAverageGte": "7.0", "voteCountGte": "500"}),
        ("three-hour", "Three-Hour Epics", {"withRuntimeGte": "175", "voteAverageGte": "7.0"}),
        ("quick-comedy", "Quick Comedy", {"genre": "35", "withRuntimeLte": "100", "voteAverageGte": "6.0"}),
        ("quick-thriller", "Quick Thriller", {"genre": "53", "withRuntimeLte": "105", "voteAverageGte": "6.0"}),
    ]
    for key, title, filters in runtimes:
        rows.append(lane(f"movies-{key}", title, query("discoverMovies", "movie", filters=filters), pool="movie-runtime", dedup_group="movies-runtime"))

    eras = [
        ("2020s", "2020s Standouts", "2020-01-01", "$today"),
        ("2010s", "Best of the 2010s", "2010-01-01", "2019-12-31"),
        ("2000s", "Best of the 2000s", "2000-01-01", "2009-12-31"),
        ("1990s", "'90s Essentials", "1990-01-01", "1999-12-31"),
        ("1980s", "'80s Favourites", "1980-01-01", "1989-12-31"),
        ("1970s", "'70s Cinema", "1970-01-01", "1979-12-31"),
        ("mid-century", "Mid-Century Classics", "1940-01-01", "1969-12-31"),
        ("early-cinema", "Early Cinema", "1900-01-01", "1939-12-31"),
    ]
    for key, title, start, end in eras:
        rows.append(lane(f"movies-era-{key}", title, query("discoverMovies", "movie", sort_by="vote_average.desc", filters={"primaryReleaseDateGte": start, "primaryReleaseDateLte": end, "voteAverageGte": "6.8", "voteCountGte": "50"}), pool="movie-era", dedup_group="movies-era"))

    for title, genre_id in MOVIE_GENRES.items():
        rows.append(lane(f"movies-genre-{slug(title)}", title, query("discoverMovies", "movie", filters={"genre": genre_id, "voteCountGte": "50"}), pool="movie-genres", dedup_group="movies-genres"))

    combos = [
        ("Action Comedy", "28,35"), ("Action Thriller", "28,53"), ("Action Adventure", "28,12"),
        ("Sci-Fi Thriller", "878,53"), ("Sci-Fi Adventure", "878,12"), ("Sci-Fi Horror", "878,27"),
        ("Horror Comedy", "27,35"), ("Psychological Mystery", "9648,53"), ("Crime Thriller", "80,53"),
        ("Crime Drama", "80,18"), ("Romantic Comedy", "10749,35"), ("Romantic Drama", "10749,18"),
        ("Fantasy Adventure", "14,12"), ("Family Animation", "10751,16"), ("Historical Drama", "36,18"),
        ("War Drama", "10752,18"),
    ]
    for title, ids in combos:
        extra_keywords = ("psychological",) if title == "Psychological Mystery" else ()
        rows.append(lane(f"movies-mix-{slug(title)}", title, query("discoverMovies", "movie", filters={"genre": ids, "voteCountGte": "30"}, keywords=extra_keywords), pool="movie-mixes", dedup_group="movies-mixes"))

    themes = [
        "Space & Deep Space", "Time Travel", "Superheroes", "Post-Apocalyptic", "Dystopian Futures",
        "Cyberpunk", "Artificial Intelligence", "Robots & Androids", "Aliens & First Contact", "Heist Movies",
        "Serial Killers", "Survival Stories", "Based on a True Story", "Coming of Age", "Road Movies", "Martial Arts",
    ]
    theme_keywords = {
        "Space & Deep Space": ("space", "outer space"),
        "Robots & Androids": ("robot", "android"),
        "Aliens & First Contact": ("alien", "first contact"),
        "Heist Movies": ("heist",),
        "Serial Killers": ("serial killer",),
        "Survival Stories": ("survival",),
        "Based on a True Story": ("based on true story",),
        "Coming of Age": ("coming of age",),
        "Road Movies": ("road movie",),
        "Martial Arts": ("martial arts",),
    }
    for title in themes:
        keywords = theme_keywords.get(title, (title.lower().replace(" & ", " "),))
        rows.append(lane(f"movies-theme-{slug(title)}", title, query("discoverMovies", "movie", filters={"voteCountGte": "25"}, keywords=keywords), pool="movie-themes", dedup_group="movies-themes"))

    for title, studio_id in MOVIE_STUDIOS.items():
        rows.append(lane(f"movies-studio-{slug(title)}", title, query("discoverMovies", "movie", filters={"studio": studio_id}), pool="movie-studios", dedup_group="movies-studios"))

    for title, code in LANGUAGES:
        rows.append(lane(f"movies-language-{slug(title)}", f"{title} Cinema", query("discoverMovies", "movie", sort_by="vote_average.desc", filters={"language": code, "voteCountGte": "30", "voteAverageGte": "6.5"}), pool="movie-languages", dedup_group="movies-languages"))

    for provider in AU_PROVIDERS:
        rows.append(lane(f"movies-provider-{slug(provider)}", f"{provider} Movies", query("discoverMovies", "movie", filters={"watchRegion": "AU"}, providers=(provider,)), pool="movie-providers", dedup_group="movies-providers"))

    occasions = [
        ("Friday Night Popcorn", {"genre": "28|35|12", "voteCountGte": "500"}, ()),
        ("Family Weekend", {"genre": "10751|16|12", "withRuntimeLte": "130"}, ()),
        ("Date Night", {"genre": "10749|35|18", "voteAverageGte": "6.2"}, ()),
        ("Late-Night Thrillers", {"genre": "53|9648|80", "voteAverageGte": "6.0"}, ()),
        ("Horror Night", {"genre": "27", "voteAverageGte": "6.0", "voteCountGte": "100"}, ()),
        ("Halloween Rotation", {"genre": "27"}, ("halloween",)),
        ("Christmas Movies", {}, ("christmas",)),
        ("Summer Blockbusters", {"genre": "28|12|878", "voteCountGte": "1000"}, ()),
        ("Rainy-Day Comfort Movies", {"genre": "35|10751|10749", "voteAverageGte": "6.3"}, ()),
        ("Documentary Night", {"genre": "99", "voteAverageGte": "7.0"}, ()),
        ("Awards Season", {"voteAverageGte": "7.0", "voteCountGte": "500"}, ("academy award",)),
        ("Festival & Indie Spotlight", {"voteAverageGte": "7.0", "voteCountGte": "50", "voteCountLte": "2500"}, ("independent film",)),
    ]
    for title, filters, keywords in occasions:
        rows.append(lane(f"movies-occasion-{slug(title)}", title, query("discoverMovies", "movie", filters=filters, keywords=keywords), pool="movie-occasions", dedup_group="movies-occasions"))

    assert len(rows) == 130, len(rows)
    return rows


def series_lanes() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []

    anchors = [
        ("trending", "Trending Series", query("trending", "tv")),
        ("popular", "Popular Series", query("discoverTv", "tv")),
        ("acclaimed", "Acclaimed Series", query("discoverTv", "tv", sort_by="vote_average.desc", filters={"voteAverageGte": "7.5", "voteCountGte": "500"})),
        ("new-returning", "New & Returning Series", query("discoverTv", "tv", filters={"firstAirDateGte": "$monthsAgo:12", "firstAirDateLte": "$monthsFromNow:3"})),
        ("fresh-premieres", "Fresh Premieres", query("discoverTv", "tv", filters={"firstAirDateGte": "$monthsAgo:3", "firstAirDateLte": "$today"})),
        ("upcoming", "Upcoming Series", query("upcomingTv", "tv")),
        ("binge-worthy", "Binge-Worthy", query("discoverTv", "tv", sort_by="vote_average.desc", filters={"genre": "18|80|35|10765", "voteAverageGte": "7.2", "voteCountGte": "200"})),
        ("limited", "Limited-Series Spotlight", query("personalised", "tv", seed_strategy="limited-series")),
        ("recently-added", "Recently Added Series", query("personalised", "tv", seed_strategy="recently-added")),
        ("continue-exploring", "Continue Exploring Series", query("personalised", "tv", seed_strategy="recent-discovery-context")),
    ]
    for key, title, q in anchors:
        rows.append(lane(f"series-{key}", title, q, pool="series-anchor", priority="anchor", cooldown=0, dedup_group="series-main"))

    discovery = [
        ("hidden-gems", "Hidden Series Gems", {"voteAverageGte": "7.5", "voteCountGte": "75", "voteCountLte": "1000"}),
        ("underseen", "Underseen Greats", {"voteAverageGte": "8.0", "voteCountGte": "50", "voteCountLte": "750"}),
        ("crowd", "Crowd Favourites", {"voteAverageGte": "7.0", "voteCountGte": "5000"}),
        ("critics", "Critics' Picks", {"voteAverageGte": "8.0", "voteCountGte": "500"}),
        ("great-not-obvious", "Great but Not Obvious", {"voteAverageGte": "7.3", "voteCountGte": "250", "voteCountLte": "2500"}),
        ("modern-classics", "Modern TV Classics", {"firstAirDateGte": "2000-01-01", "voteAverageGte": "7.7", "voteCountGte": "1000"}),
        ("recent-breakouts", "Recent Breakouts", {"firstAirDateGte": "$yearsAgo:2", "voteAverageGte": "7.2", "voteCountGte": "100"}),
        ("one-season", "One-Season Wonders", {}),
        ("long-running", "Long-Running Favourites", {}),
        ("catch-up", "Worth Catching Up On", {"firstAirDateLte": "$yearsAgo:2", "voteAverageGte": "7.5", "voteCountGte": "500"}),
    ]
    for key, title, filters in discovery:
        source = "personalised" if key in {"one-season", "long-running"} else "discoverTv"
        q = query(source, "tv", sort_by="vote_average.desc", filters=filters, seed_strategy=key if source == "personalised" else None)
        rows.append(lane(f"series-{key}", title, q, pool="series-discovery", dedup_group="series-deep"))

    runtimes = [
        ("half-hour-comedy", "Half-Hour Comedy", {"genre": "35", "withRuntimeLte": "35"}),
        ("short-episodes", "Short Episodes", {"withRuntimeLte": "30"}),
        ("45-minute", "Easy 45-Minute Watch", {"withRuntimeGte": "35", "withRuntimeLte": "50"}),
        ("hour-drama", "Hour-Long Drama", {"genre": "18", "withRuntimeGte": "45", "withRuntimeLte": "70"}),
        ("long-drama", "Long-Form Drama", {"genre": "18", "withRuntimeGte": "60"}),
        ("quick-crime", "Quick Crime Fix", {"genre": "80", "withRuntimeLte": "45"}),
        ("quick-reality", "Quick Reality Watch", {"genre": "10764", "withRuntimeLte": "50"}),
        ("weekend-binge", "Weekend Binge", {}),
    ]
    for key, title, filters in runtimes:
        source = "personalised" if key == "weekend-binge" else "discoverTv"
        rows.append(lane(f"series-{key}", title, query(source, "tv", filters=filters, seed_strategy=key if source == "personalised" else None), pool="series-runtime", dedup_group="series-runtime"))

    eras = [
        ("2020s", "2020s Standouts", "2020-01-01", "$today"),
        ("2010s", "Best of the 2010s", "2010-01-01", "2019-12-31"),
        ("2000s", "Best of the 2000s", "2000-01-01", "2009-12-31"),
        ("1990s", "'90s TV Favourites", "1990-01-01", "1999-12-31"),
        ("1980s", "'80s Television", "1980-01-01", "1989-12-31"),
        ("1970s", "'70s Television", "1970-01-01", "1979-12-31"),
        ("classic", "Classic TV 1950s-1960s", "1950-01-01", "1969-12-31"),
        ("vintage", "Vintage Television", "1900-01-01", "1949-12-31"),
    ]
    for key, title, start, end in eras:
        rows.append(lane(f"series-era-{key}", title, query("discoverTv", "tv", sort_by="vote_average.desc", filters={"firstAirDateGte": start, "firstAirDateLte": end, "voteAverageGte": "6.8", "voteCountGte": "30"}), pool="series-era", dedup_group="series-era"))

    for title, genre_id in TV_GENRES.items():
        rows.append(lane(f"series-genre-{slug(title)}", title, query("discoverTv", "tv", filters={"genre": genre_id, "voteCountGte": "25"}), pool="series-genres", dedup_group="series-genres"))

    # Add one extra normal-TV lane to reach the planned 16 direct genre routes.
    rows.append(lane("series-genre-live-variety", "Live & Variety", query("discoverTv", "tv", filters={"genre": "10767|10764", "voteCountGte": "10"}), pool="series-genres", priority="low", dedup_group="series-genres"))

    combos = [
        ("Crime & Mystery", "80,9648"), ("Crime Drama", "80,18"), ("Mystery Drama", "9648,18"),
        ("Sci-Fi Drama", "10765,18"), ("Fantasy Drama", "10765,18"), ("Action Drama", "10759,18"),
        ("Action Comedy", "10759,35"), ("Comedy Drama", "35,18"), ("Family Comedy", "10751,35"),
        ("Political Drama", "10768,18"), ("War Drama", "10768,18"), ("Western Drama", "37,18"),
        ("Documentary Crime", "99,80"), ("Reality Competition", "10764"), ("Mystery Sci-Fi", "9648,10765"),
        ("Adventure Fantasy", "10759,10765"),
    ]
    for title, ids in combos:
        keywords: tuple[str, ...] = ()
        if title == "Reality Competition":
            keywords = ("competition",)
        if title == "Fantasy Drama":
            keywords = ("fantasy",)
        rows.append(lane(f"series-mix-{slug(title)}", title, query("discoverTv", "tv", filters={"genre": ids, "voteCountGte": "20"}, keywords=keywords), pool="series-mixes", dedup_group="series-mixes"))

    themes = [
        "Time Travel", "Space & Deep Space", "Dystopian Futures", "Post-Apocalyptic Series", "Artificial Intelligence",
        "Robots & Androids", "Superheroes", "Serial Killers", "Detectives & Investigations", "Legal Drama",
        "Medical Drama", "Workplace Comedy", "Coming of Age", "High School & Teen Drama", "Survival",
        "Based on True Events", "Espionage & Spies", "Supernatural Mysteries",
    ]
    theme_keywords = {
        "Space & Deep Space": ("space", "outer space"),
        "Robots & Androids": ("robot", "android"),
        "Serial Killers": ("serial killer",),
        "Detectives & Investigations": ("detective", "investigation"),
        "Legal Drama": ("lawyer", "courtroom"),
        "Medical Drama": ("hospital", "doctor"),
        "Workplace Comedy": ("workplace",),
        "High School & Teen Drama": ("high school", "teenager"),
        "Based on True Events": ("based on true story",),
        "Espionage & Spies": ("spy", "espionage"),
        "Supernatural Mysteries": ("supernatural",),
    }
    for title in themes:
        rows.append(lane(f"series-theme-{slug(title)}", title, query("discoverTv", "tv", filters={"voteCountGte": "15"}, keywords=theme_keywords.get(title, (title.lower(),))), pool="series-themes", dedup_group="series-themes"))

    for title, network_id in SERIES_NETWORKS.items():
        rows.append(lane(f"series-network-{slug(title)}", title, query("discoverTv", "tv", filters={"network": network_id}), pool="series-networks", dedup_group="series-networks"))

    for title, code in LANGUAGES:
        label = f"{title} Series"
        rows.append(lane(f"series-language-{slug(title)}", label, query("discoverTv", "tv", sort_by="vote_average.desc", filters={"language": code, "voteCountGte": "20", "voteAverageGte": "6.5"}), pool="series-languages", dedup_group="series-languages"))

    for provider in AU_PROVIDERS:
        rows.append(lane(f"series-provider-{slug(provider)}", f"{provider} Series", query("discoverTv", "tv", filters={"watchRegion": "AU"}, providers=(provider,)), pool="series-providers", dedup_group="series-providers"))

    occasions = [
        ("Friday Night Binge", {"genre": "18|80|35", "voteCountGte": "100"}, ()),
        ("Easy Background Comedy", {"genre": "35", "withRuntimeLte": "35"}, ("workplace",)),
        ("Edge-of-Your-Seat", {"genre": "80|9648|10759", "voteAverageGte": "6.5"}, ()),
        ("Big Sci-Fi Night", {"genre": "10765", "voteAverageGte": "7.0"}, ()),
        ("Family Series Night", {"genre": "10751|35|10759"}, ()),
        ("Documentary Weekend", {"genre": "99", "voteAverageGte": "7.0"}, ()),
        ("Reality Competition Night", {"genre": "10764"}, ("competition",)),
        ("Prestige Drama", {"genre": "18", "voteAverageGte": "7.8", "voteCountGte": "500"}, ()),
        ("Comfort Rewatch Candidates", {}, ()),
        ("Dark & Twisty", {"genre": "9648|80|18", "voteAverageGte": "6.8"}, ("psychological",)),
        ("Light & Funny", {"genre": "35", "voteAverageGte": "6.8"}, ()),
        ("Something Completely Different", {}, ()),
    ]
    for title, filters, keywords in occasions:
        personal = title in {"Comfort Rewatch Candidates", "Something Completely Different"}
        q = query("personalised" if personal else "discoverTv", "tv", filters=filters, keywords=keywords, seed_strategy=slug(title) if personal else None)
        rows.append(lane(f"series-occasion-{slug(title)}", title, q, pool="series-occasions", dedup_group="series-occasions"))

    assert len(rows) == 140, len(rows)
    return rows


ANIME_THEME_KEYWORDS = [
    "isekai", "reincarnation", "another world", "magic", "supernatural", "demons", "vampires", "yokai",
    "ghost stories", "mecha", "giant robots", "cyberpunk", "post-apocalyptic", "dystopian", "space opera",
    "space travel", "aliens", "time travel", "parallel worlds", "virtual reality", "video games",
    "artificial intelligence", "school life", "high school", "coming of age", "slice of life", "romance",
    "romantic comedy", "love triangle", "sports", "martial arts", "samurai", "ninja", "sword fighting",
    "tournament", "superpowers", "superheroes", "mystery detective", "psychological", "thriller", "survival",
    "death game", "cooking food", "music bands", "idols", "workplace", "family", "friendship", "based on manga",
    "based on light novel",
]


def anime_base_filters(extra: dict[str, str] | None = None) -> dict[str, str]:
    filters = {"genre": "16", "language": "ja"}
    if extra:
        filters.update(extra)
    return filters


def anime_lanes() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []

    anchors = [
        ("popular", "Popular Anime", query("discoverTv", "tv", filters=anime_base_filters())),
        ("top-rated", "Top Rated Anime", query("discoverTv", "tv", sort_by="vote_average.desc", filters=anime_base_filters({"voteCountGte": "100"}))),
        ("trending", "Trending Anime", query("personalised", "tv", seed_strategy="trending-anime")),
        ("new-season", "New This Season", query("discoverTv", "tv", filters=anime_base_filters({"firstAirDateGte": "$monthsAgo:3", "firstAirDateLte": "$monthsFromNow:1"}))),
        ("fresh-month", "Fresh This Month", query("discoverTv", "tv", filters=anime_base_filters({"firstAirDateGte": "$monthsAgo:1", "firstAirDateLte": "$today"}))),
        ("seasonal-hits", "Recent Seasonal Hits", query("discoverTv", "tv", sort_by="vote_average.desc", filters=anime_base_filters({"firstAirDateGte": "$monthsAgo:6", "voteCountGte": "30"}))),
        ("upcoming", "Upcoming Anime", query("discoverTv", "tv", filters=anime_base_filters({"firstAirDateGte": "$today", "firstAirDateLte": "$yearsFromNow:2"}))),
        ("fresh-discoveries", "Fresh Discoveries", query("discoverTv", "tv", sort_by="vote_average.desc", filters=anime_base_filters({"voteCountGte": "20", "voteCountLte": "500"}))),
        ("hidden-gems", "Hidden Anime Gems", query("discoverTv", "tv", sort_by="vote_average.desc", filters=anime_base_filters({"voteAverageGte": "7.2", "voteCountGte": "50", "voteCountLte": "800"}))),
        ("movies", "Anime Movies", query("discoverMovies", "movie", filters={"genre": "16", "language": "ja"})),
        ("classics", "Anime Classics", query("discoverTv", "tv", sort_by="vote_average.desc", filters=anime_base_filters({"firstAirDateLte": "1999-12-31", "voteCountGte": "30"}))),
        ("unseen", "Highly Rated and Unseen Anime", query("personalised", "tv", seed_strategy="anime-highly-rated-unseen")),
    ]
    for key, title, q in anchors:
        rows.append(lane(f"anime-{key}", title, q, pool="anime-anchor", priority="anchor", cooldown=0, dedup_group="anime-main", tags=("anime",)))

    seasonal = [
        ("current-season", "Current Season Anime", "$monthsAgo:3", "$monthsFromNow:1"),
        ("previous-season", "Previous Season Highlights", "$monthsAgo:6", "$monthsAgo:3"),
        ("six-months", "Last 6 Months", "$monthsAgo:6", "$today"),
        ("twelve-months", "Last 12 Months", "$monthsAgo:12", "$today"),
        ("new-movies", "New Anime Movies", "$monthsAgo:12", "$today"),
        ("upcoming-movies", "Upcoming Anime Movies", "$today", "$yearsFromNow:2"),
        ("2020s", "2020s Anime Standouts", "2020-01-01", "$today"),
        ("2010s", "Best of the 2010s", "2010-01-01", "2019-12-31"),
        ("2000s", "Best of the 2000s", "2000-01-01", "2009-12-31"),
        ("1990s", "'90s Anime", "1990-01-01", "1999-12-31"),
        ("1980s", "'80s Anime", "1980-01-01", "1989-12-31"),
        ("1970s", "'70s Anime", "1970-01-01", "1979-12-31"),
        ("pre-1970", "Classic Anime Before 1970", "1900-01-01", "1969-12-31"),
        ("recent-hidden", "Recent Hidden Gems", "$yearsAgo:3", "$today"),
        ("new-rated", "New & Highly Rated", "$yearsAgo:2", "$today"),
        ("long-running", "Recent Long-Running Hits", "$yearsAgo:5", "$today"),
    ]
    for key, title, start, end in seasonal:
        is_movie = key in {"new-movies", "upcoming-movies"}
        source = "discoverMovies" if is_movie else "discoverTv"
        media_type = "movie" if is_movie else "tv"
        date_gte = "primaryReleaseDateGte" if is_movie else "firstAirDateGte"
        date_lte = "primaryReleaseDateLte" if is_movie else "firstAirDateLte"
        filters = {"genre": "16", "language": "ja", date_gte: start, date_lte: end, "voteCountGte": "15"}
        rows.append(lane(f"anime-time-{key}", title, query(source, media_type, sort_by="vote_average.desc", filters=filters), pool="anime-time", dedup_group="anime-time", tags=("anime",)))

    rating_lanes = [
        ("acclaimed", "Acclaimed Anime", {"voteAverageGte": "8.0", "voteCountGte": "200"}),
        ("fan-favourites", "Fan Favourites", {"voteAverageGte": "7.5", "voteCountGte": "1000"}),
        ("underseen", "Underseen Greats", {"voteAverageGte": "7.7", "voteCountGte": "50", "voteCountLte": "500"}),
        ("deep-cuts", "Deep-Cut Anime", {"voteAverageGte": "7.0", "voteCountGte": "20", "voteCountLte": "250"}),
        ("modern-classics", "Modern Anime Classics", {"firstAirDateGte": "2000-01-01", "voteAverageGte": "8.0", "voteCountGte": "500"}),
        ("recent-breakouts", "Recent Breakouts", {"firstAirDateGte": "$yearsAgo:2", "voteAverageGte": "7.5", "voteCountGte": "75"}),
        ("one-to-watch", "One to Watch", {"firstAirDateGte": "$yearsAgo:2", "voteAverageGte": "7.3", "voteCountGte": "30", "voteCountLte": "600"}),
        ("not-library", "Popular but Not in Your Library", {}),
        ("movie-top", "Top Rated Anime Movies", {}),
        ("movie-hidden", "Hidden Anime Movies", {}),
        ("older-acclaimed", "Acclaimed Older Anime", {"firstAirDateLte": "2009-12-31", "voteAverageGte": "7.8", "voteCountGte": "50"}),
        ("different", "Something Different", {}),
    ]
    for key, title, extra in rating_lanes:
        if key in {"not-library", "different"}:
            q = query("personalised", "tv", seed_strategy=f"anime-{key}")
        elif key.startswith("movie-"):
            movie_filters = {"genre": "16", "language": "ja", "voteAverageGte": "7.0", "voteCountGte": "20"}
            if key == "movie-hidden":
                movie_filters.update({"voteCountLte": "800"})
            q = query("discoverMovies", "movie", sort_by="vote_average.desc", filters=movie_filters)
        else:
            q = query("discoverTv", "tv", sort_by="vote_average.desc", filters=anime_base_filters(extra))
        rows.append(lane(f"anime-rating-{key}", title, q, pool="anime-rating", dedup_group="anime-rating", tags=("anime",)))

    direct = [
        ("Action-Packed Anime", "10759", ()), ("Adventure Anime", "10759", ("adventure",)),
        ("Comedy Anime", "35", ()), ("Drama Anime", "18", ()), ("Mystery Anime", "9648", ()),
        ("Sci-Fi Anime", "10765", ("science fiction",)), ("Fantasy Anime", "10765", ("fantasy",)),
        ("Family-Friendly Anime", "10751", ()), ("Kids Anime", "10762", ()), ("War & Politics Anime", "10768", ()),
        ("Action Comedy Anime", "10759,35", ()), ("Action Drama Anime", "10759,18", ()),
        ("Mystery Drama Anime", "9648,18", ()), ("Sci-Fi Action Anime", "10765,10759", ("science fiction",)),
        ("Fantasy Adventure Anime", "10765,10759", ("fantasy",)), ("Comedy Drama Anime", "35,18", ()),
        ("Dark Mystery Anime", "9648,18", ("supernatural",)), ("Family Adventure Anime", "10751,10759", ()),
        ("Historical Anime", "18", ("historical",)), ("Music Anime", "18", ("music",)),
    ]
    for title, extra_genres, keywords in direct:
        filters = anime_base_filters({"genre": f"16,{extra_genres}", "voteCountGte": "10"})
        rows.append(lane(f"anime-genre-{slug(title)}", title, query("discoverTv", "tv", filters=filters, keywords=keywords), pool="anime-genres", dedup_group="anime-genres", tags=("anime",)))

    assert len(ANIME_THEME_KEYWORDS) == 50, len(ANIME_THEME_KEYWORDS)
    for keyword in ANIME_THEME_KEYWORDS:
        title = keyword.title().replace("Ai", "AI")
        rows.append(lane(f"anime-theme-{slug(keyword)}", title, query("discoverTv", "tv", filters=anime_base_filters({"voteCountGte": "5"}), keywords=(keyword,)), pool="anime-themes", dedup_group="anime-themes", tags=("anime", "theme"), min_items=6))

    formats = [
        ("Short-Form Anime", query("discoverTv", "tv", filters=anime_base_filters({"withRuntimeLte": "15"}))),
        ("Standard Episodes", query("discoverTv", "tv", filters=anime_base_filters({"withRuntimeGte": "20", "withRuntimeLte": "30"}))),
        ("Longer Episodes", query("discoverTv", "tv", filters=anime_base_filters({"withRuntimeGte": "35"}))),
        ("Quick Anime Movie", query("discoverMovies", "movie", filters={"genre": "16", "language": "ja", "withRuntimeLte": "100"})),
        ("Epic Anime Movie", query("discoverMovies", "movie", filters={"genre": "16", "language": "ja", "withRuntimeGte": "120", "voteAverageGte": "7.0"})),
        ("Anime Specials & TV Movies", query("personalised", "all", seed_strategy="anime-specials")),
        ("One-Season Anime", query("personalised", "tv", seed_strategy="anime-one-season")),
        ("Long-Running Anime", query("personalised", "tv", seed_strategy="anime-long-running")),
        ("Bingeable Anime", query("personalised", "tv", seed_strategy="anime-bingeable")),
        ("Completed Anime", query("personalised", "tv", seed_strategy="anime-completed")),
        ("Continuing Anime", query("personalised", "tv", seed_strategy="anime-continuing")),
        ("Anime Miniseries & Short Runs", query("personalised", "tv", seed_strategy="anime-short-runs")),
    ]
    for title, q in formats:
        rows.append(lane(f"anime-format-{slug(title)}", title, q, pool="anime-format", dedup_group="anime-format", tags=("anime",)))

    anime_studios = [
        "Studio Ghibli Films", "Kyoto Animation Spotlight", "MAPPA Spotlight", "ufotable Spotlight", "Bones Spotlight",
        "Madhouse Spotlight", "Production I.G Spotlight", "Trigger Spotlight", "Wit Studio Spotlight", "Sunrise Spotlight",
    ]
    for title in anime_studios:
        list_id = slug(title.replace(" Spotlight", "").replace(" Films", ""))
        rows.append(lane(f"anime-studio-{list_id}", title, query("externalList", "all", list_provider="server", list_id=f"anime-studio-{list_id}"), pool="anime-studios", dedup_group="anime-studios", tags=("anime", "curated"), min_items=5))

    global_animation = [
        ("Donghua & Chinese Animation", "zh"),
        ("Korean Animation", "ko"),
        ("International Anime-Influenced Animation", "curated"),
    ]
    for title, lang in global_animation:
        q = query("externalList", "all", list_provider="server", list_id="anime-international") if lang == "curated" else query("discoverTv", "tv", filters={"genre": "16", "language": lang})
        rows.append(lane(f"anime-global-{slug(title)}", title, q, pool="anime-global", dedup_group="anime-global", tags=("animation",), priority="low"))

    personal = [
        ("Because You Watched Anime", "anime-recent-history"),
        ("More Like Your Favourite Anime", "anime-favourites"),
        ("Inspired by Your Anime Watchlist", "anime-watchlist"),
        ("More Action Anime for You", "anime-action-affinity"),
        ("More Fantasy Anime for You", "anime-fantasy-affinity"),
        ("More Romance & Drama Anime for You", "anime-romance-drama-affinity"),
        ("Anime Outside Your Usual Genres", "anime-novelty"),
        ("Highly Rated Anime You Missed", "anime-highly-rated-unseen"),
        ("Similar to Anime You Rated Highly", "anime-high-ratings"),
        ("Recent Anime Based on Your Taste", "anime-recent-affinity"),
        ("Older Anime Based on Your Taste", "anime-older-affinity"),
        ("Anime Movies Based on Your Taste", "anime-movie-affinity"),
        ("Short Anime Based on Your Taste", "anime-short-affinity"),
    ]
    for title, strategy in personal:
        rows.append(personal_lane(f"anime-personal-{slug(title)}", title, strategy, "all"))

    curated = [
        "Seasonal Staff Picks", "Essential Anime Starter Pack", "Modern Anime Essentials", "Classic Anime Essentials",
        "Best Anime Movies", "Best Sports Anime", "Best Mecha Anime", "Best Romance Anime", "Best Psychological Anime",
        "Best Sci-Fi Anime", "Best Fantasy Anime", "Best Comedy Anime",
    ]
    for title in curated:
        list_id = f"anime-{slug(title)}"
        rows.append(lane(f"anime-list-{slug(title)}", title, query("externalList", "all", list_provider="server", list_id=list_id), pool="anime-lists", dedup_group="anime-lists", tags=("anime", "curated"), min_items=5))

    assert len(rows) == 160, len(rows)
    return rows


def for_you_lanes() -> list[dict[str, Any]]:
    definitions = [
        ("because-watched", "Because You Watched", "recent-history"),
        ("favourites", "More Like Your Favourites", "favourites"),
        ("watchlist", "Inspired by Your Watchlist", "watchlist"),
        ("ratings", "Based on Your Highest Ratings", "high-ratings"),
        ("likes", "More From Things You Like", "likes"),
        ("mixed", "Picked From Your Taste", "mixed-positive"),
        ("unseen", "Highly Rated and Unseen", "highly-rated-unseen"),
        ("novelty", "Something Different", "novelty"),
        ("movie", "Movies for You", "movie-affinity"),
        ("series", "Series for You", "series-affinity"),
        ("anime", "Anime for You", "anime-affinity"),
        ("short", "Short Picks for You", "short-runtime-affinity"),
        ("older", "Older Gems for You", "older-affinity"),
        ("recent", "Recent Releases for You", "recent-affinity"),
        ("rewatch", "Worth Rewatching", "rewatch"),
        ("continue-exploring", "Continue Exploring", "recent-discovery-context"),
    ]
    return [personal_lane(f"for-you-{key}", title, strategy) for key, title, strategy in definitions]


def new_upcoming_lanes() -> list[dict[str, Any]]:
    definitions = [
        ("movies-week", "Movies Arriving This Week", "movie", "primaryReleaseDateGte", "$today", "primaryReleaseDateLte", "$monthsFromNow:1"),
        ("movies-month", "Movies Coming Soon", "movie", "primaryReleaseDateGte", "$today", "primaryReleaseDateLte", "$monthsFromNow:3"),
        ("movies-year", "Movies on the Horizon", "movie", "primaryReleaseDateGte", "$today", "primaryReleaseDateLte", "$yearsFromNow:1"),
        ("series-week", "Series Premiering Soon", "tv", "firstAirDateGte", "$today", "firstAirDateLte", "$monthsFromNow:1"),
        ("series-month", "Series Coming Soon", "tv", "firstAirDateGte", "$today", "firstAirDateLte", "$monthsFromNow:3"),
        ("series-year", "Series on the Horizon", "tv", "firstAirDateGte", "$today", "firstAirDateLte", "$yearsFromNow:1"),
        ("anime-week", "Anime Arriving Soon", "anime", "firstAirDateGte", "$today", "firstAirDateLte", "$monthsFromNow:1"),
        ("anime-season", "Next Anime Season", "anime", "firstAirDateGte", "$today", "firstAirDateLte", "$monthsFromNow:4"),
    ]
    rows: list[dict[str, Any]] = []
    for key, title, media_type, gte_key, gte, lte_key, lte in definitions:
        is_movie = media_type == "movie"
        source = "discoverMovies" if is_movie else "discoverTv"
        mt = "movie" if is_movie else "tv"
        filters = {gte_key: gte, lte_key: lte}
        if media_type == "anime":
            filters.update({"genre": "16", "language": "ja"})
        rows.append(lane(f"new-{key}", title, query(source, mt, filters=filters), pool="new-upcoming", priority="high" if "month" in key or "season" in key else "normal", dedup_group=f"new-{media_type}"))

    # Additional current/recent windows keep this tab useful even when future
    # metadata is sparse.
    extras = [
        ("movies-last-month", "Movies Released Last Month", "discoverMovies", "movie", {"primaryReleaseDateGte": "$monthsAgo:1", "primaryReleaseDateLte": "$today"}),
        ("movies-last-six", "Recent Movie Releases", "discoverMovies", "movie", {"primaryReleaseDateGte": "$monthsAgo:6", "primaryReleaseDateLte": "$today"}),
        ("series-last-month", "Series Premiered This Month", "discoverTv", "tv", {"firstAirDateGte": "$monthsAgo:1", "firstAirDateLte": "$today"}),
        ("series-last-six", "Recent Series Premieres", "discoverTv", "tv", {"firstAirDateGte": "$monthsAgo:6", "firstAirDateLte": "$today"}),
        ("anime-last-month", "Fresh Anime This Month", "discoverTv", "tv", {"genre": "16", "language": "ja", "firstAirDateGte": "$monthsAgo:1", "firstAirDateLte": "$today"}),
        ("anime-last-six", "Recent Anime Releases", "discoverTv", "tv", {"genre": "16", "language": "ja", "firstAirDateGte": "$monthsAgo:6", "firstAirDateLte": "$today"}),
        ("movie-anticipated", "Most Anticipated Movies", "discoverMovies", "movie", {"primaryReleaseDateGte": "$today", "voteCountGte": "20"}),
        ("series-anticipated", "Most Anticipated Series", "discoverTv", "tv", {"firstAirDateGte": "$today", "voteCountGte": "20"}),
        ("anime-anticipated", "Most Anticipated Anime", "discoverTv", "tv", {"genre": "16", "language": "ja", "firstAirDateGte": "$today", "voteCountGte": "10"}),
        ("movie-new-acclaimed", "New Acclaimed Movies", "discoverMovies", "movie", {"primaryReleaseDateGte": "$yearsAgo:1", "voteAverageGte": "7.3", "voteCountGte": "100"}),
        ("series-new-acclaimed", "New Acclaimed Series", "discoverTv", "tv", {"firstAirDateGte": "$yearsAgo:1", "voteAverageGte": "7.5", "voteCountGte": "75"}),
        ("anime-new-acclaimed", "New Acclaimed Anime", "discoverTv", "tv", {"genre": "16", "language": "ja", "firstAirDateGte": "$yearsAgo:1", "voteAverageGte": "7.5", "voteCountGte": "30"}),
    ]
    for key, title, source, media_type, filters in extras:
        rows.append(lane(f"new-{key}", title, query(source, media_type, sort_by="vote_average.desc" if "acclaimed" in key else "popularity.desc", filters=filters), pool="new-upcoming", dedup_group=f"new-{media_type}"))

    assert len(rows) == 20, len(rows)
    return rows


def lists_lanes() -> list[dict[str, Any]]:
    families = [
        ("movie-awards", "Award Winners & Nominees", "movie"),
        ("movie-best-picture", "Best Picture Winners", "movie"),
        ("movie-modern-classics", "Modern Movie Classics", "movie"),
        ("movie-essential-scifi", "Essential Sci-Fi", "movie"),
        ("movie-essential-horror", "Essential Horror", "movie"),
        ("movie-australian", "Australian Cinema Spotlight", "movie"),
        ("series-prestige", "Prestige TV Essentials", "tv"),
        ("series-limited", "Limited Series Essentials", "tv"),
        ("series-crime", "Best Crime Series", "tv"),
        ("series-scifi", "Best Sci-Fi Series", "tv"),
        ("series-australian", "Australian Series Spotlight", "tv"),
        ("anime-starter", "Anime Starter Pack", "all"),
        ("anime-modern", "Modern Anime Essentials", "all"),
        ("anime-classic", "Classic Anime Essentials", "all"),
        ("anime-movies", "Best Anime Movies", "movie"),
        ("anime-mecha", "Best Mecha Anime", "tv"),
        ("anime-romance", "Best Romance Anime", "tv"),
        ("anime-psychological", "Best Psychological Anime", "tv"),
        ("anime-seasonal", "Seasonal Anime Staff Picks", "tv"),
        ("recently-refreshed", "Recently Refreshed Lists", "all"),
    ]
    return [
        lane(
            f"lists-{list_id}",
            title,
            query("externalList", media_type, list_provider="server", list_id=list_id),
            pool="lists",
            priority="high" if list_id in {"recently-refreshed", "anime-seasonal"} else "normal",
            dedup_group="lists",
            min_items=5,
            tags=("curated",),
        )
        for list_id, title, media_type in families
    ]


def tab(
    tab_id: str,
    title: str,
    sections: list[dict[str, Any]],
    *,
    lane_budget: int,
    minimum: int,
    pool_budgets: dict[str, int],
) -> dict[str, Any]:
    return {
        "id": tab_id,
        "title": title,
        "sections": sections,
        "initialLaneBudget": lane_budget,
        "minimumLaneCount": minimum,
        "poolBudgets": pool_budgets,
    }


def build_catalogue() -> dict[str, Any]:
    movies = movie_lanes()
    series = series_lanes()
    anime = anime_lanes()
    for_you = for_you_lanes()
    new = new_upcoming_lanes()
    lists = lists_lanes()

    catalogue = {
        "schemaVersion": SCHEMA_VERSION,
        "catalogueVersion": "home-lab-v2-authoring",
        "defaultRegion": "AU",
        "tabs": [
            tab("for-you", "For You", for_you, lane_budget=16, minimum=10, pool_budgets={"personal": 16}),
            tab("movies", "Movies", movies, lane_budget=24, minimum=18, pool_budgets={
                "movie-anchor": 10, "movie-discovery": 4, "movie-runtime": 2, "movie-era": 2,
                "movie-genres": 4, "movie-mixes": 3, "movie-themes": 3, "movie-studios": 2,
                "movie-languages": 2, "movie-providers": 2, "movie-occasions": 2,
            }),
            tab("series", "Series", series, lane_budget=24, minimum=18, pool_budgets={
                "series-anchor": 10, "series-discovery": 4, "series-runtime": 2, "series-era": 2,
                "series-genres": 4, "series-mixes": 3, "series-themes": 3, "series-networks": 3,
                "series-languages": 2, "series-providers": 2, "series-occasions": 2,
            }),
            tab("anime", "Anime", anime, lane_budget=26, minimum=20, pool_budgets={
                "anime-anchor": 12, "anime-time": 3, "anime-rating": 3, "anime-genres": 4,
                "anime-themes": 6, "anime-format": 2, "anime-studios": 2, "anime-global": 1,
                "personal": 4, "anime-lists": 3,
            }),
            tab("new-upcoming", "New & Upcoming", new, lane_budget=16, minimum=10, pool_budgets={"new-upcoming": 16}),
            tab("lists", "Lists", lists, lane_budget=16, minimum=8, pool_budgets={"lists": 16}),
        ],
    }
    validate_catalogue(catalogue)
    return catalogue


def validate_catalogue(catalogue: dict[str, Any]) -> None:
    tabs = catalogue.get("tabs") or []
    tab_ids: set[str] = set()
    section_ids: set[str] = set()
    counts: dict[str, int] = {}

    for tab_data in tabs:
        tab_id = tab_data["id"]
        if not tab_id or tab_id in tab_ids:
            raise ValueError(f"Duplicate/empty tab id: {tab_id!r}")
        tab_ids.add(tab_id)
        sections = tab_data.get("sections") or []
        counts[tab_id] = len(sections)
        if tab_data["minimumLaneCount"] > tab_data["initialLaneBudget"]:
            raise ValueError(f"Invalid lane budgets for {tab_id}")

        for section in sections:
            section_id = section["id"]
            if not section_id or section_id in section_ids:
                raise ValueError(f"Duplicate/empty section id: {section_id!r}")
            section_ids.add(section_id)
            if not 1 <= int(section["minItems"]) <= int(section["previewLimit"]) <= 100:
                raise ValueError(f"Invalid item limits for {section_id}")
            if float(section["weight"]) <= 0:
                raise ValueError(f"Invalid weight for {section_id}")

    expected = {
        "for-you": 16,
        "movies": 130,
        "series": 140,
        "anime": 160,
        "new-upcoming": 20,
        "lists": 20,
    }
    if counts != expected:
        raise ValueError(f"Catalogue count regression: expected {expected}, got {counts}")

    total = sum(counts.values())
    if total != 486:
        raise ValueError(f"Expected 486 total authoring lanes, got {total}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, help="Write formatted JSON to this path. Defaults to stdout.")
    parser.add_argument("--compact", action="store_true", help="Emit compact JSON.")
    parser.add_argument("--check", action="store_true", help="Validate and print lane counts only.")
    args = parser.parse_args()

    catalogue = build_catalogue()
    counts = {tab_data["id"]: len(tab_data["sections"]) for tab_data in catalogue["tabs"]}
    if args.check:
        print(json.dumps({"schemaVersion": SCHEMA_VERSION, "total": sum(counts.values()), "tabs": counts}, indent=2))
        return 0

    text = json.dumps(
        catalogue,
        ensure_ascii=False,
        indent=None if args.compact else 2,
        separators=(",", ":") if args.compact else None,
    ) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
