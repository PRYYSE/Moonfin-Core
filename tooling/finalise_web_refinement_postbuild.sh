#!/usr/bin/env bash
set -Eeuo pipefail

SRC=/opt/src/moonfin-core
DEV=/opt/src/moonfin-dev
PLUGIN_ROOT=/srv/appdata/jellyfin/data/plugins
BACKUP_ROOT=/srv/appdata/jellyfin/backups
BASE=http://127.0.0.1:8096

STAGING_BRANCH=homelab/content-personalisation-v1-staging
MAIN_BRANCH=homelab/hubs-v1
LIVE_BASELINE=c7537d8784d34571c6a7ecc3a10f911066fb3263
PRODUCT_COMMIT=9be74475d0ff7dfed6a573a5f8a9e5225b8331e6
BUNDLE=/opt/src/moonfin-dev/output/homelab-moonfin-web-v2-20260813-154005.tar.gz

STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="$BACKUP_ROOT/web-refinement-postbuild-$STAMP"
VERIFY=''
PLUGIN_DIR=''
FRONTEND=''
STAGE=''
OLD_FRONTEND=''
CONFIG_APPLIED=0
JELLYFIN_STOPPED=0
OLD_SAVED=0

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  return 1
}

if docker info >/dev/null 2>&1; then
  D=(docker)
else
  D=(sudo -n docker)
fi

wait_for_moonfin() {
  local code
  for _ in $(seq 1 50); do
    code="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE/Moonfin/Web/" || true)"
    [[ "$code" == 200 ]] && return 0
    sleep 2
  done
  return 1
}

restore_on_failure() {
  local rc=$?
  trap - EXIT
  set +e
  [[ -z "$VERIFY" ]] || rm -rf "$VERIFY"

  if [[ $rc -ne 0 ]]; then
    echo
    echo '=== WEB REFINEMENT POST-BUILD FAILED: AUTOMATIC RESTORE ==='
    if [[ "$OLD_SAVED" == 1 ]] && sudo -n test -d "$OLD_FRONTEND"; then
      "${D[@]}" stop jellyfin >/dev/null 2>&1 || true
      if sudo -n test -d "$FRONTEND"; then
        sudo -n mv "$FRONTEND" "$RUN/failed-candidate-frontend" 2>/dev/null || true
      fi
      sudo -n mv "$OLD_FRONTEND" "$FRONTEND" 2>/dev/null || true
      "${D[@]}" start jellyfin >/dev/null 2>&1 || true
      echo 'Previous validated frontend restored.'
    elif [[ "$JELLYFIN_STOPPED" == 1 ]]; then
      "${D[@]}" start jellyfin >/dev/null 2>&1 || true
    fi

    if [[ "$CONFIG_APPLIED" == 1 ]]; then
      sudo -n env PYTHONPATH="$SRC/tooling" \
        python3 "$SRC/tooling/home_lab_v2_moonbase.py" \
        restore --backup-dir "$RUN/moonbase" >/dev/null 2>&1 || true
      echo 'Previous Moonbase settings restored.'
    fi
    [[ -z "$STAGE" ]] || sudo -n rm -rf "$STAGE"
    echo "Rollback data: $RUN"
  fi
  exit "$rc"
}
trap restore_on_failure EXIT

cd "$SRC"

echo '=== 1. VERIFY VALIDATION TOOLING AND BUILT PRODUCT ==='
[[ "$(git branch --show-current)" == "$STAGING_BRANCH" ]] || fail 'Wrong staging branch.'
[[ -z "$(git status --porcelain)" ]] || fail 'Source tree is dirty.'
git fetch origin \
  "$STAGING_BRANCH:refs/remotes/origin/$STAGING_BRANCH" \
  "$MAIN_BRANCH:refs/remotes/origin/$MAIN_BRANCH"
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/$STAGING_BRANCH)" ]] ||
  fail 'Local staging is not the exact remote validation commit.'
[[ "$(git rev-parse origin/$MAIN_BRANCH)" == "$LIVE_BASELINE" ]] ||
  fail 'Product branch changed unexpectedly.'
git merge-base --is-ancestor "$PRODUCT_COMMIT" HEAD ||
  fail 'The already-built product is not an ancestor of the validation tooling.'

mapfile -t TOOLING_DELTA < <(git diff --name-only "$PRODUCT_COMMIT..HEAD")
for path in "${TOOLING_DELTA[@]}"; do
  case "$path" in
    tooling/home_lab_web_refinement_config.py|\
    tooling/home_lab_v2_runtime_gate.py|\
    tooling/finalise_web_refinement_postbuild.sh) ;;
    *) fail "Unexpected post-build source change: $path" ;;
  esac
done

python3 -m py_compile \
  tooling/home_lab_safe_auth.py \
  tooling/home_lab_seerr_auth.py \
  tooling/home_lab_v2_moonbase.py \
  tooling/home_lab_web_refinement_config.py \
  tooling/home_lab_v2_runtime_gate.py \
  tooling/home_lab_v2_personal_gate_all_users.py

PYTHONPATH="$SRC/tooling" python3 - <<'PY'
import copy
import json
import home_lab_web_refinement_config as moonbase
import home_lab_v2_runtime_gate as runtime_gate

rows = moonbase.editorial_custom_rows()
ids = [row['pluginSection'] for row in rows]
assert len(rows) == 33 and len(ids) == len(set(ids))

calls = []
original = moonbase.base.request_json
legacy = dict(rows[0])
legacy['enabled'] = False
legacy['order'] = 99
legacy_metadata = json.loads(legacy['pluginAdditionalData'])
legacy_metadata.pop('homelab_destinations')
legacy_metadata.pop('homelab_destination_only')
legacy['pluginAdditionalData'] = json.dumps(legacy_metadata)

stored_settings = {
    'schemaVersion': 2,
    'global': {
        'untouched': True,
        'homeSections': [dict(legacy)],
    },
    'mobile': {
        'untouched': True,
        'homeSections': [dict(legacy)],
    },
    'tv': {
        'untouched': True,
        'homeSections': [dict(legacy)],
    },
    'desktop': {'homeSections': [{'pluginSection': 'stale'}]},
}

def fake(method, path, token, body=None, allow=()):
    global stored_settings
    if method == 'GET':
        return copy.deepcopy(stored_settings)
    calls.append((method, path, body))
    stored_settings = copy.deepcopy(body['settings'])

    # Mirror Moonbase 2.0.3 propagation: profiles with a layout receive every
    # known custom row, retaining each profile's own enabled state and order.
    managed = {
        row['pluginSection'].lower(): row
        for row in rows
    }
    for profile_name in ('global', 'desktop', 'mobile', 'tv'):
        profile = stored_settings.get(profile_name)
        if not isinstance(profile, dict):
            continue
        sections = profile.get('homeSections')
        if not isinstance(sections, list):
            continue
        present = {
            str(row.get('pluginSection') or '').lower(): row
            for row in sections
            if isinstance(row, dict)
        }
        for identity, expected in managed.items():
            if identity in present:
                continue
            added = dict(expected)
            added['enabled'] = False
            added['order'] = len(sections)
            sections.append(added)
            present[identity] = added

moonbase.base.request_json = fake
try:
    desktop = {'homeSections': rows}
    moonbase.save_user_desktop('token', 'user/id', desktop)
finally:
    moonbase.base.request_json = original

body = calls[0][2]
assert body['mergeMode'] == 'replace'
assert body['settings']['desktop'] == desktop
expected_metadata = rows[0]['pluginAdditionalData']
for profile_name in ('global', 'mobile', 'tv'):
    profile = body['settings'][profile_name]
    assert profile['untouched'] is True
    stored = profile['homeSections'][0]
    assert stored['pluginAdditionalData'] == expected_metadata
    assert stored['pluginDisplayText'] == rows[0]['pluginDisplayText']
    assert stored['enabled'] is False
    assert stored['order'] == 99

original_runtime_request = runtime_gate.gate.request_json

def fake_runtime_request(method, path, token, body=None, allow=()):
    if path == '/Moonfin/Ping':
        return {'tmdbAvailable': True}
    raise AssertionError(path)

runtime_gate.gate.request_json = fake_runtime_request
try:
    summary = runtime_gate.validate_custom_rows(
        'token',
        [{'homeSections': rows} for _ in range(3)],
    )
    assert summary['customRowsConfigured'] == 33
    assert summary['customRowsByDestination'] == {
        'movies': 9,
        'tv': 10,
        'anime': 14,
    }
    assert summary['customRowsLiveFetch'] == 'signed-in-client-required'
    duplicate_rows = list(rows) + [dict(rows[0])]
    try:
        runtime_gate.validate_custom_rows(
            'token',
            [{'homeSections': duplicate_rows}],
        )
    except RuntimeError as exc:
        assert 'profile 1 retained duplicate' in str(exc)
    else:
        raise AssertionError('Per-profile duplicate gate did not reject a duplicate')
finally:
    runtime_gate.gate.request_json = original_runtime_request

print(
    'AUTHORITATIVE SETTINGS PREFLIGHT PASS: '
    '33 unique rows across 3 users; other profiles preserved'
)
PY

[[ -f "$BUNDLE" && -f "$BUNDLE.sha256" ]] || fail 'Passed bundle/checksum is missing.'
sha256sum -c "$BUNDLE.sha256"
VERIFY="$(mktemp -d)"
tar -xzf "$BUNDLE" -C "$VERIFY"
MANIFEST="$VERIFY/homelab-build-manifest.json"
[[ -f "$MANIFEST" ]] || fail 'Bundle manifest is missing.'
grep -Fq '"design": "web-desktop-v2-candidate"' "$MANIFEST" || fail 'Design marker mismatch.'
grep -Fq "\"sourceCommit\": \"$PRODUCT_COMMIT\"" "$MANIFEST" || fail 'Bundle/source mismatch.'
grep -Fq '"theme": "home_lab_streaming"' "$MANIFEST" || fail 'Theme marker mismatch.'
echo "BUILD/BUNDLE REUSED + PASS: $PRODUCT_COMMIT"

echo
echo '=== 2. CONFIRM APPROVED LIVE BASELINE ==='
LIVE_BEFORE="$(curl -fsS "$BASE/Moonfin/Web/homelab-build-manifest.json")"
grep -Fq "\"sourceCommit\": \"$LIVE_BASELINE\"" <<<"$LIVE_BEFORE" ||
  fail 'Live frontend is not the approved baseline.'
echo "LIVE BASELINE PASS: $LIVE_BASELINE"

echo
echo '=== 3. LOCATE PLUGIN AND CREATE ROLLBACK ==='
for candidate in "$PLUGIN_ROOT"/Moonbase_* "$PLUGIN_ROOT"/Moonfin*; do
  if [[ -d "$candidate" && -f "$candidate/Moonfin.Server.dll" ]]; then
    PLUGIN_DIR="$candidate"
  fi
done
[[ -n "$PLUGIN_DIR" ]] || fail 'Moonbase/Moonfin plugin directory not found.'
FRONTEND="$PLUGIN_DIR/frontend"
[[ -f "$FRONTEND/index.html" ]] || fail 'Current frontend is incomplete.'
sudo -n mkdir -p "$RUN"
sudo -n chmod 700 "$RUN"
OLD_FRONTEND="$RUN/frontend-before-web-refinement"

echo
echo '=== 4. APPLY AUTHORITATIVE BACKED-UP MOONBASE CONFIG ==='
sudo -n env PYTHONPATH="$SRC/tooling" \
  python3 tooling/home_lab_web_refinement_config.py \
  apply \
  --backup-dir "$RUN/moonbase" \
  --theme tooling/themes/home_lab_streaming.json \
  --preview-themes-dir tooling/themes/options
CONFIG_APPLIED=1
echo 'MOONBASE CONFIG APPLY PASS'

echo
echo '=== 5. RUNTIME, DENSITY AND PERSONALISATION GATES ==='
sudo -n env PYTHONPATH="$SRC/tooling" python3 tooling/home_lab_v2_runtime_gate.py
sudo -n env PYTHONPATH="$SRC/tooling" python3 tooling/home_lab_v2_personal_gate_all_users.py
echo 'ALL PRE-DEPLOY RUNTIME GATES PASS'

echo
echo '=== 6. DEPLOY EXACT ALREADY-BUILT BUNDLE ==='
STAGE="$PLUGIN_DIR/.frontend-web-refinement-$STAMP"
sudo -n mkdir -p "$STAGE"
sudo -n tar -xzf "$BUNDLE" -C "$STAGE"
OWNER="$(stat -c '%u:%g' "$FRONTEND")"
sudo -n chown -R "$OWNER" "$STAGE"

"${D[@]}" stop jellyfin >/dev/null
JELLYFIN_STOPPED=1
sudo -n mv "$FRONTEND" "$OLD_FRONTEND"
OLD_SAVED=1
sudo -n mv "$STAGE" "$FRONTEND"
STAGE=''
"${D[@]}" start jellyfin >/dev/null
JELLYFIN_STOPPED=0
wait_for_moonfin || fail 'Jellyfin did not return after deployment.'

LIVE=''
for _ in $(seq 1 40); do
  LIVE="$(curl -fsS "$BASE/Moonfin/Web/homelab-build-manifest.json" 2>/dev/null || true)"
  grep -Fq "\"sourceCommit\": \"$PRODUCT_COMMIT\"" <<<"$LIVE" && break
  sleep 2
done
grep -Fq '"design": "web-desktop-v2-candidate"' <<<"$LIVE" || fail 'Live design marker mismatch.'
grep -Fq "\"sourceCommit\": \"$PRODUCT_COMMIT\"" <<<"$LIVE" || fail 'Live commit mismatch.'
grep -Fq '"theme": "home_lab_streaming"' <<<"$LIVE" || fail 'Live theme marker mismatch.'
echo "$LIVE"
echo 'LIVE MANIFEST PASS'

echo
echo '=== 7. PROMOTE EXACT VALIDATED PRODUCT ==='
git push origin "${PRODUCT_COMMIT}:refs/heads/${MAIN_BRANCH}"

CONFIG_APPLIED=0
OLD_SAVED=0
trap - EXIT
rm -rf "$VERIFY"
VERIFY=''

echo
echo '=================================================='
echo ' HOME LAB WEB REFINEMENT V1 VALIDATION PASS'
echo '=================================================='
echo "Product commit: $PRODUCT_COMMIT"
echo "Validation tooling: $(git rev-parse HEAD)"
echo "Bundle: $BUNDLE"
echo "Rollback/config backup: $RUN"
echo 'Build/bundle: REUSED + PASS'
echo 'Moonbase rows: 33 UNIQUE + PASS'
echo 'Home Movie/Series recommendation mix: PASS'
echo 'Movies low-duplication editorial config: PASS'
echo 'TV destination isolation and discovery: PASS'
echo 'Anime Crunchyroll-style config/discovery and safety: PASS'
echo 'Backdrop blur and hero transition: PASS'
echo 'Live manifest: PASS'
echo 'Git promotion: PASS'
