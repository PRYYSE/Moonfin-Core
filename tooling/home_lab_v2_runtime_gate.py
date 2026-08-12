#!/usr/bin/env python3
import json
import re
import urllib.parse

import home_lab_v2_moonbase as gate
from home_lab_safe_auth import jellyfin_token


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


def validate_custom_rows(token):
    resolved = gate.request_json(
        'GET', '/Moonfin/Settings/Resolved/desktop', token
    ) or {}
    sections = resolved.get('homeSections') or []
    rows = [
        row
        for row in sections
        if isinstance(row, dict)
        and str(row.get('kind') or '').lower() == 'plugindynamic'
        and bool(row.get('enabled', True))
        and str(row.get('pluginSource') or '').lower() == 'custom'
    ]
    nonempty = 0
    item_count = 0
    for row in rows:
        try:
            config = json.loads(row.get('pluginAdditionalData') or '{}')
            source = str(config.get('source') or '')
            row_type = str(config.get('type') or '')
            params = config.get('params') or {}
            if not source or not row_type:
                continue
            query = urllib.parse.urlencode({
                'source': source,
                'type': row_type,
                'params': json.dumps(params, separators=(',', ':')),
            })
            payload = gate.request_json(
                'GET', f'/Moonfin/CustomRows/Items?{query}', token
            ) or {}
            items = payload.get('items') or payload.get('Items') or []
            if items:
                nonempty += 1
                item_count += len(items)
        except Exception as exc:
            print(
                'RUNTIME WARN: custom editorial row unavailable: '
                f'{row.get("pluginDisplayText") or row.get("pluginSection")}: {exc}'
            )
    if rows and nonempty == 0:
        raise RuntimeError(
            'All configured Moonbase custom/pluginDynamic editorial rows '
            'returned empty results.'
        )
    return {
        'customRowsConfigured': len(rows),
        'customRowsNonempty': nonempty,
        'customRowItems': item_count,
    }


def safe_results(token, path, warnings):
    try:
        return gate.results(gate.seerr_get(token, path))
    except Exception as exc:
        warnings.append(f'{path}: {exc}')
        print(f'RUNTIME WARN: shelf unavailable: {path}: {exc}')
        return []


def safe_detail(token, path, warnings):
    try:
        detail = gate.seerr_get(token, path)
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
    gate.validate_theme_and_settings(token)
    summary = validate_discovery(token)
    summary.update(validate_custom_rows(token))
    print('RUNTIME DATA GATE PASS')
    print(json.dumps(summary, sort_keys=True))


if __name__ == '__main__':
    main()
