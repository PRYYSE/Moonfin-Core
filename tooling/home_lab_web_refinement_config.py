#!/usr/bin/env python3
"""Home Lab Web refinement config layered over the validated v1 helper."""

import json
import re

import home_lab_v2_moonbase as base

EXPLICIT = [
    r'\bhentai\b', r'\bporn(?:ographic|ography)?\b', r'\bxxx\b',
    r'sexually explicit', r'adult animation', r'\beroge\b',
    r'\bfutanari\b', r'tentacle sex',
]
EXPLICIT_RE = [re.compile(value, re.I) for value in EXPLICIT]

EDITORIAL_ROWS = (
    ('homelab_movies_popular', 'Popular Movies', 'movie/popular', ('movies',), True),
    ('homelab_movies_top_rated', 'Top Rated Movies', 'movie/top_rated', ('movies',), False),
    ('homelab_movies_now_playing', 'In Cinemas', 'movie/now_playing', ('movies',), False),
    ('homelab_movies_upcoming', 'Coming Soon', 'movie/upcoming', ('movies',), False),
    (
        'homelab_movies_hidden_gems',
        'Hidden Gems',
        'discover/movie?sort_by=vote_average.desc&vote_average.gte=7'
        '&vote_count.gte=250&include_adult=false',
        ('movies',),
        False,
    ),
    (
        'homelab_movies_short_brilliant',
        'Short and Brilliant',
        'discover/movie?sort_by=vote_average.desc&vote_average.gte=6.8'
        '&vote_count.gte=150&with_runtime.lte=105&include_adult=false',
        ('movies',),
        False,
    ),
    (
        'homelab_movies_modern_classics',
        'Modern Classics',
        'discover/movie?sort_by=vote_average.desc&vote_count.gte=1200'
        '&primary_release_date.gte=1990-01-01'
        '&primary_release_date.lte=2015-12-31&include_adult=false',
        ('movies',),
        False,
    ),
    (
        'homelab_movies_family_night',
        'Family Movie Night',
        'discover/movie?with_genres=10751&sort_by=popularity.desc'
        '&include_adult=false',
        ('movies',),
        False,
    ),
    (
        'homelab_movies_documentaries',
        'Documentary Spotlight',
        'discover/movie?with_genres=99&sort_by=popularity.desc'
        '&vote_count.gte=30&include_adult=false',
        ('movies',),
        False,
    ),
    (
        'homelab_tv_popular',
        'Popular Series',
        'discover/tv?sort_by=popularity.desc&without_genres=16',
        ('tv',),
        True,
    ),
    (
        'homelab_tv_top_rated',
        'Top Rated Series',
        'discover/tv?sort_by=vote_average.desc&vote_count.gte=250'
        '&without_genres=16',
        ('tv',),
        False,
    ),
    (
        'homelab_tv_more_discovery',
        'More Series to Discover',
        'discover/tv?sort_by=popularity.desc&without_genres=16&page=2',
        ('tv',),
        False,
    ),
    (
        'homelab_tv_on_air',
        'New and Returning Series',
        'discover/tv?sort_by=first_air_date.desc&vote_count.gte=5'
        '&without_genres=16',
        ('tv',),
        False,
    ),
    (
        'homelab_tv_limited_series',
        'Bingeable Limited Series',
        'discover/tv?with_type=2&sort_by=vote_average.desc'
        '&vote_count.gte=80&without_genres=16',
        ('tv',),
        False,
    ),
    (
        'homelab_tv_short_comedy',
        'Half-Hour Comedy',
        'discover/tv?with_genres=35&with_runtime.lte=38'
        '&sort_by=popularity.desc&without_genres=16',
        ('tv',),
        False,
    ),
    (
        'homelab_tv_crime_mystery',
        'Crime and Mystery',
        'discover/tv?with_genres=80|9648&sort_by=popularity.desc'
        '&without_genres=16',
        ('tv',),
        False,
    ),
    (
        'homelab_tv_reality',
        'Reality and Competition',
        'discover/tv?with_genres=10764&sort_by=popularity.desc'
        '&without_genres=16',
        ('tv',),
        False,
    ),
    (
        'homelab_tv_documentaries',
        'Docuseries',
        'discover/tv?with_genres=99&sort_by=popularity.desc'
        '&without_genres=16',
        ('tv',),
        False,
    ),
    (
        'homelab_tv_family',
        'Series for Everyone',
        'discover/tv?with_genres=10751&sort_by=popularity.desc'
        '&without_genres=16',
        ('tv',),
        False,
    ),
    (
        'homelab_anime_popular',
        'Popular Now',
        'discover/tv?with_genres=16&with_original_language=ja'
        '&sort_by=popularity.desc',
        ('anime',),
        True,
    ),
    (
        'homelab_anime_new',
        'New This Season',
        'discover/tv?with_genres=16&with_original_language=ja'
        '&sort_by=first_air_date.desc&vote_count.gte=5',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_airing',
        'Recent Seasonal Hits',
        'discover/tv?with_genres=16&with_original_language=ja'
        '&sort_by=popularity.desc&first_air_date.gte=2025-01-01',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_top_rated',
        'Top Rated Anime',
        'discover/tv?with_genres=16&with_original_language=ja'
        '&sort_by=vote_average.desc&vote_count.gte=100',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_fresh',
        'Fresh Discoveries',
        'discover/tv?with_genres=16&with_original_language=ja'
        '&sort_by=popularity.desc&page=2',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_hidden_gems',
        'Hidden Anime Gems',
        'discover/tv?with_genres=16&with_original_language=ja'
        '&sort_by=vote_average.desc&vote_average.gte=7&vote_count.gte=35'
        '&vote_count.lte=500',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_action',
        'Action-Packed',
        'discover/tv?with_genres=16,10759&with_original_language=ja'
        '&sort_by=popularity.desc',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_fantasy',
        'Fantasy Worlds',
        'discover/tv?with_genres=16,10765&with_original_language=ja'
        '&sort_by=popularity.desc',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_comedy',
        'Comedy Anime',
        'discover/tv?with_genres=16,35&with_original_language=ja'
        '&sort_by=popularity.desc',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_drama',
        'Drama and Romance',
        'discover/tv?with_genres=16,18&with_original_language=ja'
        '&sort_by=popularity.desc',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_mystery',
        'Mystery and Supernatural',
        'discover/tv?with_genres=16,9648&with_original_language=ja'
        '&sort_by=popularity.desc',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_family',
        'Family-Friendly Anime',
        'discover/tv?with_genres=16,10751&with_original_language=ja'
        '&sort_by=popularity.desc',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_movies',
        'Anime Movies',
        'discover/movie?with_genres=16&with_original_language=ja'
        '&sort_by=popularity.desc',
        ('anime',),
        False,
    ),
    (
        'homelab_anime_classics',
        'Anime Classics',
        'discover/tv?with_genres=16&with_original_language=ja'
        '&sort_by=vote_average.desc&first_air_date.lte=2005-12-31'
        '&vote_count.gte=50',
        ('anime',),
        False,
    ),
)


def editorial_custom_rows():
    rows = []
    for section_id, title, chart_type, destinations, show_on_home in EDITORIAL_ROWS:
        rows.append({
            'kind': 'pluginDynamic',
            'type': 'none',
            'enabled': show_on_home,
            'order': 0,
            'serverId': 'custom',
            'pluginSource': 'custom',
            'pluginSection': section_id,
            'pluginAdditionalData': json.dumps(
                {
                    'source': 'tmdb_chart',
                    'type': chart_type,
                    'params': {},
                    'sort_by': 'none',
                    'sort_order': 'desc',
                    'homelab_destinations': list(destinations),
                    'homelab_destination_only': not show_on_home,
                },
                separators=(',', ':'),
            ),
            'pluginDisplayText': title,
        })
    return rows


def desired_sections(existing):
    dynamics = [
        dict(section)
        for section in existing
        if str(section.get('kind', '')).lower() == 'plugindynamic'
    ]
    managed = {
        str(row.get('pluginSection') or '').strip().lower(): row
        for row in editorial_custom_rows()
    }
    reconciled = []
    seen_ids = set()
    for row in dynamics:
        identity = str(row.get('pluginSection') or '').strip().lower()
        if identity in managed:
            reconciled.append(dict(managed[identity]))
            seen_ids.add(identity)
        else:
            reconciled.append(row)
    for identity, row in managed.items():
        if identity not in seen_ids:
            reconciled.append(dict(row))

    result = []
    order = 0

    def add(name):
        nonlocal order
        result.append(base.builtin(name, order))
        order += 1

    for name in (
        'mediabar', 'resume', 'nextup', 'sinceyouwatched1',
        'sinceyouwatched2', 'sinceyouwatched3', 'rewatch',
        'seerr_watchlist',
    ):
        add(name)

    for row in sorted(reconciled, key=lambda value: int(value.get('order') or 0)):
        row['order'] = order
        result.append(row)
        order += 1

    for name in (
        'seerr_trending', 'recentlyreleased', 'seerr_recently_added',
        'collections', 'genres', 'latestmedia', 'smalllibrarytiles',
    ):
        add(name)
    return result


_base_patch_desktop = base.patch_desktop


def patch_desktop(settings, defaults):
    desktop = _base_patch_desktop(settings, defaults)
    desktop['homeSections'] = desired_sections(base.section_source(settings, defaults))
    desktop['browsingBlur'] = '8'
    return desktop


base.EDITORIAL_ROWS = EDITORIAL_ROWS
base.EXPLICIT = EXPLICIT
base.EXPLICIT_RE = EXPLICIT_RE
base.editorial_custom_rows = editorial_custom_rows
base.desired_sections = desired_sections
base.patch_desktop = patch_desktop


def __getattr__(name):
    return getattr(base, name)


if __name__ == '__main__':
    base.main()

