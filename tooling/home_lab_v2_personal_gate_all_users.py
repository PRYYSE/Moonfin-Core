#!/usr/bin/env python3
import json
import urllib.parse

import home_lab_v2_moonbase as gate
from home_lab_safe_auth import jellyfin_token
from home_lab_seerr_auth import seerr_get as direct_seerr_get


def jellyfin_items(token, user_id, *, filters='', sort_by='DateCreated', limit=30):
    params = {
        'Recursive': 'true',
        'IncludeItemTypes': 'Movie,Series',
        'SortBy': sort_by,
        'SortOrder': 'Descending',
        'Limit': str(limit),
        'Fields': 'ProviderIds,Genres,Tags,People,UserData,CommunityRating',
    }
    if filters:
        params['Filters'] = filters
    payload = gate.request_json(
        'GET',
        f'/Users/{urllib.parse.quote(user_id)}/Items?'
        + urllib.parse.urlencode(params),
        token,
    )
    return payload.get('Items') or payload.get('items') or []


def watchlist_items(token):
    try:
        return gate.results(
            direct_seerr_get(
                token,
                'discover/watchlist?page=1',
                gate.request_json,
            )
        )
    except Exception as exc:
        print(f'PERSONAL WARN: watchlist unavailable: {exc}')
        return []


def seed_identity(item):
    providers = item.get('ProviderIds') or item.get('providerIds') or {}
    tmdb = providers.get('Tmdb') or providers.get('tmdb')
    media_type = str(
        item.get('mediaType')
        or item.get('media_type')
        or item.get('Type')
        or item.get('type')
        or ''
    ).lower()
    if media_type == 'series':
        media_type = 'tv'
    if media_type not in ('movie', 'tv'):
        media_type = 'tv' if str(item.get('Type') or '') == 'Series' else 'movie'
    tmdb = tmdb or item.get('tmdbId')
    if not tmdb and (item.get('mediaType') or item.get('media_type')):
        tmdb = item.get('id')
    return media_type, str(tmdb or '').strip()


def recommendation_summary(token, seeds):
    tested = 0
    rows = 0
    recommendation_items = 0
    seen = set()

    for origin, item in seeds:
        if not isinstance(item, dict):
            continue
        media_type, tmdb = seed_identity(item)
        key = f'{media_type}:{tmdb}'
        if not tmdb or key in seen:
            continue
        seen.add(key)
        tested += 1
        try:
            recs = gate.results(
                direct_seerr_get(
                    token,
                    f'{media_type}/{tmdb}/recommendations?page=1',
                    gate.request_json,
                )
            )
        except Exception as exc:
            print(
                'PERSONAL WARN: recommendation lookup unavailable for '
                f'{key}: {exc}'
            )
            recs = []

        safe = [
            item
            for item in recs
            if not bool(item.get('adult', False))
            and not bool((item.get('mediaInfo') or {}).get('status') == 6)
        ]
        if safe:
            rows += 1
            recommendation_items += len(safe)
            print(f'PERSONAL SEED PASS: {origin} {key} -> {len(safe)} items')
        if rows >= 3 or tested >= 10:
            break

    return tested, rows, recommendation_items


def main():
    token = jellyfin_token()
    users = gate.request_json('GET', '/Users', token) or []
    if not isinstance(users, list):
        users = []
    users = [u for u in users if isinstance(u, dict)]
    users.sort(
        key=lambda u: str(
            u.get('LastActivityDate') or u.get('lastActivityDate') or ''
        ),
        reverse=True,
    )

    shared_watchlist = watchlist_items(token)
    best = None

    for user in users:
        user_id = str(user.get('Id') or user.get('id') or '').strip()
        if not user_id:
            continue

        seeds = []
        for origin, kwargs in (
            ('history', {'filters': 'IsPlayed', 'sort_by': 'DatePlayed'}),
            ('favourite', {'filters': 'IsFavorite', 'sort_by': 'DateCreated'}),
            ('rating', {'filters': 'Likes', 'sort_by': 'DateCreated'}),
        ):
            try:
                seeds.extend(
                    (origin, item)
                    for item in jellyfin_items(token, user_id, **kwargs)
                )
            except Exception as exc:
                print(f'PERSONAL WARN: {origin} seeds unavailable: {exc}')

        seeds.extend(('watchlist', item) for item in shared_watchlist)
        try:
            seeds.extend(
                ('library', item)
                for item in jellyfin_items(
                    token,
                    user_id,
                    sort_by='CommunityRating',
                    limit=40,
                )
            )
        except Exception as exc:
            print(f'PERSONAL WARN: library seeds unavailable: {exc}')

        tested, rows, recommendation_items = recommendation_summary(token, seeds)
        candidate = {
            'userId': user_id,
            'seedsTested': tested,
            'seedsWithRecommendations': rows,
            'recommendationItems': recommendation_items,
            'coldStartSources': [
                'history',
                'favourites',
                'likes',
                'watchlist',
                'library',
            ],
        }
        if best is None or rows > best['seedsWithRecommendations']:
            best = candidate
        if rows >= 2 and recommendation_items >= 10:
            print('PERSONAL RECOMMENDATION GATE PASS')
            print(json.dumps(candidate, sort_keys=True))
            return

    raise RuntimeError(
        'Personalisation cold-start gate failed: no user produced at least '
        'two useful recommendation rows from history, favourites, likes, '
        'watchlist or owned-library seeds. Best=' + json.dumps(best)
    )


if __name__ == '__main__':
    main()
