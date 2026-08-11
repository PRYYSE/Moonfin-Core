#!/usr/bin/env python3
import json

import home_lab_v2_moonbase as gate


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
        ('tv', 'discover/tv?page=1&sortBy=vote_average.desc&genre=16'),
        ('tv', 'discover/tv?page=1&sortBy=first_air_date.desc&genre=16'),
        ('movie', 'discover/movies?page=1&sortBy=popularity.desc&genre=16'),
        ('tv', 'discover/tv?page=1&sortBy=popularity.desc&genre=10759'),
        ('tv', 'discover/tv?page=1&sortBy=popularity.desc&genre=35'),
        ('tv', 'discover/tv?page=1&sortBy=popularity.desc&genre=18'),
    ]

    viable_shelves = 0
    verified_total = 0
    checked = 0
    detail_failures = 0

    for fallback_type, path in anime_queries:
        candidates = [
            item
            for item in safe_results(token, path, warnings)
            if gate.anime_basic(item)
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
            if any(pattern.search(text) for pattern in gate.EXPLICIT_RE):
                raise RuntimeError(
                    'Anime safety gate found an explicit candidate in ordinary '
                    f'discovery: {gate.title_of(item)}'
                )
            verified += 1

        if verified >= 2:
            viable_shelves += 1
        verified_total += verified

    if viable_shelves < 5 or verified_total < 12:
        raise RuntimeError(
            'Anime discovery gate failed: '
            f'{viable_shelves}/7 shelves viable, '
            f'{verified_total} safe verified titles, '
            f'{detail_failures} detail lookups unavailable.'
        )

    return {
        'movieShelves': movie_nonempty,
        'tvShelves': tv_nonempty,
        'animeShelves': viable_shelves,
        'animeVerified': verified_total,
        'animeChecked': checked,
        'detailFailures': detail_failures,
        'warnings': len(warnings),
    }


def main():
    token = gate.discover_admin_token()
    gate.validate_theme_and_settings(token)
    summary = validate_discovery(token)
    print('RUNTIME DATA GATE PASS')
    print(json.dumps(summary, sort_keys=True))


if __name__ == '__main__':
    main()
