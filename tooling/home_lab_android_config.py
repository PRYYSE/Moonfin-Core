#!/usr/bin/env python3
"""Apply and validate the release-ready Home Lab profile for Android mobile."""

import argparse
import json
import os
import urllib.parse
from pathlib import Path

import home_lab_web_refinement_config as web
from home_lab_safe_auth import jellyfin_token

CLIENT_ID = 'HomeLab-android-release-v1'
PROFILE = 'mobile'


def _source_sections(settings, defaults):
    for profile in (
        settings.get(PROFILE),
        settings.get('desktop'),
        settings.get('global'),
        defaults,
    ):
        if isinstance(profile, dict):
            sections = profile.get('homeSections')
            if isinstance(sections, list):
                return [dict(row) for row in sections if isinstance(row, dict)]
    return []


def _desired_mobile_sections(settings, defaults):
    output = []
    seen_plugins = set()
    for row in web.desired_sections(_source_sections(settings, defaults)):
        section = dict(row)
        identity = str(section.get('pluginSection') or '').strip().lower()
        if identity:
            if identity in seen_plugins:
                continue
            seen_plugins.add(identity)
        section['order'] = len(output)
        output.append(section)
    return output


def patch_mobile(settings, defaults):
    mobile = dict(settings.get(PROFILE) or {})
    mobile.update({
        'visualTheme': 'moonfin',
        'customThemeId': web.THEME_ID,
        'oledMode': 'off',
        'navbarPosition': 'bottom',
        'navbarAlwaysExpanded': False,
        'navbarOpacity': 0,
        'focusColor': 'moonfinCyan',
        'cardFocusExpansion': True,
        'homeRowsStyle': 'v2',
        'modernHomeRowsPadding': 6,
        'fullScreenRows': False,
        'posterSize': 'medium',
        'detailScreenStyle': 'modern',
        'detailsBackdropOpacity': 82,
        'detailsBackdropBlur': 6,
        'detailsScreenBlur': '6',
        'browsingBlur': '8',
        'backdropEnabled': True,
        'mediaBarMode': 'makd',
        'mediaBarItemCount': 6,
        'mediaBarOpacity': 72,
        'mediaBarOverlayColor': '#000000',
        'mediaBarAutoAdvance': True,
        'mediaBarIntervalMs': 12000,
        'mediaBarTrailerPreview': False,
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
        'homeSections': _desired_mobile_sections(settings, defaults),
    })
    return mobile


def _write_json(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(payload, indent=2, sort_keys=True) + '\n')
    os.chmod(temporary, 0o600)
    temporary.replace(path)


def _save_profile(token, user_id, profile):
    body = {
        'settings': {'schemaVersion': 2, PROFILE: profile},
        'clientId': CLIENT_ID,
        'mergeMode': 'merge',
    }
    web.request_json(
        'POST',
        f'/Moonfin/Settings/{urllib.parse.quote(user_id)}',
        token,
        body,
    )


def apply(token, backup_dir):
    backup = Path(backup_dir)
    backup.mkdir(parents=True, exist_ok=True)
    os.chmod(backup, 0o700)
    defaults = web.request_json('GET', '/Moonfin/Defaults', token) or {}
    users = web.request_json('GET', '/Users', token) or []
    manifest = {'profile': PROFILE, 'users': []}
    try:
        for user in users:
            user_id = str(user.get('Id') or user.get('id') or '').strip()
            if not user_id:
                continue
            settings = web.request_json(
                'GET',
                f'/Moonfin/Settings/{urllib.parse.quote(user_id)}',
                token,
                allow=(404,),
            ) or {'schemaVersion': 2, 'syncEnabled': True}
            _write_json(backup / 'users' / f'{user_id}.json', settings)
            manifest['users'].append({'id': user_id})
            _save_profile(token, user_id, patch_mobile(settings, defaults))
        if not manifest['users']:
            raise RuntimeError('No Jellyfin users were available for Android config.')
        _write_json(backup / 'android-manifest.json', manifest)
    except Exception:
        _write_json(backup / 'android-manifest.json', manifest)
        restore(token, backup)
        raise


def restore(token, backup_dir):
    backup = Path(backup_dir)
    manifest_path = backup / 'android-manifest.json'
    if not manifest_path.exists():
        return
    manifest = json.loads(manifest_path.read_text())
    for entry in manifest.get('users', []):
        user_id = str(entry.get('id') or '').strip()
        path = backup / 'users' / f'{user_id}.json'
        if not user_id or not path.exists():
            continue
        web.request_json(
            'POST',
            f'/Moonfin/Settings/{urllib.parse.quote(user_id)}',
            token,
            {
                'settings': json.loads(path.read_text()),
                'clientId': CLIENT_ID + '-rollback',
                'mergeMode': 'replace',
            },
        )


def validate(token):
    required_ids = {
        str(row.get('pluginSection') or '').strip().lower()
        for row in web.editorial_custom_rows()
    }
    required_builtins = {
        'mediabar', 'resume', 'nextup', 'sinceyouwatched1',
        'sinceyouwatched2', 'sinceyouwatched3', 'rewatch', 'seerr_watchlist',
    }
    users = web.request_json('GET', '/Users', token) or []
    checked = 0
    for user in users:
        user_id = str(user.get('Id') or user.get('id') or '').strip()
        if not user_id:
            continue
        settings = web.request_json(
            'GET',
            f'/Moonfin/Settings/{urllib.parse.quote(user_id)}',
            token,
        ) or {}
        mobile = settings.get(PROFILE)
        if not isinstance(mobile, dict):
            raise RuntimeError(f'Android profile missing for Jellyfin user {user_id}.')
        if mobile.get('customThemeId') != web.THEME_ID:
            raise RuntimeError(f'Android theme mismatch for Jellyfin user {user_id}.')
        if mobile.get('navbarPosition') != 'bottom':
            raise RuntimeError(f'Android navigation mismatch for Jellyfin user {user_id}.')
        sections = mobile.get('homeSections') or []
        managed = [
            str(row.get('pluginSection') or '').strip().lower()
            for row in sections
            if isinstance(row, dict)
            and str(row.get('pluginSection') or '').strip().lower() in required_ids
        ]
        if set(managed) != required_ids or len(managed) != len(required_ids):
            raise RuntimeError(f'Android editorial rows are incomplete or duplicated for {user_id}.')
        builtins = {
            str(row.get('type') or '').strip().lower()
            for row in sections
            if isinstance(row, dict)
            and str(row.get('kind') or '').strip().lower() == 'builtin'
            and bool(row.get('enabled', True))
        }
        if not required_builtins.issubset(builtins):
            raise RuntimeError(f'Android personalised rows are incomplete for {user_id}.')
        checked += 1
    if checked == 0:
        raise RuntimeError('No Android user profiles were validated.')
    print(f'ANDROID MOONBASE PROFILE PASS: {checked} user(s), {len(required_ids)} editorial rows')


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest='command', required=True)
    apply_parser = commands.add_parser('apply')
    apply_parser.add_argument('--backup-dir', required=True)
    restore_parser = commands.add_parser('restore')
    restore_parser.add_argument('--backup-dir', required=True)
    commands.add_parser('validate')
    args = parser.parse_args()
    token = jellyfin_token()
    if args.command == 'apply':
        apply(token, args.backup_dir)
        validate(token)
    elif args.command == 'restore':
        restore(token, args.backup_dir)
        print('ANDROID MOONBASE PROFILE RESTORED')
    else:
        validate(token)


if __name__ == '__main__':
    main()
