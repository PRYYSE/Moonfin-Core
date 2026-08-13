#!/usr/bin/env python3
"""Safe server-side access to the existing Moonbase Seerr sessions."""

import json
import os
import re
import urllib.error
import urllib.request
from pathlib import Path


DEFAULT_JELLYFIN_ROOT = Path('/srv/appdata/jellyfin')
SESSION_DIR_NAME = 'seerr-sessions'
COOKIE_NAME_RE = re.compile(r'^[A-Za-z0-9._-]+$')
PRUNED_DIRS = {
    'backups',
    'cache',
    'log',
    'logs',
    'metadata',
    'transcodes',
}


def _session_files():
    configured = os.environ.get('MOONFIN_SEERR_SESSIONS_DIR', '').strip()
    if configured:
        session_dir = Path(configured)
        if not session_dir.is_dir():
            raise RuntimeError(
                'Configured Moonbase Seerr session directory does not exist.'
            )
        return sorted(session_dir.glob('*.json'))

    root = Path(
        os.environ.get('MOONFIN_JELLYFIN_ROOT', str(DEFAULT_JELLYFIN_ROOT))
    )
    matches = []
    for base, dirs, files in os.walk(root):
        dirs[:] = [
            name
            for name in dirs
            if name.lower() not in PRUNED_DIRS
        ]
        current = Path(base)
        if current.name == SESSION_DIR_NAME:
            matches.extend(
                current / name for name in files if name.endswith('.json')
            )
            dirs[:] = []
    return sorted(matches)


def _sessions():
    sessions = []
    for path in _session_files():
        try:
            payload = json.loads(path.read_text())
        except Exception:
            continue
        if not isinstance(payload, dict):
            continue
        cookie = str(payload.get('sessionCookie') or '').strip()
        cookie_name = str(
            payload.get('sessionCookieName') or 'connect.sid'
        ).strip()
        if not cookie or not COOKIE_NAME_RE.fullmatch(cookie_name):
            continue
        sessions.append(payload)

    sessions.sort(
        key=lambda item: (
            int(
                item.get('seerrUserId') == 1
                or bool(int(item.get('permissions') or 0) & 2)
            ),
            int(item.get('lastValidated') or 0),
        ),
        reverse=True,
    )
    return sessions


def _configured_seerr_url(jellyfin_token, request_json):
    config = request_json('GET', '/Moonfin/Seerr/Config', jellyfin_token) or {}
    url = str(config.get('url') or config.get('Url') or '').strip().rstrip('/')
    enabled = config.get('enabled')
    if enabled is None:
        enabled = config.get('Enabled')
    if not enabled or not url:
        raise RuntimeError('Moonbase Seerr integration is not enabled/configured.')
    return url


def seerr_get(jellyfin_token, path, request_json):
    """GET Seerr JSON using an existing Moonbase-managed session.

    Session cookies stay in memory and are never returned or logged.
    """
    base_url = _configured_seerr_url(jellyfin_token, request_json)
    sessions = _sessions()
    if not sessions:
        raise RuntimeError(
            'No existing Moonbase Seerr session files were found.'
        )

    target = f"{base_url}/api/v1/{path.lstrip('/')}"
    last_auth_error = None

    for session in sessions:
        cookie_name = str(
            session.get('sessionCookieName') or 'connect.sid'
        ).strip()
        cookie = str(session.get('sessionCookie') or '').strip()
        request = urllib.request.Request(
            target,
            headers={
                'Accept': 'application/json',
                'Cookie': f'{cookie_name}={cookie}',
                'User-Agent': 'HomeLabRuntimeGate/1.0',
            },
            method='GET',
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                raw = response.read()
                return json.loads(raw.decode('utf-8')) if raw else None
        except urllib.error.HTTPError as exc:
            if exc.code in (401, 403):
                last_auth_error = exc.code
                continue
            raise RuntimeError(
                f'Seerr GET {path} returned HTTP {exc.code}.'
            ) from None
        except (urllib.error.URLError, TimeoutError) as exc:
            raise RuntimeError(
                f'Seerr GET {path} could not reach the configured server.'
            ) from exc

    raise RuntimeError(
        'No stored Moonbase Seerr session authenticated successfully'
        + (
            f' (last HTTP status {last_auth_error}).'
            if last_auth_error is not None
            else '.'
        )
    )
