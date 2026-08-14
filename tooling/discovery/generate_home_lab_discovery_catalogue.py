#!/usr/bin/env python3
"""Generate Home Lab's schema-v2 Seerr Discovery authoring catalogue.

No secrets or network calls live here. Keyword/provider names intentionally stay
human-readable until the Moonbase catalogue compiler resolves them against the
current Seerr/TMDb data and serves a compiled catalogue to clients.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Iterable

SCHEMA_VERSION = 2


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def q(
    source: str,
    media_type: str,
    *,
    sort: str = "popularity.desc",
    filters: dict[str, str] | None = None,
    keywords: Iterable[str] = (),
    providers: Iterable[str] = (),
    seed: str | None = None,
    list_id: str | None = None,
) -> dict[str, Any]:
    out: dict[str, Any] = {"source": source, "mediaType": media_type, "sortBy": sort}
    if filters:
        out["filters"] = dict(filters)
    if keywords:
        out["keywordNames"] = list(keywords)
    if providers:
        out["providerNames"] = list(providers)
    if seed:
        out["seedStrategy"] = seed
    if list_id:
        out["listProvider"] = "server"
        out["listId"] = list_id
    return out


def lane(
    lane_id: str,
    title: str,
    query: dict[str, Any],
    pool: str,
    *,
    priority: str = "normal",
    weight: float = 1.0,
    cooldown: int = 1,
    min_items: int = 8,
    availability: str = "all",
    tags: Iterable[str] = (),
) -> dict[str, Any]:
    out: dict[str, Any] = {
        "id": lane_id,
        "title": title,
        "query": query,
        "presentation": "carousel",
        "expandable": True,
        "previewLimit": 20,
        "dedupGroup": pool,
        "sessionDedup": True,
        "pool": pool,
        "priority": priority,
        "weight": weight,
        "cooldownSessions": cooldown,
        "minItems": min_items,
        "availabilityMode": availability,
    }
    if tags:
        out["tags"] = list(tags)
    return out


def add_keywords(
    rows: list[dict[str, Any]],
    prefix: str,
    names: Iterable[str],
    *,
    source: str,
    media_type: str,
    pool: str,
    base_filters: dict[str, str] | None = None,
    tags: Iterable[str] = (),
) -> None:
    for name in names:
        rows.append(
            lane(
                f"{prefix}-{slug(name)}",
                name,
                q(source, media_type, filters=base_filters, keywords=(name.lower(),)),
                pool,
                tags=tags,
                min_items=6,
            )
        )


MOVIE_GENRES = {
    "Action": "28", "Adventure": "12", "Animation": "16", "Comedy": "35", "Crime": "80",
    "Documentary": "99", "Drama": "18", "Family": "10751", "Fantasy": "14", "History": "36",
    "Horror": "27", "Music & Musicals": "10402", "Mystery": "9648", "Romance": "10749",
    "Science Fiction": "878", "TV Movies": "10770", "Thriller": "53", "War": "10752", "Western": "37",
}
TV_GENRES = {
    "Action & Adventure": "10759", "Animation": "16", "Comedy": "35", "Crime": "80",
    "Documentary": "99", "Drama": "18", "Family": "10751", "Kids": "10762", "Mystery": "9648",
    "News": "10763", "Reality": "10764", "Sci-Fi & Fantasy": "10765", "Soap": "10766", "Talk": "10767",
    "War & Politics": "10768", "Western": "37",
}
MOVIE_STUDIOS = {
    "Disney": "2", "20th Century Studios": "127928", "Sony Pictures": "34", "Warner Bros. Pictures": "174",
    "Universal": "33", "Paramount": "4", "Pixar": "3", "DreamWorks": "521", "Marvel Studios": "420",
    "DC": "9993", "A24": "41077",
}
SERIES_NETWORKS = {
    "Netflix": "213", "Disney+": "2739", "Prime Video": "1024", "Apple TV+": "2552", "Hulu": "453",
    "HBO": "49", "Discovery+": "4353", "ABC": "2", "FOX": "19", "Cinemax": "359", "AMC": "174",
    "Showtime": "67", "Starz": "318", "The CW": "71", "NBC": "6", "CBS": "16", "Paramount+": "4330",
    "BBC One": "4", "Cartoon Network": "56", "Adult Swim": "80", "Nickelodeon": "13", "Peacock": "3353",
}
LANGUAGES = [
    ("Korean", "ko"), ("Japanese", "ja"), ("French", "fr"), ("Spanish-Language", "es"),
    ("Hindi", "hi"), ("Chinese-Language", "zh"), ("Italian", "it"), ("German-Language", "de"),
    ("Swedish", "sv"), ("Danish", "da"),
]
AU_PROVIDERS = [
    "Netflix", "Amazon Prime Video", "Disney Plus", "Apple TV Plus", "BINGE",
    "Stan", "Paramount Plus", "Shudder", "SBS On Demand", "ABC iview",
]


def movies() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    anchors = [
        ("trending", "Trending Movies", q("trending", "movie")),
        ("popular", "Popular Movies", q("discoverMovies", "movie")),
        ("acclaimed", "Critically Acclaimed", q("discoverMovies", "movie", sort="vote_average.desc", filters={"voteAverageGte": "7.5", "voteCountGte": "1000"})),
        ("audience", "Audience Favourites", q("discoverMovies", "movie", sort="vote_average.desc", filters={"voteAverageGte": "7.0", "voteCountGte": "5000"})),
        ("new", "New Releases", q("discoverMovies", "movie", filters={"primaryReleaseDateGte": "$monthsAgo:6", "primaryReleaseDateLte": "$today"})),
        ("month", "Fresh This Month", q("discoverMovies", "movie", filters={"primaryReleaseDateGte": "$monthsAgo:1", "primaryReleaseDateLte": "$today"})),
        ("current", "Current Releases", q("discoverMovies", "movie", filters={"primaryReleaseDateGte": "$monthsAgo:2", "primaryReleaseDateLte": "$monthsFromNow:1"})),
        ("coming", "Coming Soon", q("upcomingMovies", "movie")),
        ("anticipated", "Highly Anticipated", q("discoverMovies", "movie", filters={"primaryReleaseDateGte": "$today", "primaryReleaseDateLte": "$yearsFromNow:2", "voteCountGte": "20"})),
        ("added", "Recently Added Movies", q("personalised", "movie", seed="recently-added")),
    ]
    rows += [lane(f"movies-{key}", title, query, "movie-anchor", priority="anchor", cooldown=0) for key, title, query in anchors]

    discovery = [
        ("Hidden Gems", {"voteAverageGte": "7.0", "voteCountGte": "150", "voteCountLte": "1500"}),
        ("Deep Cuts", {"voteAverageGte": "6.8", "voteCountGte": "50", "voteCountLte": "500"}),
        ("Underseen Masterpieces", {"voteAverageGte": "7.8", "voteCountGte": "100", "voteCountLte": "1000"}),
        ("Crowd-Pleasing Picks", {"voteAverageGte": "6.8", "voteCountGte": "10000"}),
        ("Critics' Corner", {"voteAverageGte": "8.0", "voteCountGte": "1000"}),
        ("Great but Not Obvious", {"voteAverageGte": "7.2", "voteCountGte": "500", "voteCountLte": "3000"}),
        ("Polarising Movies", {"voteCountGte": "500"}),
        ("Modern Classics", {"primaryReleaseDateGte": "2000-01-01", "voteAverageGte": "7.5", "voteCountGte": "3000"}),
        ("Cult Favourites", {"voteCountGte": "100"}),
        ("One to Watch", {"primaryReleaseDateGte": "$yearsAgo:2", "voteAverageGte": "7.0", "voteCountGte": "100", "voteCountLte": "3000"}),
    ]
    for title, filters in discovery:
        keywords = ("cult film",) if title == "Cult Favourites" else ()
        rows.append(lane(f"movies-discovery-{slug(title)}", title, q("discoverMovies", "movie", sort="vote_average.desc", filters=filters, keywords=keywords), "movie-discovery"))

    runtimes = [
        ("Under 90 Minutes", {"withRuntimeLte": "90", "voteAverageGte": "6.0"}),
        ("Short and Brilliant", {"withRuntimeLte": "105", "voteAverageGte": "6.8", "voteCountGte": "150"}),
        ("Easy Two-Hour Watch", {"withRuntimeGte": "90", "withRuntimeLte": "125"}),
        ("Long but Worth It", {"withRuntimeGte": "125", "withRuntimeLte": "160", "voteAverageGte": "7.0"}),
        ("Epic Movie Night", {"withRuntimeGte": "150", "voteAverageGte": "7.0", "voteCountGte": "500"}),
        ("Three-Hour Epics", {"withRuntimeGte": "175", "voteAverageGte": "7.0"}),
        ("Quick Comedy", {"genre": "35", "withRuntimeLte": "100"}),
        ("Quick Thriller", {"genre": "53", "withRuntimeLte": "105"}),
    ]
    rows += [lane(f"movies-runtime-{slug(title)}", title, q("discoverMovies", "movie", filters=filters), "movie-runtime") for title, filters in runtimes]

    eras = [
        ("2020s Standouts", "2020-01-01", "$today"), ("Best of the 2010s", "2010-01-01", "2019-12-31"),
        ("Best of the 2000s", "2000-01-01", "2009-12-31"), ("'90s Essentials", "1990-01-01", "1999-12-31"),
        ("'80s Favourites", "1980-01-01", "1989-12-31"), ("'70s Cinema", "1970-01-01", "1979-12-31"),
        ("Mid-Century Classics", "1940-01-01", "1969-12-31"), ("Early Cinema", "1900-01-01", "1939-12-31"),
    ]
    for title, start, end in eras:
        rows.append(lane(f"movies-era-{slug(title)}", title, q("discoverMovies", "movie", sort="vote_average.desc", filters={"primaryReleaseDateGte": start, "primaryReleaseDateLte": end, "voteAverageGte": "6.8", "voteCountGte": "50"}), "movie-era"))

    rows += [lane(f"movies-genre-{slug(title)}", title, q("discoverMovies", "movie", filters={"genre": genre_id, "voteCountGte": "50"}), "movie-genres") for title, genre_id in MOVIE_GENRES.items()]

    combos = [
        ("Action Comedy", "28,35"), ("Action Thriller", "28,53"), ("Action Adventure", "28,12"),
        ("Sci-Fi Thriller", "878,53"), ("Sci-Fi Adventure", "878,12"), ("Sci-Fi Horror", "878,27"),
        ("Horror Comedy", "27,35"), ("Psychological Mystery", "9648,53"), ("Crime Thriller", "80,53"),
        ("Crime Drama", "80,18"), ("Romantic Comedy", "10749,35"), ("Romantic Drama", "10749,18"),
        ("Fantasy Adventure", "14,12"), ("Family Animation", "10751,16"), ("Historical Drama", "36,18"), ("War Drama", "10752,18"),
    ]
    for title, ids in combos:
        rows.append(lane(f"movies-mix-{slug(title)}", title, q("discoverMovies", "movie", filters={"genre": ids, "voteCountGte": "30"}, keywords=("psychological",) if title == "Psychological Mystery" else ()), "movie-mixes"))

    themes = [
        "Space & Deep Space", "Time Travel", "Superheroes", "Post-Apocalyptic", "Dystopian Futures", "Cyberpunk",
        "Artificial Intelligence", "Robots & Androids", "Aliens & First Contact", "Heist Movies", "Serial Killers",
        "Survival Stories", "Based on a True Story", "Coming of Age", "Road Movies", "Martial Arts",
    ]
    add_keywords(rows, "movies-theme", themes, source="discoverMovies", media_type="movie", pool="movie-themes", base_filters={"voteCountGte": "25"})

    rows += [lane(f"movies-studio-{slug(title)}", title, q("discoverMovies", "movie", filters={"studio": studio_id}), "movie-studios") for title, studio_id in MOVIE_STUDIOS.items()]
    rows += [lane(f"movies-language-{code}", f"{title} Cinema", q("discoverMovies", "movie", sort="vote_average.desc", filters={"language": code, "voteAverageGte": "6.5", "voteCountGte": "30"}), "movie-languages") for title, code in LANGUAGES]
    rows += [lane(f"movies-provider-{slug(provider)}", f"{provider} Movies", q("discoverMovies", "movie", filters={"watchRegion": "AU"}, providers=(provider,)), "movie-providers") for provider in AU_PROVIDERS]

    occasions = [
        ("Friday Night Popcorn", {"genre": "28|35|12"}), ("Family Weekend", {"genre": "10751|16|12", "withRuntimeLte": "130"}),
        ("Date Night", {"genre": "10749|35|18"}), ("Late-Night Thrillers", {"genre": "53|9648|80"}),
        ("Horror Night", {"genre": "27", "voteAverageGte": "6.0"}), ("Halloween Rotation", {"genre": "27"}),
        ("Christmas Movies", {}), ("Summer Blockbusters", {"genre": "28|12|878", "voteCountGte": "1000"}),
        ("Rainy-Day Comfort Movies", {"genre": "35|10751|10749"}), ("Documentary Night", {"genre": "99", "voteAverageGte": "7.0"}),
        ("Awards Season", {"voteAverageGte": "7.0", "voteCountGte": "500"}), ("Festival & Indie Spotlight", {"voteAverageGte": "7.0", "voteCountGte": "50", "voteCountLte": "2500"}),
    ]
    occasion_keywords = {"Halloween Rotation": ("halloween",), "Christmas Movies": ("christmas",), "Awards Season": ("academy award",), "Festival & Indie Spotlight": ("independent film",)}
    for title, filters in occasions:
        rows.append(lane(f"movies-occasion-{slug(title)}", title, q("discoverMovies", "movie", filters=filters, keywords=occasion_keywords.get(title, ())), "movie-occasions"))

    assert len(rows) == 130, f"Movie lane count {len(rows)} != 130"
    return rows


def series() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    anchors = [
        ("Trending Series", q("trending", "tv")), ("Popular Series", q("discoverTv", "tv")),
        ("Acclaimed Series", q("discoverTv", "tv", sort="vote_average.desc", filters={"voteAverageGte": "7.5", "voteCountGte": "500"})),
        ("New & Returning Series", q("discoverTv", "tv", filters={"firstAirDateGte": "$monthsAgo:12", "firstAirDateLte": "$monthsFromNow:3"})),
        ("Fresh Premieres", q("discoverTv", "tv", filters={"firstAirDateGte": "$monthsAgo:3", "firstAirDateLte": "$today"})),
        ("Upcoming Series", q("upcomingTv", "tv")),
        ("Binge-Worthy", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "18|80|35|10765", "voteAverageGte": "7.2", "voteCountGte": "200"})),
        ("Limited-Series Spotlight", q("personalised", "tv", seed="limited-series")),
        ("Recently Added Series", q("personalised", "tv", seed="recently-added")),
        ("Continue Exploring Series", q("personalised", "tv", seed="recent-discovery-context")),
    ]
    rows += [lane(f"series-anchor-{slug(title)}", title, query, "series-anchor", priority="anchor", cooldown=0) for title, query in anchors]

    discovery = [
        ("Hidden Series Gems", {"voteAverageGte": "7.5", "voteCountGte": "75", "voteCountLte": "1000"}),
        ("Underseen Greats", {"voteAverageGte": "8.0", "voteCountGte": "50", "voteCountLte": "750"}),
        ("Crowd Favourites", {"voteAverageGte": "7.0", "voteCountGte": "5000"}),
        ("Critics' Picks", {"voteAverageGte": "8.0", "voteCountGte": "500"}),
        ("Great but Not Obvious", {"voteAverageGte": "7.3", "voteCountGte": "250", "voteCountLte": "2500"}),
        ("Modern TV Classics", {"firstAirDateGte": "2000-01-01", "voteAverageGte": "7.7", "voteCountGte": "1000"}),
        ("Recent Breakouts", {"firstAirDateGte": "$yearsAgo:2", "voteAverageGte": "7.2", "voteCountGte": "100"}),
        ("One-Season Wonders", {}), ("Long-Running Favourites", {}),
        ("Worth Catching Up On", {"firstAirDateLte": "$yearsAgo:2", "voteAverageGte": "7.5", "voteCountGte": "500"}),
    ]
    for title, filters in discovery:
        generated = title in {"One-Season Wonders", "Long-Running Favourites"}
        rows.append(lane(f"series-discovery-{slug(title)}", title, q("personalised" if generated else "discoverTv", "tv", sort="vote_average.desc", filters=filters, seed=slug(title) if generated else None), "series-discovery"))

    runtimes = [
        ("Half-Hour Comedy", {"genre": "35", "withRuntimeLte": "35"}), ("Short Episodes", {"withRuntimeLte": "30"}),
        ("Easy 45-Minute Watch", {"withRuntimeGte": "35", "withRuntimeLte": "50"}), ("Hour-Long Drama", {"genre": "18", "withRuntimeGte": "45", "withRuntimeLte": "70"}),
        ("Long-Form Drama", {"genre": "18", "withRuntimeGte": "60"}), ("Quick Crime Fix", {"genre": "80", "withRuntimeLte": "45"}),
        ("Quick Reality Watch", {"genre": "10764", "withRuntimeLte": "50"}), ("Weekend Binge", {}),
    ]
    for title, filters in runtimes:
        generated = title == "Weekend Binge"
        rows.append(lane(f"series-runtime-{slug(title)}", title, q("personalised" if generated else "discoverTv", "tv", filters=filters, seed="weekend-binge" if generated else None), "series-runtime"))

    eras = [
        ("2020s Standouts", "2020-01-01", "$today"), ("Best of the 2010s", "2010-01-01", "2019-12-31"),
        ("Best of the 2000s", "2000-01-01", "2009-12-31"), ("'90s TV Favourites", "1990-01-01", "1999-12-31"),
        ("'80s Television", "1980-01-01", "1989-12-31"), ("'70s Television", "1970-01-01", "1979-12-31"),
        ("Classic TV 1950s-1960s", "1950-01-01", "1969-12-31"), ("Vintage Television", "1900-01-01", "1949-12-31"),
    ]
    for title, start, end in eras:
        rows.append(lane(f"series-era-{slug(title)}", title, q("discoverTv", "tv", sort="vote_average.desc", filters={"firstAirDateGte": start, "firstAirDateLte": end, "voteAverageGte": "6.8", "voteCountGte": "30"}), "series-era"))

    rows += [lane(f"series-genre-{slug(title)}", title, q("discoverTv", "tv", filters={"genre": genre_id, "voteCountGte": "25"}), "series-genres", priority="low" if title in {"News", "Soap", "Talk"} else "normal") for title, genre_id in TV_GENRES.items()]

    combos = [
        ("Crime & Mystery", "80,9648"), ("Crime Drama", "80,18"), ("Mystery Drama", "9648,18"),
        ("Sci-Fi Drama", "10765,18"), ("Fantasy Drama", "10765,18"), ("Action Drama", "10759,18"),
        ("Action Comedy", "10759,35"), ("Comedy Drama", "35,18"), ("Family Comedy", "10751,35"),
        ("Political Drama", "10768,18"), ("War Drama", "10768,18"), ("Western Drama", "37,18"),
        ("Documentary Crime", "99,80"), ("Reality Competition", "10764"), ("Mystery Sci-Fi", "9648,10765"),
        ("Adventure Fantasy", "10759,10765"),
    ]
    for title, ids in combos:
        keywords = ("competition",) if title == "Reality Competition" else (("fantasy",) if title == "Fantasy Drama" else ())
        rows.append(lane(f"series-mix-{slug(title)}", title, q("discoverTv", "tv", filters={"genre": ids, "voteCountGte": "20"}, keywords=keywords), "series-mixes"))

    themes = [
        "Time Travel", "Space & Deep Space", "Dystopian Futures", "Post-Apocalyptic Series", "Artificial Intelligence",
        "Robots & Androids", "Superheroes", "Serial Killers", "Detectives & Investigations", "Legal Drama", "Medical Drama",
        "Workplace Comedy", "Coming of Age", "High School & Teen Drama", "Survival", "Based on True Events", "Espionage & Spies", "Supernatural Mysteries",
    ]
    add_keywords(rows, "series-theme", themes, source="discoverTv", media_type="tv", pool="series-themes", base_filters={"voteCountGte": "15"})
    rows += [lane(f"series-network-{slug(title)}", title, q("discoverTv", "tv", filters={"network": network_id}), "series-networks") for title, network_id in SERIES_NETWORKS.items()]
    rows += [lane(f"series-language-{code}", f"{title} Series", q("discoverTv", "tv", sort="vote_average.desc", filters={"language": code, "voteAverageGte": "6.5", "voteCountGte": "20"}), "series-languages") for title, code in LANGUAGES]
    rows += [lane(f"series-provider-{slug(provider)}", f"{provider} Series", q("discoverTv", "tv", filters={"watchRegion": "AU"}, providers=(provider,)), "series-providers") for provider in AU_PROVIDERS]

    occasions = [
        ("Friday Night Binge", {"genre": "18|80|35"}, ()), ("Easy Background Comedy", {"genre": "35", "withRuntimeLte": "35"}, ("workplace",)),
        ("Edge-of-Your-Seat", {"genre": "80|9648|10759"}, ()), ("Big Sci-Fi Night", {"genre": "10765", "voteAverageGte": "7.0"}, ()),
        ("Family Series Night", {"genre": "10751|35|10759"}, ()), ("Documentary Weekend", {"genre": "99", "voteAverageGte": "7.0"}, ()),
        ("Reality Competition Night", {"genre": "10764"}, ("competition",)), ("Prestige Drama", {"genre": "18", "voteAverageGte": "7.8", "voteCountGte": "500"}, ()),
        ("Comfort Rewatch Candidates", {}, ()), ("Dark & Twisty", {"genre": "9648|80|18"}, ("psychological",)),
        ("Light & Funny", {"genre": "35", "voteAverageGte": "6.8"}, ()), ("Something Completely Different", {}, ()),
    ]
    for title, filters, keywords in occasions:
        generated = title in {"Comfort Rewatch Candidates", "Something Completely Different"}
        rows.append(lane(f"series-occasion-{slug(title)}", title, q("personalised" if generated else "discoverTv", "tv", filters=filters, keywords=keywords, seed=slug(title) if generated else None), "series-occasions"))

    assert len(rows) == 140, f"Series lane count {len(rows)} != 140"
    return rows


ANIME_THEMES = [
    "Isekai", "Reincarnation", "Another World", "Magic", "Supernatural", "Demons", "Vampires", "Yokai",
    "Ghost Stories", "Mecha", "Giant Robots", "Cyberpunk", "Post-Apocalyptic", "Dystopian", "Space Opera",
    "Space Travel", "Aliens", "Time Travel", "Parallel Worlds", "Virtual Reality", "Video Games",
    "Artificial Intelligence", "School Life", "High School", "Coming of Age", "Slice of Life", "Romance",
    "Romantic Comedy", "Love Triangle", "Sports", "Martial Arts", "Samurai", "Ninja", "Sword Fighting",
    "Tournament", "Superpowers", "Superheroes", "Mystery & Detective", "Psychological", "Thriller", "Survival",
    "Death Game", "Cooking & Food", "Music & Bands", "Idols", "Workplace", "Family", "Friendship",
    "Based on Manga", "Based on Light Novel",
]


def anime_filter(extra: dict[str, str] | None = None) -> dict[str, str]:
    out = {"genre": "16", "language": "ja"}
    if extra:
        out.update(extra)
    return out


def anime() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    anchors = [
        ("Popular Anime", q("discoverTv", "tv", filters=anime_filter())),
        ("Top Rated Anime", q("discoverTv", "tv", sort="vote_average.desc", filters=anime_filter({"voteCountGte": "100"}))),
        ("Trending Anime", q("personalised", "tv", seed="trending-anime")),
        ("New This Season", q("discoverTv", "tv", filters=anime_filter({"firstAirDateGte": "$monthsAgo:3", "firstAirDateLte": "$monthsFromNow:1"}))),
        ("Fresh This Month", q("discoverTv", "tv", filters=anime_filter({"firstAirDateGte": "$monthsAgo:1", "firstAirDateLte": "$today"}))),
        ("Recent Seasonal Hits", q("discoverTv", "tv", sort="vote_average.desc", filters=anime_filter({"firstAirDateGte": "$monthsAgo:6", "voteCountGte": "30"}))),
        ("Upcoming Anime", q("discoverTv", "tv", filters=anime_filter({"firstAirDateGte": "$today", "firstAirDateLte": "$yearsFromNow:2"}))),
        ("Fresh Discoveries", q("discoverTv", "tv", sort="vote_average.desc", filters=anime_filter({"voteCountGte": "20", "voteCountLte": "500"}))),
        ("Hidden Anime Gems", q("discoverTv", "tv", sort="vote_average.desc", filters=anime_filter({"voteAverageGte": "7.2", "voteCountGte": "50", "voteCountLte": "800"}))),
        ("Anime Movies", q("discoverMovies", "movie", filters={"genre": "16", "language": "ja"})),
        ("Anime Classics", q("discoverTv", "tv", sort="vote_average.desc", filters=anime_filter({"firstAirDateLte": "1999-12-31", "voteCountGte": "30"}))),
        ("Highly Rated and Unseen Anime", q("personalised", "tv", seed="anime-highly-rated-unseen")),
    ]
    rows += [lane(f"anime-anchor-{slug(title)}", title, query, "anime-anchor", priority="anchor", cooldown=0, tags=("anime",)) for title, query in anchors]

    time_lanes = [
        ("Current Season Anime", "$monthsAgo:3", "$monthsFromNow:1", False),
        ("Previous Season Highlights", "$monthsAgo:6", "$monthsAgo:3", False),
        ("Last 6 Months", "$monthsAgo:6", "$today", False), ("Last 12 Months", "$monthsAgo:12", "$today", False),
        ("New Anime Movies", "$monthsAgo:12", "$today", True), ("Upcoming Anime Movies", "$today", "$yearsFromNow:2", True),
        ("2020s Anime Standouts", "2020-01-01", "$today", False), ("Best of the 2010s", "2010-01-01", "2019-12-31", False),
        ("Best of the 2000s", "2000-01-01", "2009-12-31", False), ("'90s Anime", "1990-01-01", "1999-12-31", False),
        ("'80s Anime", "1980-01-01", "1989-12-31", False), ("'70s Anime", "1970-01-01", "1979-12-31", False),
        ("Classic Anime Before 1970", "1900-01-01", "1969-12-31", False), ("Recent Hidden Gems", "$yearsAgo:3", "$today", False),
        ("New & Highly Rated", "$yearsAgo:2", "$today", False), ("Recent Long-Running Hits", "$yearsAgo:5", "$today", False),
    ]
    for title, start, end, movie in time_lanes:
        source, media = ("discoverMovies", "movie") if movie else ("discoverTv", "tv")
        gte, lte = ("primaryReleaseDateGte", "primaryReleaseDateLte") if movie else ("firstAirDateGte", "firstAirDateLte")
        rows.append(lane(f"anime-time-{slug(title)}", title, q(source, media, sort="vote_average.desc", filters={"genre": "16", "language": "ja", gte: start, lte: end, "voteCountGte": "15"}), "anime-time", tags=("anime",)))

    ratings = [
        ("Acclaimed Anime", {"voteAverageGte": "8.0", "voteCountGte": "200"}),
        ("Fan Favourites", {"voteAverageGte": "7.5", "voteCountGte": "1000"}),
        ("Underseen Greats", {"voteAverageGte": "7.7", "voteCountGte": "50", "voteCountLte": "500"}),
        ("Deep-Cut Anime", {"voteAverageGte": "7.0", "voteCountGte": "20", "voteCountLte": "250"}),
        ("Modern Anime Classics", {"firstAirDateGte": "2000-01-01", "voteAverageGte": "8.0", "voteCountGte": "500"}),
        ("Recent Breakouts", {"firstAirDateGte": "$yearsAgo:2", "voteAverageGte": "7.5", "voteCountGte": "75"}),
        ("One to Watch", {"firstAirDateGte": "$yearsAgo:2", "voteAverageGte": "7.3", "voteCountGte": "30", "voteCountLte": "600"}),
        ("Popular but Not in Your Library", {}), ("Top Rated Anime Movies", {}), ("Hidden Anime Movies", {}),
        ("Acclaimed Older Anime", {"firstAirDateLte": "2009-12-31", "voteAverageGte": "7.8", "voteCountGte": "50"}),
        ("Something Different", {}),
    ]
    for title, filters in ratings:
        if title in {"Popular but Not in Your Library", "Something Different"}:
            query = q("personalised", "tv", seed=f"anime-{slug(title)}")
        elif "Anime Movies" in title:
            movie_filters = {"genre": "16", "language": "ja", "voteAverageGte": "7.0", "voteCountGte": "20"}
            if title.startswith("Hidden"):
                movie_filters["voteCountLte"] = "800"
            query = q("discoverMovies", "movie", sort="vote_average.desc", filters=movie_filters)
        else:
            query = q("discoverTv", "tv", sort="vote_average.desc", filters=anime_filter(filters))
        rows.append(lane(f"anime-rating-{slug(title)}", title, query, "anime-rating", tags=("anime",)))

    direct = [
        ("Action-Packed Anime", "10759"), ("Adventure Anime", "10759"), ("Comedy Anime", "35"), ("Drama Anime", "18"),
        ("Mystery Anime", "9648"), ("Sci-Fi Anime", "10765"), ("Fantasy Anime", "10765"), ("Family-Friendly Anime", "10751"),
        ("Kids Anime", "10762"), ("War & Politics Anime", "10768"), ("Action Comedy Anime", "10759,35"),
        ("Action Drama Anime", "10759,18"), ("Mystery Drama Anime", "9648,18"), ("Sci-Fi Action Anime", "10765,10759"),
        ("Fantasy Adventure Anime", "10765,10759"), ("Comedy Drama Anime", "35,18"), ("Dark Mystery Anime", "9648,18"),
        ("Family Adventure Anime", "10751,10759"), ("Historical Anime", "18"), ("Music Anime", "18"),
    ]
    keyword_refinement = {
        "Adventure Anime": ("adventure",), "Sci-Fi Anime": ("science fiction",), "Fantasy Anime": ("fantasy",),
        "Sci-Fi Action Anime": ("science fiction",), "Fantasy Adventure Anime": ("fantasy",),
        "Dark Mystery Anime": ("supernatural",), "Historical Anime": ("historical",), "Music Anime": ("music",),
    }
    for title, extra_genres in direct:
        rows.append(lane(f"anime-genre-{slug(title)}", title, q("discoverTv", "tv", filters={"genre": f"16,{extra_genres}", "language": "ja", "voteCountGte": "10"}, keywords=keyword_refinement.get(title, ())), "anime-genres", tags=("anime",)))

    assert len(ANIME_THEMES) == 50
    add_keywords(rows, "anime-theme", ANIME_THEMES, source="discoverTv", media_type="tv", pool="anime-themes", base_filters={"genre": "16", "language": "ja", "voteCountGte": "5"}, tags=("anime", "theme"))

    formats = [
        ("Short-Form Anime", q("discoverTv", "tv", filters=anime_filter({"withRuntimeLte": "15"}))),
        ("Standard Episodes", q("discoverTv", "tv", filters=anime_filter({"withRuntimeGte": "20", "withRuntimeLte": "30"}))),
        ("Longer Episodes", q("discoverTv", "tv", filters=anime_filter({"withRuntimeGte": "35"}))),
        ("Quick Anime Movie", q("discoverMovies", "movie", filters={"genre": "16", "language": "ja", "withRuntimeLte": "100"})),
        ("Epic Anime Movie", q("discoverMovies", "movie", filters={"genre": "16", "language": "ja", "withRuntimeGte": "120", "voteAverageGte": "7.0"})),
        ("Anime Specials & TV Movies", q("personalised", "all", seed="anime-specials")),
        ("One-Season Anime", q("personalised", "tv", seed="anime-one-season")), ("Long-Running Anime", q("personalised", "tv", seed="anime-long-running")),
        ("Bingeable Anime", q("personalised", "tv", seed="anime-bingeable")), ("Completed Anime", q("personalised", "tv", seed="anime-completed")),
        ("Continuing Anime", q("personalised", "tv", seed="anime-continuing")), ("Anime Miniseries & Short Runs", q("personalised", "tv", seed="anime-short-runs")),
    ]
    rows += [lane(f"anime-format-{slug(title)}", title, query, "anime-format", tags=("anime",)) for title, query in formats]

    studios = ["Studio Ghibli Films", "Kyoto Animation Spotlight", "MAPPA Spotlight", "ufotable Spotlight", "Bones Spotlight", "Madhouse Spotlight", "Production I.G Spotlight", "Trigger Spotlight", "Wit Studio Spotlight", "Sunrise Spotlight"]
    rows += [lane(f"anime-studio-{slug(title)}", title, q("externalList", "all", list_id=f"anime-studio-{slug(title)}"), "anime-studios", min_items=5, tags=("anime", "curated")) for title in studios]

    rows += [
        lane("anime-global-donghua", "Donghua & Chinese Animation", q("discoverTv", "tv", filters={"genre": "16", "language": "zh"}), "anime-global", priority="low"),
        lane("anime-global-korean", "Korean Animation", q("discoverTv", "tv", filters={"genre": "16", "language": "ko"}), "anime-global", priority="low"),
        lane("anime-global-influenced", "International Anime-Influenced Animation", q("externalList", "all", list_id="anime-international-influenced"), "anime-global", priority="low", min_items=5),
    ]

    personal = [
        ("Because You Watched Anime", "anime-recent-history"), ("More Like Your Favourite Anime", "anime-favourites"),
        ("Inspired by Your Anime Watchlist", "anime-watchlist"), ("More Action Anime for You", "anime-action-affinity"),
        ("More Fantasy Anime for You", "anime-fantasy-affinity"), ("More Romance & Drama Anime for You", "anime-romance-drama-affinity"),
        ("Anime Outside Your Usual Genres", "anime-novelty"), ("Highly Rated Anime You Missed", "anime-highly-rated-unseen"),
        ("Similar to Anime You Rated Highly", "anime-high-ratings"), ("Recent Anime Based on Your Taste", "anime-recent-affinity"),
        ("Older Anime Based on Your Taste", "anime-older-affinity"), ("Anime Movies Based on Your Taste", "anime-movie-affinity"),
        ("Short Anime Based on Your Taste", "anime-short-affinity"),
    ]
    rows += [lane(f"anime-personal-{slug(title)}", title, q("personalised", "all", seed=seed), "anime-personal", priority="high" if "Favourite" in title or "Watchlist" in title else "normal", cooldown=0, tags=("anime", "personal")) for title, seed in personal]

    curated = ["Seasonal Staff Picks", "Essential Anime Starter Pack", "Modern Anime Essentials", "Classic Anime Essentials", "Best Anime Movies", "Best Sports Anime", "Best Mecha Anime", "Best Romance Anime", "Best Psychological Anime", "Best Sci-Fi Anime", "Best Fantasy Anime", "Best Comedy Anime"]
    rows += [lane(f"anime-list-{slug(title)}", title, q("externalList", "all", list_id=f"anime-{slug(title)}"), "anime-lists", min_items=5, tags=("anime", "curated")) for title in curated]

    assert len(rows) == 160, f"Anime lane count {len(rows)} != 160"
    return rows


def for_you() -> list[dict[str, Any]]:
    definitions = [
        ("Because You Watched", "recent-history"), ("More Like Your Favourites", "favourites"),
        ("Inspired by Your Watchlist", "watchlist"), ("Based on Your Highest Ratings", "high-ratings"),
        ("More From Things You Like", "likes"), ("Picked From Your Taste", "mixed-positive"),
        ("Highly Rated and Unseen", "highly-rated-unseen"), ("Something Different", "novelty"),
        ("Movies for You", "movie-affinity"), ("Series for You", "series-affinity"), ("Anime for You", "anime-affinity"),
        ("Short Picks for You", "short-runtime-affinity"), ("Older Gems for You", "older-affinity"),
        ("Recent Releases for You", "recent-affinity"), ("Worth Rewatching", "rewatch"), ("Continue Exploring", "recent-discovery-context"),
    ]
    return [lane(f"for-you-{slug(title)}", title, q("personalised", "all", seed=seed), "personal", priority="high" if seed in {"recent-history", "favourites", "watchlist"} else "normal", cooldown=0, tags=("personal",)) for title, seed in definitions]


def new_upcoming() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    windows = [
        ("Movies Arriving Soon", "discoverMovies", "movie", "primaryReleaseDateGte", "$today", "primaryReleaseDateLte", "$monthsFromNow:1", {}),
        ("Movies Coming This Quarter", "discoverMovies", "movie", "primaryReleaseDateGte", "$today", "primaryReleaseDateLte", "$monthsFromNow:3", {}),
        ("Movies on the Horizon", "discoverMovies", "movie", "primaryReleaseDateGte", "$today", "primaryReleaseDateLte", "$yearsFromNow:1", {}),
        ("Series Premiering Soon", "discoverTv", "tv", "firstAirDateGte", "$today", "firstAirDateLte", "$monthsFromNow:1", {}),
        ("Series Coming This Quarter", "discoverTv", "tv", "firstAirDateGte", "$today", "firstAirDateLte", "$monthsFromNow:3", {}),
        ("Series on the Horizon", "discoverTv", "tv", "firstAirDateGte", "$today", "firstAirDateLte", "$yearsFromNow:1", {}),
        ("Anime Arriving Soon", "discoverTv", "tv", "firstAirDateGte", "$today", "firstAirDateLte", "$monthsFromNow:1", {"genre": "16", "language": "ja"}),
        ("Next Anime Season", "discoverTv", "tv", "firstAirDateGte", "$today", "firstAirDateLte", "$monthsFromNow:4", {"genre": "16", "language": "ja"}),
    ]
    for title, source, media, gte_key, gte, lte_key, lte, extra in windows:
        filters = dict(extra); filters.update({gte_key: gte, lte_key: lte})
        rows.append(lane(f"new-{slug(title)}", title, q(source, media, filters=filters), "new-upcoming", priority="high"))

    extras = [
        ("Movies Released Last Month", "discoverMovies", "movie", {"primaryReleaseDateGte": "$monthsAgo:1", "primaryReleaseDateLte": "$today"}),
        ("Recent Movie Releases", "discoverMovies", "movie", {"primaryReleaseDateGte": "$monthsAgo:6", "primaryReleaseDateLte": "$today"}),
        ("Series Premiered This Month", "discoverTv", "tv", {"firstAirDateGte": "$monthsAgo:1", "firstAirDateLte": "$today"}),
        ("Recent Series Premieres", "discoverTv", "tv", {"firstAirDateGte": "$monthsAgo:6", "firstAirDateLte": "$today"}),
        ("Fresh Anime This Month", "discoverTv", "tv", {"genre": "16", "language": "ja", "firstAirDateGte": "$monthsAgo:1", "firstAirDateLte": "$today"}),
        ("Recent Anime Releases", "discoverTv", "tv", {"genre": "16", "language": "ja", "firstAirDateGte": "$monthsAgo:6", "firstAirDateLte": "$today"}),
        ("Most Anticipated Movies", "discoverMovies", "movie", {"primaryReleaseDateGte": "$today", "voteCountGte": "20"}),
        ("Most Anticipated Series", "discoverTv", "tv", {"firstAirDateGte": "$today", "voteCountGte": "20"}),
        ("Most Anticipated Anime", "discoverTv", "tv", {"genre": "16", "language": "ja", "firstAirDateGte": "$today", "voteCountGte": "10"}),
        ("New Acclaimed Movies", "discoverMovies", "movie", {"primaryReleaseDateGte": "$yearsAgo:1", "voteAverageGte": "7.3", "voteCountGte": "100"}),
        ("New Acclaimed Series", "discoverTv", "tv", {"firstAirDateGte": "$yearsAgo:1", "voteAverageGte": "7.5", "voteCountGte": "75"}),
        ("New Acclaimed Anime", "discoverTv", "tv", {"genre": "16", "language": "ja", "firstAirDateGte": "$yearsAgo:1", "voteAverageGte": "7.5", "voteCountGte": "30"}),
    ]
    rows += [lane(f"new-{slug(title)}", title, q(source, media, sort="vote_average.desc" if "Acclaimed" in title else "popularity.desc", filters=filters), "new-upcoming") for title, source, media, filters in extras]
    assert len(rows) == 20
    return rows


def curated_lists() -> list[dict[str, Any]]:
    # These are intentionally executable smart collections rather than opaque
    # external-list placeholders. Real configured MDBList/TMDb/Letterboxd rows
    # are appended client-side without replacing this baseline.
    definitions = [
        ("Award Season Favourites", q("discoverMovies", "movie", sort="vote_average.desc", filters={"voteAverageGte": "7.2", "voteCountGte": "1000"}, keywords=("academy award",))),
        ("Modern Movie Classics", q("discoverMovies", "movie", sort="vote_average.desc", filters={"primaryReleaseDateGte": "2000-01-01", "voteAverageGte": "7.5", "voteCountGte": "3000"})),
        ("Essential Sci-Fi", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "878", "voteAverageGte": "7.0", "voteCountGte": "500"})),
        ("Essential Horror", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "27", "voteAverageGte": "6.5", "voteCountGte": "300"})),
        ("Essential Crime & Thriller", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "80|53", "voteAverageGte": "7.0", "voteCountGte": "500"})),
        ("Great Films Under Two Hours", q("discoverMovies", "movie", sort="vote_average.desc", filters={"withRuntimeLte": "120", "voteAverageGte": "7.2", "voteCountGte": "500"})),
        ("Family Favourites", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "10751|16", "voteAverageGte": "6.8", "voteCountGte": "300"})),
        ("A24 Essentials", q("discoverMovies", "movie", sort="vote_average.desc", filters={"studio": "41077", "voteAverageGte": "6.5", "voteCountGte": "100"})),
        ("Animated Film Essentials", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "16", "voteAverageGte": "7.0", "voteCountGte": "300"})),
        ("Korean Cinema Essentials", q("discoverMovies", "movie", sort="vote_average.desc", filters={"language": "ko", "voteAverageGte": "7.0", "voteCountGte": "100"})),
        ("Prestige TV Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "18", "voteAverageGte": "8.0", "voteCountGte": "500"})),
        ("Crime Series Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "80", "voteAverageGte": "7.5", "voteCountGte": "250"})),
        ("Sci-Fi & Fantasy Series Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "10765", "voteAverageGte": "7.5", "voteCountGte": "250"})),
        ("Comedy Series Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "35", "voteAverageGte": "7.5", "voteCountGte": "250"})),
        ("Documentary Series Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "99", "voteAverageGte": "7.5", "voteCountGte": "50"})),
        ("Korean Series Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"language": "ko", "voteAverageGte": "7.5", "voteCountGte": "100"})),
        ("Anime Starter Pack", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "16", "language": "ja", "voteAverageGte": "7.5", "voteCountGte": "200"})),
        ("Modern Anime Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "16", "language": "ja", "firstAirDateGte": "2010-01-01", "voteAverageGte": "8.0", "voteCountGte": "150"})),
        ("Classic Anime Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "16", "language": "ja", "firstAirDateLte": "2009-12-31", "voteAverageGte": "7.8", "voteCountGte": "75"})),
        ("Best Anime Movies", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "16", "language": "ja", "voteAverageGte": "7.5", "voteCountGte": "50"})),
    ]
    return [
        lane(
            f"lists-{slug(title)}",
            title,
            query,
            "smart-collections",
            min_items=5,
            tags=("curated", "smart-collection"),
        )
        for title, query in definitions
    ]


def tab(tab_id: str, title: str, sections: list[dict[str, Any]], budget: int, minimum: int, pool_budgets: dict[str, int]) -> dict[str, Any]:
    return {"id": tab_id, "title": title, "sections": sections, "initialLaneBudget": budget, "minimumLaneCount": minimum, "poolBudgets": pool_budgets}


def build() -> dict[str, Any]:
    tabs = [
        tab("for-you", "For You", for_you(), 16, 10, {"personal": 16}),
        tab("movies", "Movies", movies(), 24, 18, {"movie-anchor": 10, "movie-discovery": 4, "movie-runtime": 2, "movie-era": 2, "movie-genres": 4, "movie-mixes": 3, "movie-themes": 3, "movie-studios": 2, "movie-languages": 2, "movie-providers": 2, "movie-occasions": 2}),
        tab("series", "Series", series(), 24, 18, {"series-anchor": 10, "series-discovery": 4, "series-runtime": 2, "series-era": 2, "series-genres": 4, "series-mixes": 3, "series-themes": 3, "series-networks": 3, "series-languages": 2, "series-providers": 2, "series-occasions": 2}),
        tab("anime", "Anime", anime(), 26, 20, {"anime-anchor": 12, "anime-time": 3, "anime-rating": 3, "anime-genres": 4, "anime-themes": 6, "anime-format": 2, "anime-studios": 2, "anime-global": 1, "anime-personal": 4, "anime-lists": 3}),
        tab("new-upcoming", "New & Upcoming", new_upcoming(), 16, 10, {"new-upcoming": 16}),
        tab("lists", "Lists", curated_lists(), 16, 8, {"smart-collections": 12, "configured-lists": 6}),
    ]
    result = {"schemaVersion": SCHEMA_VERSION, "catalogueVersion": "home-lab-v2-authoring", "defaultRegion": "AU", "tabs": tabs}
    validate(result)
    return result


def validate(catalogue: dict[str, Any]) -> None:
    expected = {"for-you": 16, "movies": 130, "series": 140, "anime": 160, "new-upcoming": 20, "lists": 20}
    counts: dict[str, int] = {}
    tab_ids: set[str] = set()
    section_ids: set[str] = set()
    for tab_data in catalogue["tabs"]:
        tab_id = tab_data["id"]
        if tab_id in tab_ids:
            raise ValueError(f"duplicate tab {tab_id}")
        tab_ids.add(tab_id)
        counts[tab_id] = len(tab_data["sections"])
        if not 1 <= tab_data["minimumLaneCount"] <= tab_data["initialLaneBudget"]:
            raise ValueError(f"invalid lane budget in {tab_id}")
        for section in tab_data["sections"]:
            if section["id"] in section_ids:
                raise ValueError(f"duplicate section {section['id']}")
            section_ids.add(section["id"])
            if not 1 <= section["minItems"] <= section["previewLimit"] <= 100:
                raise ValueError(f"invalid item limits in {section['id']}")
            if section["weight"] <= 0 or section["cooldownSessions"] < 0:
                raise ValueError(f"invalid composition metadata in {section['id']}")
    if counts != expected:
        raise ValueError(f"lane-count regression: expected {expected}, got {counts}")
    if sum(counts.values()) != 486:
        raise ValueError(f"expected 486 total lanes, got {sum(counts.values())}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    parser.add_argument("--compact", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    catalogue = build()
    counts = {tab_data["id"]: len(tab_data["sections"]) for tab_data in catalogue["tabs"]}
    if args.check:
        print(json.dumps({"schemaVersion": SCHEMA_VERSION, "total": sum(counts.values()), "tabs": counts}, indent=2))
        return 0
    text = json.dumps(catalogue, ensure_ascii=False, indent=None if args.compact else 2, separators=(",", ":") if args.compact else None) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
