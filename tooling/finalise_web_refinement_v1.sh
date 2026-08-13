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

STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="$BACKUP_ROOT/web-refinement-v1-$STAMP"
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
    echo '=== WEB REFINEMENT FAILED: AUTOMATIC RESTORE ==='

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

echo '=== 1. VERIFY EXACT STAGING SOURCE ==='
[[ "$(git branch --show-current)" == "$STAGING_BRANCH" ]] || fail 'Wrong staging branch.'
[[ -z "$(git status --porcelain)" ]] || fail 'Source tree is dirty.'
git fetch origin \
  "$STAGING_BRANCH:refs/remotes/origin/$STAGING_BRANCH" \
  "$MAIN_BRANCH:refs/remotes/origin/$MAIN_BRANCH"
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/$STAGING_BRANCH)" ]] ||
  fail 'Local staging is not the exact remote staging commit.'
[[ "$(git rev-parse origin/$MAIN_BRANCH)" == "$LIVE_BASELINE" ]] ||
  fail 'Product branch changed unexpectedly.'
git merge-base --is-ancestor "$LIVE_BASELINE" HEAD ||
  fail 'The approved live product is not an ancestor of this refinement.'

python3 -m py_compile \
  tooling/home_lab_safe_auth.py \
  tooling/home_lab_seerr_auth.py \
  tooling/home_lab_v2_moonbase.py \
  tooling/home_lab_web_refinement_config.py \
  tooling/home_lab_v2_runtime_gate.py \
  tooling/home_lab_v2_personal_gate_all_users.py

PYTHONPATH="$SRC/tooling" python3 - <<'PY'
import home_lab_web_refinement_config as moonbase

rows = moonbase.editorial_custom_rows()
destinations = {'movies': 0, 'tv': 0, 'anime': 0}
for row in rows:
    metadata = __import__('json').loads(row['pluginAdditionalData'])
    for destination in metadata['homelab_destinations']:
        destinations[destination] += 1
assert len(rows) == 33, len(rows)
assert destinations == {'movies': 9, 'tv': 10, 'anime': 14}, destinations
print('LOCAL PREFLIGHT PASS: 33 targeted custom rows', destinations)
PY

echo
echo '=== 2. FORMAT CANDIDATE SOURCE (NO BUILD) ==='
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
"${D[@]}" run --rm \
  --user "$HOST_UID:$HOST_GID" \
  -e HOME=/home/builder \
  -e PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -v "$SRC:/workspace" \
  -w /workspace \
  homelab-flutter:3.44.1 dart format \
    lib/data/services/row_data_source.dart \
    lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart \
    lib/ui/widgets/media_bar.dart

git diff --check
mapfile -t FORMATTED < <(git diff --name-only)
if (( ${#FORMATTED[@]} )); then
  for path in "${FORMATTED[@]}"; do
    case "$path" in
      lib/data/services/row_data_source.dart|\
      lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart|\
      lib/ui/widgets/media_bar.dart) ;;
      *) fail "Formatter changed unexpected file: $path" ;;
    esac
  done
  git add -- "${FORMATTED[@]}"
  git commit -m 'Format Home Lab web refinement v1 source'
  git push origin HEAD:"$STAGING_BRANCH"
else
  echo 'Source already formatted.'
fi
[[ -z "$(git status --porcelain)" ]] || fail 'Source is dirty after formatting.'

PRODUCT_COMMIT="$(git rev-parse HEAD)"
echo "Candidate: $PRODUCT_COMMIT"

echo
echo '=== 3. ONE COMMITTED-SOURCE WEB BUILD (30 MIN MAX) ==='
timeout --signal=TERM --kill-after=30s 30m \
  bash tooling/build_web_desktop_v2.sh final
[[ -z "$(git status --porcelain)" ]] || fail 'Build changed committed source.'

BUNDLE="$(cat "$DEV/state/web-desktop-v2-latest-bundle")"
[[ -f "$BUNDLE" && -f "$BUNDLE.sha256" ]] || fail 'Bundle/checksum missing.'
sha256sum -c "$BUNDLE.sha256"

VERIFY="$(mktemp -d)"
tar -xzf "$BUNDLE" -C "$VERIFY"
MANIFEST="$VERIFY/homelab-build-manifest.json"
[[ -f "$MANIFEST" ]] || fail 'Bundle manifest missing.'
grep -Fq '"design": "web-desktop-v2-candidate"' "$MANIFEST" || fail 'Design marker mismatch.'
grep -Fq "\"sourceCommit\": \"$PRODUCT_COMMIT\"" "$MANIFEST" || fail 'Bundle/source mismatch.'
grep -Fq '"theme": "home_lab_streaming"' "$MANIFEST" || fail 'Theme marker mismatch.'
echo "BUILD/BUNDLE PASS: $PRODUCT_COMMIT"

echo
echo '=== 4. CONFIRM APPROVED LIVE BASELINE ==='
LIVE_BEFORE="$(curl -fsS "$BASE/Moonfin/Web/homelab-build-manifest.json")"
grep -Fq "\"sourceCommit\": \"$LIVE_BASELINE\"" <<<"$LIVE_BEFORE" ||
  fail 'Live frontend is not the approved c7537d87 baseline.'
echo "LIVE BASELINE PASS: $LIVE_BASELINE"

echo
echo '=== 5. LOCATE PLUGIN AND CREATE ROLLBACK ==='
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
echo '=== 6. APPLY BACKED-UP MOONBASE CONTENT CONFIG ==='
sudo -n env PYTHONPATH="$SRC/tooling" \
  python3 tooling/home_lab_web_refinement_config.py \
  apply \
  --backup-dir "$RUN/moonbase" \
  --theme tooling/themes/home_lab_streaming.json \
  --preview-themes-dir tooling/themes/options
CONFIG_APPLIED=1
echo 'MOONBASE CONFIG APPLY PASS'

echo
echo '=== 7. RUNTIME, DENSITY AND PERSONALISATION GATES ==='
sudo -n env PYTHONPATH="$SRC/tooling" python3 tooling/home_lab_v2_runtime_gate.py
sudo -n env PYTHONPATH="$SRC/tooling" python3 tooling/home_lab_v2_personal_gate_all_users.py
echo 'ALL PRE-DEPLOY RUNTIME GATES PASS'

echo
echo '=== 8. DEPLOY EXACT VALIDATED BUNDLE ==='
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
echo '=== 9. PROMOTE EXACT VALIDATED SOURCE ==='
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
echo "Bundle: $BUNDLE"
echo "Rollback/config backup: $RUN"
echo 'Home Movie/Series recommendation mix: PASS'
echo 'Movies low-duplication editorial mix: PASS'
echo 'TV destination isolation and density: PASS'
echo 'Anime Crunchyroll-style density and safety: PASS'
echo 'Backdrop blur and hero transition: PASS'
echo 'Live manifest: PASS'
echo 'Git promotion: PASS'
