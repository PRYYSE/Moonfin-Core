#!/usr/bin/env bash
set -Eeuo pipefail

SRC=/opt/src/moonfin-core
DEV=/opt/src/moonfin-dev
PLUGIN_ROOT=/srv/appdata/jellyfin/data/plugins
BACKUP_ROOT=/srv/appdata/jellyfin/backups
BASE=http://127.0.0.1:8096

STAGING_BRANCH=homelab/content-personalisation-v1-staging
MAIN_BRANCH=homelab/hubs-v1
BASELINE_COMMIT=dfaf5401e2bbeb90ccabefc79f69dc7817d2489f
PRODUCT_COMMIT=c7537d8784d34571c6a7ecc3a10f911066fb3263
BUNDLE=/opt/src/moonfin-dev/output/homelab-moonfin-web-v2-20260813-093735.tar.gz

STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="$BACKUP_ROOT/content-personalisation-v1-final-$STAMP"
VERIFY="$(mktemp -d)"

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
  for _ in $(seq 1 40); do
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
  rm -rf "$VERIFY"

  if [[ $rc -ne 0 ]]; then
    echo
    echo '=== FINALISATION FAILED: AUTOMATIC RESTORE ==='

    if [[ "$OLD_SAVED" == 1 ]] && sudo -n test -d "$OLD_FRONTEND"; then
      "${D[@]}" stop jellyfin >/dev/null 2>&1 || true

      if sudo -n test -d "$FRONTEND"; then
        sudo -n mv \
          "$FRONTEND" \
          "$RUN/failed-candidate-frontend" 2>/dev/null || true
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
      echo 'Previous Moonbase theme/settings restored.'
    fi

    [[ -z "$STAGE" ]] || sudo -n rm -rf "$STAGE"
    echo "Rollback data: $RUN"
  fi

  exit "$rc"
}
trap restore_on_failure EXIT

cd "$SRC"

echo '=== 1. VERIFY SOURCE, PRODUCT AND BUNDLE ==='
[[ "$(git branch --show-current)" == "$STAGING_BRANCH" ]] ||
  fail 'Wrong staging branch.'
[[ -z "$(git status --porcelain)" ]] ||
  fail 'Source tree is dirty.'

git merge-base --is-ancestor "$PRODUCT_COMMIT" HEAD ||
  fail 'Validated product commit is not in staging history.'

grep -qx \
  "DEFAULT_DB = Path('/srv/appdata/jellyfin/data/data/jellyfin.db')" \
  tooling/home_lab_safe_auth.py ||
  fail 'Confirmed Jellyfin database path is missing.'

git fetch origin "$MAIN_BRANCH:refs/remotes/origin/$MAIN_BRANCH"
[[ "$(git rev-parse "origin/$MAIN_BRANCH")" == "$BASELINE_COMMIT" ]] ||
  fail 'Product branch changed unexpectedly.'

[[ -f "$BUNDLE" && -f "$BUNDLE.sha256" ]] ||
  fail 'Validated bundle or checksum is missing.'
sha256sum -c "$BUNDLE.sha256"

tar -xzf "$BUNDLE" -C "$VERIFY"
MANIFEST="$VERIFY/homelab-build-manifest.json"
[[ -f "$MANIFEST" ]] || fail 'Bundle manifest is missing.'

grep -Fq '"design": "web-desktop-v2-candidate"' "$MANIFEST" ||
  fail 'Bundle design marker mismatch.'
grep -Fq "\"sourceCommit\": \"$PRODUCT_COMMIT\"" "$MANIFEST" ||
  fail 'Bundle product commit mismatch.'
grep -Fq '"theme": "home_lab_streaming"' "$MANIFEST" ||
  fail 'Bundle theme marker mismatch.'

echo "BUNDLE REUSED + PASS: $PRODUCT_COMMIT"

echo
echo '=== 2. VERIFY APPROVED LIVE BASELINE ==='
LIVE_BEFORE="$(curl -fsS "$BASE/Moonfin/Web/homelab-build-manifest.json")"

grep -Fq "\"sourceCommit\": \"$BASELINE_COMMIT\"" <<<"$LIVE_BEFORE" ||
  fail 'Live frontend is not the approved dfaf5401 baseline.'
grep -Fq '"design": "web-desktop-v2-candidate"' <<<"$LIVE_BEFORE" ||
  fail 'Live baseline design marker mismatch.'

echo "LIVE BASELINE PASS: $BASELINE_COMMIT"

echo
echo '=== 3. LOCATE PLUGIN AND CREATE ROLLBACK ==='
for candidate in "$PLUGIN_ROOT"/Moonbase_* "$PLUGIN_ROOT"/Moonfin*; do
  if [[ -d "$candidate" && -f "$candidate/Moonfin.Server.dll" ]]; then
    PLUGIN_DIR="$candidate"
  fi
done

[[ -n "$PLUGIN_DIR" ]] ||
  fail 'Moonbase/Moonfin plugin directory not found.'

FRONTEND="$PLUGIN_DIR/frontend"
[[ -f "$FRONTEND/index.html" ]] ||
  fail 'Current frontend is incomplete.'

sudo -n mkdir -p "$RUN"
sudo -n chmod 700 "$RUN"
OLD_FRONTEND="$RUN/frontend-before-content-personalisation"

echo
echo '=== 4. BACK UP AND APPLY APPROVED MOONBASE CONFIG ==='
python3 -m py_compile \
  tooling/home_lab_safe_auth.py \
  tooling/home_lab_seerr_auth.py \
  tooling/home_lab_v2_moonbase.py \
  tooling/home_lab_v2_runtime_gate.py \
  tooling/home_lab_v2_personal_gate_all_users.py

sudo -n env PYTHONPATH="$SRC/tooling" \
  python3 tooling/home_lab_v2_moonbase.py \
  apply \
  --backup-dir "$RUN/moonbase" \
  --theme tooling/themes/home_lab_streaming.json \
  --preview-themes-dir tooling/themes/options

CONFIG_APPLIED=1
echo 'MOONBASE CONFIG APPLY PASS'

echo
echo '=== 5. RUNTIME AND PERSONALISATION GATES ==='
sudo -n env PYTHONPATH="$SRC/tooling" \
  python3 tooling/home_lab_v2_runtime_gate.py

sudo -n env PYTHONPATH="$SRC/tooling" \
  python3 tooling/home_lab_v2_personal_gate_all_users.py

echo 'RUNTIME/PERSONALISATION GATES PASS'

echo
echo '=== 6. DEPLOY EXACT VALIDATED PRODUCT BUNDLE ==='
STAGE="$PLUGIN_DIR/.frontend-content-personalisation-$STAMP"
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

wait_for_moonfin ||
  fail 'Jellyfin did not return after deployment.'

LIVE=''
for _ in $(seq 1 40); do
  LIVE="$(
    curl -fsS \
      "$BASE/Moonfin/Web/homelab-build-manifest.json" 2>/dev/null ||
      true
  )"

  grep -Fq "\"sourceCommit\": \"$PRODUCT_COMMIT\"" <<<"$LIVE" && break
  sleep 2
done

grep -Fq '"design": "web-desktop-v2-candidate"' <<<"$LIVE" ||
  fail 'Live design marker mismatch.'
grep -Fq "\"sourceCommit\": \"$PRODUCT_COMMIT\"" <<<"$LIVE" ||
  fail 'Live product commit mismatch.'
grep -Fq '"theme": "home_lab_streaming"' <<<"$LIVE" ||
  fail 'Live theme marker mismatch.'

echo "$LIVE"
echo 'LIVE MANIFEST PASS'

echo
echo '=== 7. PROMOTE EXACT VALIDATED PRODUCT COMMIT ==='
git push origin "${PRODUCT_COMMIT}:refs/heads/${MAIN_BRANCH}"

trap - EXIT
rm -rf "$VERIFY"

echo
echo '=================================================='
echo ' CONTENT + PERSONALISATION V1 VALIDATION PASS'
echo '=================================================='
echo "Product commit: $PRODUCT_COMMIT"
echo "Validation tooling: $(git rev-parse HEAD)"
echo "Bundle: $BUNDLE"
echo "Rollback/config backup: $RUN"
echo 'Build/bundle: REUSED + PASS'
echo 'Moonbase theme/config: APPLY + PASS'
echo 'Six Moonfin preview themes: UPLOADED + PASS'
echo 'Movies/TV/Anime runtime data: PASS'
echo 'Cold-start personalisation: PASS'
echo 'Live manifest: PASS'
echo 'Git promotion: PASS'
