#!/usr/bin/env python3
import json
import urllib.parse

import home_lab_v2_moonbase as gate


def played_items(token, user_id):
    params = urllib.parse.urlencode({
        'Recursive': 'true',
        'Filters': 'IsPlayed',
        'IncludeItemTypes': 'Movie,Series',
        'SortBy': 'DatePlayed',
        'SortOrder': 'Descending',
        'Limit': '12',
        'Fields': 'ProviderIds,Genres,Tags,People',
    })
    payload = gate.request_json(
        'GET',
        f'/Users/{urllib.parse.quote(user_id)}/Items?{params}',
        token,
    )
    return payload.get('Items') or payload.get('items') or []


def recommendation_summary(token, items):
    tested = 0
    rows = 0
    recommendation_items = 0

    for item in items:
        if not isinstance(item, dict):
            continue
        providers = item.get('ProviderIds') or item.get('providerIds') or {}
        tmdb = providers.get('Tmdb') or providers.get('tmdb')
        if not tmdb:
            continue

        media_type = (
            'tv'
            if str(item.get('Type') or item.get('type')) == 'Series'
            else 'movie'
        )
        tested += 1
        try:
            recs = gate.results(
                gate.seerr_get(token, f'{media_type}/{tmdb}/recommendations?page=1')
            )
        except Exception as exc:
            print(
                'PERSONAL WARN: recommendation lookup unavailable for '
                f'{media_type}/{tmdb}: {exc}'
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
        if tested >= 5:
            break

    return tested, rows, recommendation_items


def main():
    token = gate.discover_admin_token()
    users = gate.request_json('GET', '/Users', token) or []
    if not isinstance(users, list):
        users = []

    users = [u for u in users if isinstance(u, dict)]
    users.sort(
        key=lambda u: str(u.get('LastActivityDate') or u.get('lastActivityDate') or ''),
        reverse=True,
    )

    any_history = False
    best = None

    for user in users:
        user_id = str(user.get('Id') or user.get('id') or '').strip()
        if not user_id:
            continue
        try:
            played = played_items(token, user_id)
        except Exception as exc:
            print(f'PERSONAL WARN: could not read history for user {user_id}: {exc}')
            continue

        tested, rows, recommendation_items = recommendation_summary(token, played)
        if tested == 0:
            continue
        any_history = True
        candidate = {
            'userId': user_id,
            'historySeedsTested': tested,
            'seedsWithRecommendations': rows,
            'recommendationItems': recommendation_items,
        }
        if best is None or rows > best['seedsWithRecommendations']:
            best = candidate
        if rows >= 2:
            print('PERSONAL RECOMMENDATION GATE PASS')
            print(json.dumps(candidate, sort_keys=True))
            return

    if not any_history:
        print(
            'PERSONAL RECOMMENDATION GATE: SKIP '
            '(no Jellyfin user has played TMDb-linked Movie/Series history yet)'
        )
        return

    if best and best['seedsWithRecommendations'] > 0:
        print('PERSONAL RECOMMENDATION GATE PASS (limited history)')
        print(json.dumps(best, sort_keys=True))
        return

    raise RuntimeError(
        'Played TMDb-linked history exists, but Seerr returned no usable '
        'recommendations for any tested Jellyfin user.'
    )


if __name__ == '__main__':
    main()
