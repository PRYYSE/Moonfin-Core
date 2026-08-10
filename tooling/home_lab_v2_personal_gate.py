#!/usr/bin/env python3
import json
import urllib.parse

import home_lab_v2_moonbase as gate


def main():
    token = gate.discover_admin_token()
    me = gate.request_json('GET', '/Users/Me', token)
    user_id = str(me.get('Id') or me.get('id') or '')
    if not user_id:
        raise RuntimeError('Could not resolve the active administrator user for recommendation validation.')

    params = urllib.parse.urlencode({
        'Recursive': 'true',
        'Filters': 'IsPlayed',
        'IncludeItemTypes': 'Movie,Series',
        'SortBy': 'DatePlayed',
        'SortOrder': 'Descending',
        'Limit': '8',
        'Fields': 'ProviderIds,Genres,Tags,People',
    })
    payload = gate.request_json('GET', f'/Users/{urllib.parse.quote(user_id)}/Items?{params}', token)
    played = payload.get('Items') or payload.get('items') or []
    tested = 0
    recommendation_rows = 0
    recommendation_items = 0

    for item in played:
        if not isinstance(item, dict):
            continue
        providers = item.get('ProviderIds') or item.get('providerIds') or {}
        tmdb = providers.get('Tmdb') or providers.get('tmdb')
        if not tmdb:
            continue
        media_type = 'tv' if str(item.get('Type') or item.get('type')) == 'Series' else 'movie'
        tested += 1
        recs = gate.results(gate.seerr_get(token, f'{media_type}/{tmdb}/recommendations?page=1'))
        safe = [
            x for x in recs
            if not bool(x.get('adult', False))
            and not bool((x.get('mediaInfo') or {}).get('status') == 6)
        ]
        if safe:
            recommendation_rows += 1
            recommendation_items += len(safe)
        if tested >= 3:
            break

    if tested == 0:
        print('PERSONAL RECOMMENDATION GATE: SKIP (insufficient played TMDb-linked history)')
        return
    if recommendation_rows == 0:
        raise RuntimeError('Played history exists, but Seerr returned no usable recommendations for tested titles.')

    print('PERSONAL RECOMMENDATION GATE PASS')
    print(json.dumps({
        'historySeedsTested': tested,
        'seedsWithRecommendations': recommendation_rows,
        'recommendationItems': recommendation_items,
    }, sort_keys=True))


if __name__ == '__main__':
    main()
