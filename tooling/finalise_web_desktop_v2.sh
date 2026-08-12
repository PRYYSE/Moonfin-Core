#!/usr/bin/env bash
set -Eeuo pipefail

SRC=/opt/src/moonfin-core
DEV=/opt/src/moonfin-dev
IMAGE=homelab-flutter:3.44.1
STAGING_BRANCH=homelab/content-personalisation-v1-staging
MAIN_BRANCH=homelab/hubs-v1
BASE='http://127.0.0.1:8096'
PLUGIN_ROOT=/srv/appdata/jellyfin/data/plugins
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="/srv/appdata/jellyfin/backups/web-desktop-v2-final-$STAMP"
LOG="$DEV/logs/web-desktop-v2-finalise-$STAMP.log"

mkdir -p "$DEV/logs" "$DEV/pub-cache"
exec > >(tee -a "$LOG") 2>&1

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

cd "$SRC"

if docker info >/dev/null 2>&1; then
  D=(docker)
else
  D=(sudo docker)
fi

FORMAT_PATHS=(
  lib/data/services/row_data_source.dart
  lib/ui/screens/home/home_screen.dart
  lib/ui/screens/home/home_view_model.dart
  lib/ui/screens/home/homelab_home_composer.dart
  lib/ui/screens/hubs/homelab_hub_screen.dart
  lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart
  lib/ui/widgets/media_bar.dart
)

printf '=== 1. RECONCILE EXACT STAGING SOURCE ===\n'
[[ -z "$(git status --porcelain)" ]] || {
  git status --short
  fail 'Source tree is dirty before finalisation; no files were changed.'
}

git fetch origin "$STAGING_BRANCH:refs/remotes/origin/$STAGING_BRANCH"
git checkout -B "$STAGING_BRANCH" "origin/$STAGING_BRANCH"
echo "Staging: $(git rev-parse HEAD)"

printf '\n=== 2. PREPARE FORMATTER DEPENDENCIES ===\n'
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

"${D[@]}" run --rm \
  --user "$HOST_UID:$HOST_GID" \
  -e HOME=/home/builder \
  -e PUB_CACHE=/home/builder/.pub-cache \
  -e PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -v "$SRC:/workspace" \
  -v "$DEV/pub-cache:/home/builder/.pub-cache" \
  -w /workspace \
  "$IMAGE" flutter pub get

printf '\n=== 3. FORMAT SOURCE ONLY (NO BUILD) ===\n'
"${D[@]}" run --rm \
  --user "$HOST_UID:$HOST_GID" \
  -e HOME=/home/builder \
  -e PUB_CACHE=/home/builder/.pub-cache \
  -e PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -v "$SRC:/workspace" \
  -v "$DEV/pub-cache:/home/builder/.pub-cache" \
  -w /workspace \
  "$IMAGE" dart format "${FORMAT_PATHS[@]}"

git diff --check

mapfile -t CHANGED < <(git diff --name-only)
if (( ${#CHANGED[@]} )); then
  for path in "${CHANGED[@]}"; do
    allowed=0
    for expected in "${FORMAT_PATHS[@]}"; do
      [[ "$path" == "$expected" ]] && allowed=1 && break
    done
    [[ "$allowed" == 1 ]] || fail "Unexpected source change before build: $path"
  done

  echo 'Formatter changes:'
  printf '  %s\n' "${CHANGED[@]}"
  git add -- "${CHANGED[@]}"
  git commit -m 'Format Home Lab web desktop v2 final source'
  git push origin HEAD:"$STAGING_BRANCH"
else
  echo 'Source already formatted.'
fi

[[ -z "$(git status --porcelain)" ]] || fail 'Source is not clean after formatting commit.'
COMMIT="$(git rev-parse HEAD)"
echo "Build commit: $COMMIT"

printf '\n=== 4. FINAL COMMITTED-SOURCE BUILD ===\n'
timeout --signal=TERM --kill-after=30s 30m \
  bash "$SRC/tooling/build_web_desktop_v2.sh" final

[[ -z "$(git status --porcelain)" ]] || {
  git status --short
  fail 'Final build changed committed source.'
}

BUNDLE="$(cat "$DEV/state/web-desktop-v2-latest-bundle")"
[[ -f "$BUNDLE" && -f "$BUNDLE.sha256" ]] || fail 'Final bundle/checksum missing.'
sha256sum -c "$BUNDLE.sha256"

VERIFY="$(mktemp -d)"
trap 'rm -rf "$VERIFY"' EXIT
tar -xzf "$BUNDLE" -C "$VERIFY"
MANIFEST="$VERIFY/homelab-build-manifest.json"
[[ -f "$MANIFEST" ]] || fail 'Bundle manifest missing.'
grep -Fq '"design": "web-desktop-v2-candidate"' "$MANIFEST" || fail 'Wrong design marker.'
grep -Fq "\"sourceCommit\": \"$COMMIT\"" "$MANIFEST" || fail 'Bundle/source commit mismatch.'
grep -Fq '"theme": "home_lab_streaming"' "$MANIFEST" || fail 'Theme marker missing.'

echo "BUILD/BUNDLE PASS: $COMMIT"

printf '\n=== 5. LOCATE LIVE PLUGIN + CREATE ROLLBACK ===\n'
PLUGIN_DIR=''
for candidate in "$PLUGIN_ROOT"/Moonbase_* "$PLUGIN_ROOT"/Moonfin*; do
  if [[ -d "$candidate" && -f "$candidate/Moonfin.Server.dll" ]]; then
    PLUGIN_DIR="$candidate"
  fi
done
[[ -n "$PLUGIN_DIR" ]] || fail 'Moonbase/Moonfin plugin directory not found.'
FRONTEND="$PLUGIN_DIR/frontend"
[[ -f "$FRONTEND/index.html" ]] || fail "Live frontend missing: $FRONTEND"

sudo mkdir -p "$RUN"
sudo chown "$(id -u):$(id -g)" "$RUN"
chmod 700 "$RUN"
CONFIG_APPLIED=0
DEPLOYED=0
OLD_FRONTEND="$RUN/frontend-before-final"

restore_transaction() {
  rc=$?
  trap - EXIT
  set +e
  rm -rf "$VERIFY"
  if [[ $rc -ne 0 ]]; then
    echo
    echo '=== FINALISATION FAILED: AUTOMATIC RESTORE ==='
    if [[ "$DEPLOYED" == 1 ]] && sudo test -d "$OLD_FRONTEND"; then
      "${D[@]}" stop jellyfin >/dev/null 2>&1 || true
      if sudo test -d "$FRONTEND"; then
        sudo mv "$FRONTEND" "$RUN/failed-final-frontend" 2>/dev/null || sudo rm -rf "$FRONTEND"
      fi
      sudo mv "$OLD_FRONTEND" "$FRONTEND" 2>/dev/null || true
      "${D[@]}" start jellyfin >/dev/null 2>&1 || true
      echo 'Previous frontend restored.'
    fi
    echo "Failure log: $LOG"
    echo "Rollback data: $RUN"
  fi
  exit "$rc"
}
trap restore_transaction EXIT

printf '\n=== 6. VERIFY EXISTING CONFIG + SERVER DATA GATES ===\n'
python3 -m py_compile \
  "$SRC/tooling/home_lab_safe_auth.py" \
  "$SRC/tooling/home_lab_v2_moonbase.py" \
  "$SRC/tooling/home_lab_v2_runtime_gate.py" \
  "$SRC/tooling/home_lab_v2_personal_gate_all_users.py"

sudo env PYTHONPATH="$SRC/tooling" \
  python3 "$SRC/tooling/home_lab_v2_runtime_gate.py"

sudo env PYTHONPATH="$SRC/tooling" \
  python3 "$SRC/tooling/home_lab_v2_personal_gate_all_users.py"

printf '\n=== 7. DEPLOY EXACT VALIDATED BUILD ===\n'
STAGE="$PLUGIN_DIR/.frontend-v2-final-$STAMP"
OWNER="$(stat -c '%u:%g' "$FRONTEND")"
sudo rm -rf "$STAGE"
sudo mkdir -p "$STAGE"
sudo tar -xzf "$BUNDLE" -C "$STAGE"
sudo chown -R "$OWNER" "$STAGE"

"${D[@]}" stop jellyfin >/dev/null
sudo mv "$FRONTEND" "$OLD_FRONTEND"
DEPLOYED=1
sudo mv "$STAGE" "$FRONTEND"
"${D[@]}" start jellyfin >/dev/null

LIVE=''
for _ in $(seq 1 40); do
  LIVE="$(curl -fsS "$BASE/Moonfin/Web/homelab-build-manifest.json" 2>/dev/null || true)"
  if grep -Fq "\"sourceCommit\": \"$COMMIT\"" <<<"$LIVE"; then
    break
  fi
  sleep 2
done

[[ -n "$LIVE" ]] || fail 'Moonfin did not return a live manifest after deployment.'
grep -Fq '"design": "web-desktop-v2-candidate"' <<<"$LIVE" || fail 'Live design marker mismatch.'
grep -Fq "\"sourceCommit\": \"$COMMIT\"" <<<"$LIVE" || fail 'Live source commit mismatch.'
grep -Fq '"theme": "home_lab_streaming"' <<<"$LIVE" || fail 'Live theme marker mismatch.'
echo "$LIVE"

printf '\n=== 8. PROMOTE EXACT VALIDATED SOURCE ===\n'
git push origin HEAD:"$MAIN_BRANCH"
git checkout -B "$MAIN_BRANCH" HEAD
git branch --set-upstream-to="origin/$MAIN_BRANCH" "$MAIN_BRANCH" >/dev/null 2>&1 || true

CONFIG_APPLIED=0
DEPLOYED=0
trap - EXIT
rm -rf "$VERIFY"

echo
echo '=================================================='
echo ' HOME LAB WEB-DESKTOP V2 VALIDATION PASS'
echo '=================================================='
echo "Commit: $COMMIT"
echo "Bundle: $BUNDLE"
echo "Backup: $RUN"
echo "Log: $LOG"
echo 'Home Lab theme/config: PASS'
echo 'Movies/TV/Anime expanded runtime data gate: PASS'
echo 'Personal recommendation cold-start gate: PASS'
echo 'Live manifest: PASS'
