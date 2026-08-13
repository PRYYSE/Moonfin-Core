#!/usr/bin/env python3
"""Read-only Seerr API access for Home Lab server validation."""

import json
import os
import subprocess
import urllib.error
import urllib.request
from pathlib import Path


CONTAINER_NAME_HINTS = ('seerr', 'jellyseerr')
CONFIG_DESTINATIONS = {'/app/config', '/config'}
CONFIG_FILENAMES = ('settings.json',)


def _docker(args):
    command = ['docker', *args]
    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
            timeout=15,
        )
    except (FileNotFoundError, subprocess.SubprocessError):
        result = subprocess.run(
            ['sudo', '-n', *command],
            check=True,
            capture_output=True,
            text=True,
            timeout=15,
        )
    return result.stdout


def _seerr_container():
    names = [
        name.strip()
        for name in _docker(['ps', '--format', '{{.Names}}']).splitlines()
        if name.strip()
    ]
    matches = [
        name
        for name in names
        if any(hint in name.lower() for hint in CONTAINER_NAME_HINTS)
    ]
    if len(matches) != 1:
        raise RuntimeError(
            'Expected exactly one Seerr/Jellyseerr container; '
            f'found {len(matches)}.'
        )
    return matches[0]


def _container_metadata(name):
    payload = json.loads(_docker(['inspect', name]))
    if not isinstance(payload, list) or len(payload) != 1:
        raise RuntimeError('Could not inspect the configured Seerr container.')
    return payload[0]


def _api_key_from_environment(metadata):
    config = metadata.get('Config') or {}
    for entry in config.get('Env') or []:
        if not isinstance(entry, str) or '=' not in entry:
            continue
        key, value = entry.split('=', 1)
        if key in {'API_KEY', 'SEERR_API_KEY', 'JELLYSEERR_API_KEY'}:
            value = value.strip()
            if value:
                return value
    return None


def _api_key_from_settings(metadata):
    mounts = metadata.get('Mounts') or []
    candidates = []
    for mount in mounts:
        if not isinstance(mount, dict):
            continue
        destination = str(mount.get('Destination') or '').rstrip('/')
        source = str(mount.get('Source') or '').strip()
        if destination not in CONFIG_DESTINATIONS or not source:
            continue
        root = Path(source)
        candidates.extend(root / name for name in CONFIG_FILENAMES)

    for path in candidates:
        try:
            payload = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        main = payload.get('main') if isinstance(payload, dict) else None
        values = []
        if isinstance(main, dict):
            values.append(main.get('apiKey'))
        if isinstance(payload, dict):
            values.extend((payload.get('apiKey'), payload.get('apikey')))
        for value in values:
            value = str(value or '').strip()
            if value:
                return value

    raise RuntimeError(
        'The existing Seerr API key was not found in the container '
        'environment or its explicit config mount.'
    )


def _configured_seerr_url(jellyfin_token, request_json):
    config = request_json('GET', '/Moonfin/Seerr/Config', jellyfin_token) or {}
    url = str(config.get('url') or config.get('Url') or '').strip().rstrip('/')
    enabled = config.get('enabled')
    if enabled is None:
        enabled = config.get('Enabled')
    if not enabled or not url:
        raise RuntimeError('Moonbase Seerr integration is not enabled/configured.')
    return url


def _credentials():
    metadata = _container_metadata(_seerr_container())
    api_key = _api_key_from_environment(metadata)
    if not api_key:
        api_key = _api_key_from_settings(metadata)
    return api_key


_API_KEY = None


def seerr_get(jellyfin_token, path, request_json):
    """GET Seerr JSON with its existing API key, without logging the key."""
    global _API_KEY
    if _API_KEY is None:
        _API_KEY = _credentials()

    base_url = _configured_seerr_url(jellyfin_token, request_json)
    target = f"{base_url}/api/v1/{path.lstrip('/')}"
    request = urllib.request.Request(
        target,
        headers={
            'Accept': 'application/json',
            'X-Api-Key': _API_KEY,
            'User-Agent': 'HomeLabRuntimeGate/1.0',
        },
        method='GET',
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read()
            return json.loads(raw.decode('utf-8')) if raw else None
    except urllib.error.HTTPError as exc:
        raise RuntimeError(
            f'Seerr GET {path} returned HTTP {exc.code}.'
        ) from None
    except (urllib.error.URLError, TimeoutError) as exc:
        raise RuntimeError(
            f'Seerr GET {path} could not reach the configured server.'
        ) from exc
