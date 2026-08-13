#!/usr/bin/env python3
import argparse
import json
import os
import re
import sqlite3
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from home_lab_safe_auth import jellyfin_token

BASE = 'http://127.0.0.1:8096'
THEME_ID = 'home_lab_streaming'
PREVIEW_THEME_IDS = (
    'home_lab_lunar_glass',
    'home_lab_neon_arcade',
    'home_lab_velvet_cinema',
    'home_lab_arctic_minimal',
    'home_lab_kyoto_night',
    'home_lab_forest_signal',
)
CLIENT_ID = 'HomeLab-web-desktop-v2'
EXPLICIT = [
    r'\bsex\b', r'sexual', r'\bporn\b', r'erotic', r'\bnude\b', r'nudity',
    r'\bxxx\b', r'adult film', r'prostitute', r'stripper', r'\bescort\b',
    r'seduction', r'\baffair\b', r'threesome', r'\borgy\b', r'kinky',
    r'fetish', r'\bbdsm\b', r'dominatrix', r'\bhentai\b', r'pornographic',
    r'sexually explicit', r'adult animation', r'\beroge\b', r'\bfutanari\b',
    r'\bnetorare\b', r'tentacle sex', r'\bincest\b', r'\brape\b',
]
EXPLICIT_RE = [re.compile(x, re.I) for x in EXPLICIT]

EDITORIAL_ROWS = (
    ('homelab_movies_popular', 'Popular Movies', 'movie/popular'),
    ('homelab_movies_top_rated', 'Top Rated Movies', 'movie/top_rated'),
    ('homelab_movies_upcoming', 'Coming Soon to Movies', 'movie/upcoming'),
    ('homelab_tv_popular', 'Popular Series', 'tv/popular'),
    ('homelab_tv_top_rated', 'Top Rated Series', 'tv/top_rated'),
    ('homelab_tv_on_air', 'New and Returning Series', 'tv/on_the_air'),
    (
        'homelab_anime_popular',
        'Anime Spotlight',
        'discover/tv?with_genres=16&with_original_language=ja'
        '&sort_by=popularity.desc',
    ),
    (
        'homelab_anime_top_rated',
        'Top Rated Anime',
        'discover/tv?with_genres=16&with_original_language=ja'
        '&sort_by=vote_average.desc&vote_count.gte=100',
    ),
    (
        'homelab_anime_new',
        'New Season Anime',
        'discover/tv?with_genres=16&with_original_language=ja'
        '&sort_by=first_air_date.desc&vote_count.gte=5',
    ),
    (
        'homelab_anime_movies',
        'Anime Movies',
        'discover/movie?with_genres=16&with_original_language=ja'
        '&sort_by=popularity.desc',
    ),
    (
        'homelab_anime_action',
        'Action Anime',
        'discover/tv?with_genres=16,10759&with_original_language=ja'
        '&sort_by=popularity.desc',
    ),
    (
        'homelab_anime_comedy',
        'Comedy Anime',
        'discover/tv?with_genres=16,35&with_original_language=ja'
        '&sort_by=popularity.desc',
    ),
)

class ApiError(RuntimeError):
    def __init__(self, method, path, status, detail=''):
        super().__init__(f'{method} {path}: HTTP {status}{": " + detail if detail else ""}')
        self.status = status


def auth_headers(token):
    return {
        'Authorization': f'MediaBrowser Token="{token}"',
        'X-Emby-Token': token,
        'X-MediaBrowser-Token': token,
        'Accept': 'application/json',
        'User-Agent': 'HomeLabV2/1.0',
    }


def request_json(method, path, token, data=None, allow=()):
    body = None
    headers = auth_headers(token)
    if data is not None:
        body = json.dumps(data, separators=(',', ':')).encode('utf-8')
        headers['Content-Type'] = 'application/json'
    req = urllib.request.Request(BASE + path, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            if not raw:
                return None
            return json.loads(raw.decode('utf-8'))
    except urllib.error.HTTPError as exc:
        if exc.code in allow:
            return None
        detail = ''
        try:
            payload = exc.read().decode('utf-8', 'replace')[:500]
            parsed = json.loads(payload)
            if isinstance(parsed, dict):
                detail = str(parsed.get('error') or parsed.get('Error') or '')[:300]
        except Exception:
            pass
        raise ApiError(method, path, exc.code, detail) from None


def unwrap_proxy(payload):
    if isinstance(payload, dict):
        file_contents = payload.get('FileContents') or payload.get('fileContents')
        if isinstance(file_contents, str):
            try:
                return json.loads(file_contents)
            except json.JSONDecodeError:
                return payload
    return payload


def candidate_databases(root):
    paths = []
    for base, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in {'cache', 'transcodes', 'metadata'}]
        for name in files:
            if name.endswith('.db'):
                paths.append(Path(base) / name)
    return sorted(paths, key=lambda p: (p.name != 'jellyfin.db', len(str(p))))


def token_candidates(db_path):
    seen = set()
    try:
        conn = sqlite3.connect(f'file:{db_path}?mode=ro', uri=True)
    except Exception:
        return
    try:
        tables = [r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")]
        for table in tables:
            safe_table = table.replace('"', '""')
            try:
                cols = [r[1] for r in conn.execute(f'PRAGMA table_info("{safe_table}")')]
            except Exception:
                continue
            for col in cols:
                lc = col.lower()
                if 'token' not in lc and lc not in {'apikey', 'api_key', 'accesskey'}:
                    continue
                safe_col = col.replace('"', '""')
                try:
                    rows = conn.execute(
                        f'SELECT "{safe_col}" FROM "{safe_table}" '
                        f'WHERE "{safe_col}" IS NOT NULL LIMIT 500'
                    )
                    for (value,) in rows:
                        if isinstance(value, bytes):
                            try:
                                value = value.decode('utf-8')
                            except Exception:
                                continue
                        if not isinstance(value, str):
                            continue
                        value = value.strip()
                        if len(value) < 12 or value in seen:
                            continue
                        seen.add(value)
                        yield value
                except Exception:
                    continue
    finally:
        conn.close()


def discover_admin_token(root='/srv/appdata/jellyfin'):
    for db in candidate_databases(root):
        for token in token_candidates(db):
            try:
                me = request_json('GET', '/Users/Me', token)
                if not isinstance(me, dict):
                    continue
                policy = me.get('Policy') or me.get('policy') or {}
                if not isinstance(policy, dict):
                    continue
                is_admin = bool(
                    policy.get('IsAdministrator') or policy.get('isAdministrator')
                )
                if not is_admin:
                    continue
                users = request_json('GET', '/Users', token)
                if isinstance(users, list):
                    return token
            except Exception:
                continue
    raise RuntimeError(
        'Could not automatically locate a working Jellyfin administrator user token.'
    )


def atomic_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')
    os.chmod(temp, 0o600)
    temp.replace(path)


def builtin(section_type, order, enabled=True):
    return {
        'kind': 'builtin',
        'type': section_type,
        'enabled': enabled,
        'order': order,
    }


def editorial_custom_rows():
    rows = []
    for section_id, title, chart_type in EDITORIAL_ROWS:
        rows.append({
            'kind': 'pluginDynamic',
            'type': 'none',
            'enabled': True,
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
                },
                separators=(',', ':'),
            ),
            'pluginDisplayText': title,
        })
    return rows


def section_source(settings, defaults):
    for profile in (settings.get('desktop'), settings.get('global'), defaults):
        if isinstance(profile, dict):
            sections = profile.get('homeSections')
            if isinstance(sections, list):
                return [dict(x) for x in sections if isinstance(x, dict)]
    return []


def desired_sections(existing):
    dynamics = [
        dict(s)
        for s in existing
        if str(s.get('kind', '')).lower() == 'plugindynamic'
    ]
    existing_ids = {
        str(row.get('pluginSection') or '').strip().lower()
        for row in dynamics
    }
    for row in editorial_custom_rows():
        identity = str(row.get('pluginSection') or '').strip().lower()
        if identity not in existing_ids:
            dynamics.append(row)
            existing_ids.add(identity)

    result = []
    order = 0

    def add(name):
        nonlocal order
        result.append(builtin(name, order))
        order += 1

    for name in (
        'mediabar',
        'resume',
        'nextup',
        'sinceyouwatched1',
        'sinceyouwatched2',
        'sinceyouwatched3',
        'rewatch',
        'seerr_watchlist',
    ):
        add(name)

    for row in sorted(dynamics, key=lambda x: int(x.get('order') or 0)):
        row['order'] = order
        result.append(row)
        order += 1

    for name in (
        'seerr_trending',
        'recentlyreleased',
        'seerr_recently_added',
        'collections',
        'genres',
        'latestmedia',
        'smalllibrarytiles',
    ):
        add(name)
    return result


def patch_desktop(settings, defaults):
    desktop = dict(settings.get('desktop') or {})
    source_sections = section_source(settings, defaults)
    desktop.update({
        'visualTheme': 'moonfin',
        'customThemeId': THEME_ID,
        'oledMode': 'off',
        'navbarPosition': 'left',
        'navbarAlwaysExpanded': False,
        'navbarOpacity': 0,
        'navbarColor': '#000000',
        'focusColor': 'moonfinCyan',
        'cardFocusExpansion': True,
        'homeRowsStyle': 'v2',
        'modernHomeRowsPadding': 8,
        'fullScreenRows': False,
        'posterSize': 'medium',
        'desktopUiScale': 'medium',
        'detailScreenStyle': 'modern',
        'detailsBackdropOpacity': 82,
        'detailsBackdropBlur': 6,
        'detailsScreenBlur': '6',
        'browsingBlur': '0',
        'backdropEnabled': True,
        'mediaBarMode': 'makd',
        'mediaBarItemCount': 8,
        'mediaBarOpacity': 72,
        'mediaBarOverlayColor': '#000000',
        'mediaBarAutoAdvance': True,
        'mediaBarIntervalMs': 12000,
        'mediaBarTrailerPreview': True,
        'mediaBarTrailerAudio': False,
        'mediaBarTrailerCaptions': True,
        'mergeContinueWatchingNextUp': False,
        'mergeRecentRowsByType': True,
        'displayCollectionsRows': True,
        'displayGenresRows': True,
        'displaySeerrRows': True,
        'displaySinceYouWatchedRows': True,
        'sinceYouWatchedSource': 'online',
        'sinceYouWatchedSourceType': 'both',
        'sinceYouWatchedSourceItem': 'recentlyWatched',
        'sinceYouWatchedNumRows': 3,
        'sinceYouWatchedIncludeWatched': False,
        'sinceYouWatched1Enabled': True,
        'sinceYouWatched2Enabled': True,
        'sinceYouWatched3Enabled': True,
        'sinceYouWatched4Enabled': False,
        'sinceYouWatched5Enabled': False,
        'displayRewatchRow': True,
        'rewatchSortBy': 'random',
        'rewatchIncludeMovies': True,
        'rewatchIncludeShows': True,
        'rewatchIncludeCollections': False,
        'recommendationSystemSource': 'online',
        'recommendationsApplyParentalRatingCap': True,
        'seerrBlockNsfw': True,
        'homeSections': desired_sections(source_sections),
    })
    return desktop


def save_user_desktop(token, user_id, desktop):
    body = {
        'settings': {
            'schemaVersion': 2,
            'desktop': desktop,
        },
        'clientId': CLIENT_ID,
        'mergeMode': 'merge',
    }
    request_json('POST', f'/Moonfin/Settings/{urllib.parse.quote(user_id)}', token, body)


def restore_settings(token, backup_dir):
    backup = Path(backup_dir)
    manifest_path = backup / 'moonbase-manifest.json'
    if not manifest_path.exists():
        return
    manifest = json.loads(manifest_path.read_text())
    for entry in manifest.get('users', []):
        user_id = entry['id']
        original_path = backup / 'users' / f'{user_id}.json'
        if not original_path.exists():
            continue
        original = json.loads(original_path.read_text())
        body = {
            'settings': original,
            'clientId': CLIENT_ID + '-rollback',
            'mergeMode': 'replace',
        }
        request_json('POST', f'/Moonfin/Settings/{urllib.parse.quote(user_id)}', token, body)

    theme_path = backup / 'theme-before.json'
    theme_absent = bool(manifest.get('themeAbsent'))
    if theme_absent:
        try:
            request_json('DELETE', f'/Moonfin/Admin/Themes/{THEME_ID}', token, allow=(404,))
        except Exception:
            pass
    elif theme_path.exists():
        request_json(
            'POST',
            '/Moonfin/Admin/Themes',
            token,
            json.loads(theme_path.read_text()),
        )

    for entry in manifest.get('previewThemes', []):
        theme_id = str(entry.get('id') or '').strip()
        if not theme_id:
            continue
        if bool(entry.get('absent')):
            request_json(
                'DELETE',
                f'/Moonfin/Admin/Themes/{urllib.parse.quote(theme_id)}',
                token,
                allow=(404,),
            )
            continue
        backup_name = str(entry.get('backup') or '').strip()
        before_path = backup / 'preview-themes' / backup_name
        if before_path.exists():
            request_json(
                'POST',
                '/Moonfin/Admin/Themes',
                token,
                json.loads(before_path.read_text()),
            )


def load_preview_themes(directory):
    if not directory:
        return []
    root = Path(directory)
    if not root.is_dir():
        raise RuntimeError(f'Preview theme directory is missing: {root}')
    themes = []
    seen = set()
    for path in sorted(root.glob('*.json')):
        theme = json.loads(path.read_text())
        theme_id = str(theme.get('id') or '').strip()
        if not theme_id or theme_id == THEME_ID or theme_id in seen:
            raise RuntimeError(f'Invalid or duplicate preview theme ID in {path}.')
        seen.add(theme_id)
        themes.append((path, theme))
    if seen != set(PREVIEW_THEME_IDS):
        missing = sorted(set(PREVIEW_THEME_IDS) - seen)
        extra = sorted(seen - set(PREVIEW_THEME_IDS))
        raise RuntimeError(
            'Preview theme set mismatch. '
            f'Missing={missing}; extra={extra}'
        )
    return themes


def apply(token, backup_dir, theme_path, preview_themes_dir=None):
    backup = Path(backup_dir)
    backup.mkdir(parents=True, exist_ok=True)
    os.chmod(backup, 0o700)

    theme_before = request_json('GET', f'/Moonfin/Themes/{THEME_ID}', token, allow=(404,))
    theme_absent = theme_before is None
    if theme_before is not None:
        atomic_json(backup / 'theme-before.json', theme_before)

    theme = json.loads(Path(theme_path).read_text())
    preview_themes = load_preview_themes(preview_themes_dir)
    users = request_json('GET', '/Users', token)
    defaults = request_json('GET', '/Moonfin/Defaults', token) or {}
    manifest = {
        'themeAbsent': theme_absent,
        'users': [],
        'previewThemes': [],
    }

    try:
        request_json('POST', '/Moonfin/Admin/Themes', token, theme)

        for path, preview_theme in preview_themes:
            preview_id = str(preview_theme['id'])
            before = request_json(
                'GET',
                f'/Moonfin/Themes/{urllib.parse.quote(preview_id)}',
                token,
                allow=(404,),
            )
            entry = {
                'id': preview_id,
                'absent': before is None,
                'backup': path.name,
            }
            manifest['previewThemes'].append(entry)
            if before is not None:
                atomic_json(
                    backup / 'preview-themes' / path.name,
                    before,
                )
            request_json(
                'POST',
                '/Moonfin/Admin/Themes',
                token,
                preview_theme,
            )

        for user in users:
            user_id = str(user.get('Id') or user.get('id') or '').strip()
            if not user_id:
                continue
            settings = request_json(
                'GET',
                f'/Moonfin/Settings/{urllib.parse.quote(user_id)}',
                token,
                allow=(404,),
            )
            existed = settings is not None
            if settings is None:
                settings = {'schemaVersion': 2, 'syncEnabled': True}
            atomic_json(backup / 'users' / f'{user_id}.json', settings)
            manifest['users'].append({'id': user_id, 'existed': existed})
            desktop = patch_desktop(settings, defaults)
            save_user_desktop(token, user_id, desktop)
        atomic_json(backup / 'moonbase-manifest.json', manifest)
    except Exception:
        atomic_json(backup / 'moonbase-manifest.json', manifest)
        restore_settings(token, backup)
        raise


def validate_theme_and_settings(token):
    """Validate the saved desktop profile for every Jellyfin user.

    Moonbase's resolved endpoint is scoped to the authenticated user's claims.
    Admin API keys therefore validate users through the supported
    /Moonfin/Settings/{userId} route instead.
    """
    themes = request_json('GET', '/Moonfin/Themes', token)
    available_theme_ids = {
        str(theme.get('id') or '')
        for theme in themes
        if isinstance(theme, dict)
    } if isinstance(themes, list) else set()
    required_theme_ids = {THEME_ID, *PREVIEW_THEME_IDS}
    missing_theme_ids = sorted(required_theme_ids - available_theme_ids)
    if missing_theme_ids:
        raise RuntimeError(
            'Required Home Lab themes are unavailable through Moonbase: '
            + ', '.join(missing_theme_ids)
        )

    users = request_json('GET', '/Users', token) or []
    users = [user for user in users if isinstance(user, dict)]
    if not users:
        raise RuntimeError(
            'No Jellyfin users were available for Moonbase validation.'
        )

    required = {
        'customThemeId': THEME_ID,
        'fullScreenRows': False,
        'homeRowsStyle': 'v2',
        'mediaBarMode': 'makd',
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
    for user in users:
        user_id = str(user.get('Id') or user.get('id') or '').strip()
        if not user_id:
            continue
        settings = request_json(
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
        checked += 1

    if checked == 0:
        raise RuntimeError('No Jellyfin user settings profiles were validated.')
    print(f'MOONBASE USER SETTINGS PASS: {checked} user(s)')


def seerr_get(token, path):
    return unwrap_proxy(request_json('GET', '/Moonfin/Seerr/Api/' + path, token))


def results(payload):
    if not isinstance(payload, dict):
        return []
    raw = payload.get('results') or payload.get('Results') or []
    return [x for x in raw if isinstance(x, dict)]


def title_of(item):
    return str(item.get('title') or item.get('name') or item.get('originalName') or item.get('originalTitle') or '')


def anime_basic(item):
    adult = bool(item.get('adult', False))
    media = item.get('mediaInfo') or item.get('media') or {}
    blacklisted = isinstance(media, dict) and media.get('status') == 6
    lang = str(item.get('originalLanguage') or item.get('original_language') or '').lower()
    genres = item.get('genreIds') or item.get('genre_ids') or []
    text = f"{title_of(item)} {item.get('overview') or ''}"
    return not adult and not blacklisted and lang == 'ja' and 16 in genres and not any(r.search(text) for r in EXPLICIT_RE)


def validate_discovery(token):
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
    def safe_results(path):
        try:
            return results(seerr_get(token, path))
        except ApiError as exc:
            print(f'RUNTIME WARN: shelf unavailable: {path}: {exc}')
            return []

    movie_nonempty = sum(bool(safe_results(p)) for p in movie_paths)
    tv_nonempty = sum(bool(safe_results(p)) for p in tv_paths)
    if movie_nonempty < 4:
        raise RuntimeError(f'Movie discovery gate failed: only {movie_nonempty}/5 core shelves returned content.')
    if tv_nonempty < 4:
        raise RuntimeError(f'TV discovery gate failed: only {tv_nonempty}/5 core shelves returned content.')

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
    for fallback_type, path in anime_queries:
        candidates = [x for x in safe_results(path) if anime_basic(x)][:10]
        verified = 0
        for item in candidates:
            tmdb_id = item.get('id') or item.get('tmdbId')
            media_type = str(item.get('mediaType') or fallback_type)
            if not tmdb_id:
                continue
            detail = seerr_get(token, f'{"movie" if media_type == "movie" else "tv"}/{tmdb_id}')
            if not isinstance(detail, dict):
                continue
            media = detail.get('mediaInfo') or detail.get('media') or {}
            if isinstance(media, dict) and media.get('status') == 6:
                continue
            keywords_raw = detail.get('keywords') or []
            keywords = []
            if isinstance(keywords_raw, dict):
                keywords_raw = keywords_raw.get('keywords') or keywords_raw.get('results') or []
            if isinstance(keywords_raw, list):
                for k in keywords_raw:
                    if isinstance(k, dict):
                        keywords.append(str(k.get('name') or ''))
            genres = detail.get('genres') or []
            genre_names = [str(g.get('name') or '') for g in genres if isinstance(g, dict)]
            text = ' '.join([
                title_of(item), str(item.get('overview') or ''),
                title_of(detail), str(detail.get('overview') or ''),
                str(detail.get('tagline') or ''), ' '.join(keywords), ' '.join(genre_names),
            ])
            checked += 1
            if any(r.search(text) for r in EXPLICIT_RE):
                raise RuntimeError(f'Anime safety gate found an explicit candidate in ordinary discovery: {title_of(item)}')
            verified += 1
        if verified >= 2:
            viable_shelves += 1
        verified_total += verified
    if viable_shelves < 5 or verified_total < 12:
        raise RuntimeError(
            f'Anime discovery gate failed: {viable_shelves}/7 shelves viable, {verified_total} safe verified titles.'
        )
    return {'movieShelves': movie_nonempty, 'tvShelves': tv_nonempty, 'animeShelves': viable_shelves, 'animeVerified': verified_total, 'animeChecked': checked}


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest='command', required=True)
    p_apply = sub.add_parser('apply')
    p_apply.add_argument('--backup-dir', required=True)
    p_apply.add_argument('--theme', required=True)
    p_apply.add_argument('--preview-themes-dir')
    p_restore = sub.add_parser('restore')
    p_restore.add_argument('--backup-dir', required=True)
    p_validate = sub.add_parser('validate')
    args = parser.parse_args()

    token = jellyfin_token()
    if args.command == 'apply':
        apply(
            token,
            args.backup_dir,
            args.theme,
            preview_themes_dir=args.preview_themes_dir,
        )
        validate_theme_and_settings(token)
        print('MOONBASE CONFIG PASS')
    elif args.command == 'restore':
        restore_settings(token, args.backup_dir)
        print('MOONBASE CONFIG RESTORED')
    else:
        validate_theme_and_settings(token)
        summary = validate_discovery(token)
        print('RUNTIME DATA GATE PASS')
        print(json.dumps(summary, sort_keys=True))

if __name__ == '__main__':
    main()
