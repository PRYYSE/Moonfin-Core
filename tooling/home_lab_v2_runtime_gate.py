#!/usr/bin/env python3
import json
import re
import urllib.parse

import home_lab_web_refinement_config as gate
from home_lab_safe_auth import jellyfin_token
from home_lab_seerr_auth import seerr_get as direct_seerr_get


EXPLICIT_RE = [
    re.compile(pattern, re.I)
    for pattern in (
        r'\bhentai\b',
        r'\bporn(?:ographic|ography)?\b',
        r'\bxxx\b',
        r'\bsexually explicit\b',
        r'\badult animation\b',
        r'\beroge\b',
        r'\bfutanari\b',
        r'\btentacle sex\b',
    )
]


def anime_basic(item):
    media = item.get('mediaInfo') or item.get('media') or {}
    genres = item.get('genreIds') or item.get('genre_ids') or []
    text = ' '.join([
        gate.title_of(item),
        str(item.get('overview') or ''),
    ])
    return (
        not bool(item.get('adult', False))
        and not bool(isinstance(media, dict) and media.get('status') == 6)
        and str(
            item.get('originalLanguage')
            or item.get('original_language')
            or ''
        ).lower() == 'ja'
        and 16 in genres
        and not any(pattern.search(text) for pattern in EXPLICIT_RE)
    )


def validate_stored_user_settings(token):
    """Validate all user desktop profiles with an admin API key.

    The resolved-settings endpoint is intentionally claim-scoped by Moonbase,
    so a server API key must not be used to assert a particular user's resolved
    profile. The preceding Moonbase apply command already performs a real-user
    resolved check. This gate verifies that every saved user profile contains
    the expected desktop settings before deployment.
    """
    themes = gate.request_json('GET', '/Moonfin/Themes', token)
    if not isinstance(themes, list) or not any(
        isinstance(theme, dict) and theme.get('id') == gate.THEME_ID
        for theme in themes
    ):
        raise RuntimeError(
            'Home Lab custom theme is not available through Moonbase.'
        )

    users = gate.request_json('GET', '/Users', token) or []
    users = [user for user in users if isinstance(user, dict)]
    if not users:
        raise RuntimeError('No Jellyfin users were available for settings validation.')

    required = {
        'customThemeId': gate.THEME_ID,
        'fullScreenRows': False,
        'homeRowsStyle': 'v2',
        'mediaBarMode': 'makd',
        'browsingBlur': '8',
        'displaySinceYouWatchedRows': True,
        'sinceYouWatchedNumRows': 3,
        'seerrBlockNsfw': True,
    }
    required_sections = {
        'resume',
        'nextup',
        'sinceyouwatched1',
        'sinceyouwatched2',
        'sinceyouwatched3',
        'rewatch',
        'seerr_watchlist',
        'seerr_trending',
        'recentlyreleased',
        'latestmedia',
        'smalllibrarytiles',
    }

    checked = 0
    desktops = []
    for user in users:
        user_id = str(user.get('Id') or user.get('id') or '').strip()
        if not user_id:
            continue
        settings = gate.request_json(
            'GET',
            f'/Moonfin/Settings/{urllib.parse.quote(user_id)}',
            token,
        ) or {}
        desktop = settings.get('desktop') or settings.get('Desktop') or {}
        if not isinstance(desktop, dict):
            raise RuntimeError(
                f'User {user_id} has no stored Moonbase desktop profile.'
            )

        for key, expected in required.items():
            if desktop.get(key) != expected:
                raise RuntimeError(
                    f'User {user_id} stored desktop setting {key} '
                    'did not apply as expected.'
                )

        sections = desktop.get('homeSections') or []
        section_types = {
            str(section.get('type') or '').lower()
            for section in sections
            if isinstance(section, dict)
        }
        missing = sorted(required_sections - section_types)
        if missing:
            raise RuntimeError(
                f'User {user_id} is missing required Home sections: '
                + ', '.join(missing)
            )
        desktops.append(desktop)
        checked += 1

    if checked == 0:
        raise RuntimeError('No Jellyfin user settings profiles were validated.')
    print(f'MOONBASE STORED USER SETTINGS PASS: {checked} user(s)')
    return desktops


def validate_custom_rows(token, desktops):
    rows_by_identity = {}
    for desktop in desktops:
        sections = desktop.get('homeSections') or []
        for row in sections:
            if (
                isinstance(row, dict)
                and str(row.get('kind') or '').lower() == 'plugindynamic'
                and str(row.get('pluginSource') or '').lower() == 'custom'
            ):
                identity = str(row.get('pluginSection') or '').strip().lower()
                if identity:
                    rows_by_identity.setdefault(identity, []).append(row)

    required = {
        section_id: chart_type
        for section_id, _title, chart_type, _destinations, _show_on_home
        in gate.EDITORIAL_ROWS
    }
    missing = sorted(set(required) - set(rows_by_identity))
    if missing:
        raise RuntimeError(
            'Moonbase is missing required Home Lab editorial rows: '
            + ', '.join(missing)
        )

    duplicated = sorted(
        section_id
        for section_id in required
        if len(rows_by_identity[section_id]) != 1
    )
    if duplicated:
        raise RuntimeError(
            'Moonbase retained duplicate Home Lab editorial rows: '
            + ', '.join(duplicated)
        )

    invalid = []
    configs = {}
    for section_id, chart_type in required.items():
        row = rows_by_identity[section_id][0]
        try:
            config = json.loads(row.get('pluginAdditionalData') or '{}')
        except json.JSONDecodeError:
            invalid.append(section_id)
            continue
        if (
            not isinstance(config, dict)
            or str(config.get('source') or '').lower() != 'tmdb_chart'
            or str(config.get('type') or '') != chart_type
            or not isinstance(config.get('params'), dict)
            or not isinstance(config.get('homelab_destinations'), list)
        ):
            invalid.append(section_id)
        else:
            configs[section_id] = config

    if invalid:
        raise RuntimeError(
            'Moonbase editorial row definitions are invalid: '
            + ', '.join(sorted(invalid))
        )

    ping = gate.request_json('GET', '/Moonfin/Ping', token) or {}
    tmdb_available = bool(
        ping.get('tmdbAvailable')
        if 'tmdbAvailable' in ping
        else ping.get('TmdbAvailable')
    )
    if not tmdb_available:
        raise RuntimeError(
            'Moonbase reports that the existing TMDb integration is unavailable.'
        )

    dense_by_destination = {'movies': 0, 'tv': 0, 'anime': 0}
    total_by_destination = {'movies': 0, 'tv': 0, 'anime': 0}
    row_warnings = []
    for section_id, config in configs.items():
        destinations = [
            str(value).lower()
            for value in config.get('homelab_destinations', [])
            if str(value).lower() in total_by_destination
        ]
        for destination in destinations:
            total_by_destination[destination] += 1
        query = urllib.parse.urlencode({
            'source': 'tmdb_chart',
            'type': config['type'],
            'params': json.dumps(config.get('params') or {}, separators=(',', ':')),
            'refresh': 'true',
        })
        try:
            payload = gate.request_json(
                'GET', f'/Moonfin/CustomRows/Items?{query}', token
            ) or {}
            items = payload.get('items') or payload.get('Items') or []
            if not isinstance(items, list):
                items = []
        except Exception as exc:
            items = []
            row_warnings.append(f'{section_id}: {exc}')
        if len(items) >= 6:
            for destination in destinations:
                dense_by_destination[destination] += 1

    for destination, total in total_by_destination.items():
        minimum = max(3, int(total * 0.65))
        if dense_by_destination[destination] < minimum:
            raise RuntimeError(
                f'{destination.title()} custom-row density gate failed: '
                f'{dense_by_destination[destination]}/{total} rows returned '
                'at least 6 items.'
            )

    print(
        'MOONBASE EDITORIAL ROWS PASS: '
        f'{len(required)} required, {len(rows_by_identity)} unique configured'
    )
    print(
        'MOONBASE EDITORIAL DENSITY PASS: '
        + ', '.join(
            f'{name} {dense_by_destination[name]}/{total_by_destination[name]}'
            for name in ('movies', 'tv', 'anime')
        )
    )
    return {
        'customRowsConfigured': len(rows_by_identity),
        'customRowsRequired': len(required),
        'customRowsDense': dense_by_destination,
        'customRowWarnings': len(row_warnings),
        'tmdbAvailable': True,
    }

def safe_results(token, path, warnings):
    try:
        return gate.results(direct_seerr_get(token, path, gate.request_json))
    except Exception as exc:
        warnings.append(f'{path}: {exc}')
        print(f'RUNTIME WARN: shelf unavailable: {path}: {exc}')
        return []


def safe_detail(token, path, warnings):
    try:
        detail = direct_seerr_get(token, path, gate.request_json)
        return detail if isinstance(detail, dict) else None
    except Exception as exc:
        warnings.append(f'{path}: {exc}')
        print(f'RUNTIME WARN: detail unavailable: {path}: {exc}')
        return None


def validate_discovery(token):
    warnings = []
    movie_paths = [
        'discover/movies?page=1',
        'discover/movies?page=1&sortBy=vote_average.desc',
        'discover/movies/upcoming?page=1',
        'discover/movies?page=1&sortBy=popularity.desc&genre=28',
        'discover/movies?page=1&sortBy=popularity.desc&genre=878',
    ]
    tv_paths = [
        'discover/tv?page=1',
        'discover/tv?page=1&sortBy=vote_average.desc',
        'discover/tv/upcoming?page=1',
        'discover/tv?page=1&sortBy=popularity.desc&genre=18',
        'discover/tv?page=1&sortBy=popularity.desc&genre=10765',
    ]

    movie_nonempty = sum(bool(safe_results(token, p, warnings)) for p in movie_paths)
    tv_nonempty = sum(bool(safe_results(token, p, warnings)) for p in tv_paths)
    if movie_nonempty < 4:
        raise RuntimeError(
            f'Movie discovery gate failed: only {movie_nonempty}/5 core shelves returned content.'
        )
    if tv_nonempty < 4:
        raise RuntimeError(
            f'TV discovery gate failed: only {tv_nonempty}/5 core shelves returned content.'
        )

    anime_queries = [
        ('tv', 'discover/tv?page=1&sortBy=popularity.desc&genre=16'),
        ('tv', 'discover/tv?page=2&sortBy=popularity.desc&genre=16'),
        ('tv', 'discover/tv?page=1&sortBy=vote_average.desc&genre=16'),
        ('tv', 'discover/tv?page=1&sortBy=first_air_date.desc&genre=16'),
        ('movie', 'discover/movies?page=1&sortBy=popularity.desc&genre=16'),
        ('movie', 'discover/movies?page=1&sortBy=vote_average.desc&genre=16'),
        ('tv', 'discover/tv?page=1&sortBy=popularity.desc&genre=10759'),
        ('tv', 'discover/tv?page=1&sortBy=popularity.desc&genre=10765'),
        ('tv', 'discover/tv?page=1&sortBy=popularity.desc&genre=35'),
        ('tv', 'discover/tv?page=1&sortBy=popularity.desc&genre=18'),
        ('tv', 'discover/tv?page=1&sortBy=popularity.desc&genre=9648'),
        ('tv', 'discover/tv?page=1&sortBy=popularity.desc&genre=80'),
    ]

    viable_shelves = 0
    verified_total = 0
    checked = 0
    detail_failures = 0
    rejected_explicit = 0
    rejected_blacklisted = 0

    for fallback_type, path in anime_queries:
        candidates = [
            item
            for item in safe_results(token, path, warnings)
            if anime_basic(item)
        ][:10]
        verified = 0

        for item in candidates:
            tmdb_id = item.get('id') or item.get('tmdbId')
            if not tmdb_id:
                continue
            media_type = str(
                item.get('mediaType') or item.get('media_type') or fallback_type
            ).lower()
            detail_path = f'{"movie" if media_type == "movie" else "tv"}/{tmdb_id}'
            detail = safe_detail(token, detail_path, warnings)
            if detail is None:
                detail_failures += 1
                continue

            media = detail.get('mediaInfo') or detail.get('media') or {}
            if isinstance(media, dict) and media.get('status') == 6:
                rejected_blacklisted += 1
                continue

            keywords_raw = detail.get('keywords') or []
            if isinstance(keywords_raw, dict):
                keywords_raw = (
                    keywords_raw.get('keywords')
                    or keywords_raw.get('results')
                    or []
                )
            keywords = [
                str(k.get('name') or '')
                for k in keywords_raw
                if isinstance(k, dict)
            ] if isinstance(keywords_raw, list) else []

            genres = detail.get('genres') or []
            genre_names = [
                str(g.get('name') or '')
                for g in genres
                if isinstance(g, dict)
            ]
            text = ' '.join([
                gate.title_of(item),
                str(item.get('overview') or ''),
                gate.title_of(detail),
                str(detail.get('overview') or ''),
                str(detail.get('tagline') or ''),
                ' '.join(keywords),
                ' '.join(genre_names),
            ])
            checked += 1

            # Upstream discovery is allowed to contain explicit/blacklisted anime.
            # The product requirement is that those titles are rejected before they
            # enter ordinary Anime shelves. This mirrors the Dart detail verifier.
            if any(pattern.search(text) for pattern in EXPLICIT_RE):
                rejected_explicit += 1
                continue

            verified += 1

        if verified >= 2:
            viable_shelves += 1
        verified_total += verified

    if viable_shelves < 8 or verified_total < 20:
        raise RuntimeError(
            'Anime discovery gate failed after safety filtering: '
            f'{viable_shelves}/{len(anime_queries)} shelves viable, '
            f'{verified_total} safe verified titles, '
            f'{rejected_explicit} explicit titles rejected, '
            f'{rejected_blacklisted} blacklisted titles rejected, '
            f'{detail_failures} detail lookups unavailable.'
        )

    return {
        'movieShelves': movie_nonempty,
        'tvShelves': tv_nonempty,
        'animeShelves': viable_shelves,
        'animeVerified': verified_total,
        'animeChecked': checked,
        'animeExplicitRejected': rejected_explicit,
        'animeBlacklistedRejected': rejected_blacklisted,
        'detailFailures': detail_failures,
        'warnings': len(warnings),
    }


def main():
    token = jellyfin_token()
    desktops = validate_stored_user_settings(token)
    summary = validate_discovery(token)
    summary.update(validate_custom_rows(token, desktops))
    print('RUNTIME DATA GATE PASS')
    print(json.dumps(summary, sort_keys=True))


if __name__ == '__main__':
    main()
