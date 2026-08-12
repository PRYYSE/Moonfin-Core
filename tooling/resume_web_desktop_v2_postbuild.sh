#!/usr/bin/env bash
set -Eeuo pipefail

SRC=/opt/src/moonfin-core
DEV=/opt/src/moonfin-dev
BASE='http://127.0.0.1:8096'
PLUGIN_ROOT=/srv/appdata/jellyfin/data/plugins
MAIN_BRANCH=homelab/hubs-v1
BUILD_COMMIT=dfaf5401e2bbeb90ccabefc79f69dc7817d2489f
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="/srv/appdata/jellyfin/backups/web-desktop-v2-postbuild-$STAMP"
LOG="$DEV/logs/web-desktop-v2-postbuild-$STAMP.log"

mkdir -p "$DEV/logs"
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

SUDO_KEEPALIVE_PID=''
CONFIG_APPLIED=0
DEPLOYED=0
PLUGIN_DIR=''
FRONTEND=''
OLD_FRONTEND=''

stop_keepalive() {
  if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
    kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
    wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    SUDO_KEEPALIVE_PID=''
  fi
}

rollback() {
  rc=$?
  trap - EXIT INT TERM
  set +e
  stop_keepalive

  if [[ $rc -ne 0 ]]; then
    echo
    echo '=== POST-BUILD RESUME FAILED: AUTOMATIC RESTORE ==='

    if [[ "$DEPLOYED" == 1 && -n "$OLD_FRONTEND" ]] && sudo -n test -d "$OLD_FRONTEND"; then
      "${D[@]}" stop jellyfin >/dev/null 2>&1 || true
      if [[ -n "$FRONTEND" ]] && sudo -n test -d "$FRONTEND"; then
        sudo -n mv "$FRONTEND" "$RUN/failed-v2-frontend" 2>/dev/null || sudo -n rm -rf "$FRONTEND"
      fi
      sudo -n mv "$OLD_FRONTEND" "$FRONTEND" 2>/dev/null || true
      "${D[@]}" start jellyfin >/dev/null 2>&1 || true
      echo 'Previous frontend restored.'
    fi

    if [[ "$CONFIG_APPLIED" == 1 ]]; then
      sudo -n env PYTHONPATH="$SRC/tooling" \
        python3 "$SRC/tooling/home_lab_v2_moonbase.py" \
        restore --backup-dir "$RUN/moonbase" >/dev/null 2>&1 || true
      echo 'Previous Moonbase configuration restored.'
    fi

    echo "Failure log: $LOG"
    echo "Rollback data: $RUN"
  fi

  exit "$rc"
}
trap rollback EXIT INT TERM

echo '=== 1. VERIFY ALREADY-SUCCESSFUL BUILD ==='

[[ -z "$(git status --porcelain)" ]] || {
  git status --short
  fail 'Source tree is dirty. No changes made.'
}

CURRENT="$(git rev-parse HEAD)"
[[ "$CURRENT" == "$BUILD_COMMIT" ]] || \
  fail "Local source is $CURRENT; expected already-built commit $BUILD_COMMIT."

git cat-file -e "$BUILD_COMMIT^{commit}" || fail 'Built commit is missing locally.'

BUNDLE="$(cat "$DEV/state/web-desktop-v2-latest-bundle" 2>/dev/null || true)"
[[ -n "$BUNDLE" && -f "$BUNDLE" && -f "$BUNDLE.sha256" ]] || \
  fail 'Latest v2 bundle/checksum is missing.'
sha256sum -c "$BUNDLE.sha256"

MANIFEST="$(tar -xOf "$BUNDLE" ./homelab-build-manifest.json 2>/dev/null || tar -xOf "$BUNDLE" homelab-build-manifest.json)"
grep -Fq '"design": "web-desktop-v2-candidate"' <<<"$MANIFEST" || fail 'Bundle design marker is wrong.'
grep -Fq "\"sourceCommit\": \"$BUILD_COMMIT\"" <<<"$MANIFEST" || fail 'Bundle is not the successful dfaf5401 build.'
grep -Fq '"theme": "home_lab_streaming"' <<<"$MANIFEST" || fail 'Bundle theme marker is missing.'

echo "BUILD/BUNDLE REUSED: $BUILD_COMMIT"
echo "Bundle: $BUNDLE"

echo
echo '=== 2. VERIFY SUDO SESSION ==='
if ! sudo -n true 2>/dev/null; then
  fail 'sudo is not pre-authorised. Run this resume with `sudo -v && ...` as supplied.'
fi

(
  while sleep 60; do
    sudo -n true >/dev/null 2>&1 || exit 0
  done
) &
SUDO_KEEPALIVE_PID=$!

echo 'sudo: cached and keepalive active.'

echo
echo '=== 3. LOCATE LIVE PLUGIN + CREATE ROLLBACK ==='
mapfile -t PLUGINS < <(
  for candidate in "$PLUGIN_ROOT"/Moonbase_* "$PLUGIN_ROOT"/Moonfin*; do
    [[ -d "$candidate" && -f "$candidate/Moonfin.Server.dll" ]] && printf '%s\n' "$candidate"
  done | sort -u
)

(( ${#PLUGINS[@]} == 1 )) || {
  printf 'Candidates found:\n'
  printf '  %s\n' "${PLUGINS[@]:-none}"
  fail "Expected exactly one Moonbase/Moonfin plugin directory; found ${#PLUGINS[@]}."
}

PLUGIN_DIR="${PLUGINS[0]}"
FRONTEND="$PLUGIN_DIR/frontend"
[[ -f "$FRONTEND/index.html" ]] || fail "Live frontend missing: $FRONTEND"

echo "Plugin: $PLUGIN_DIR"
echo 'Current live manifest:'
curl -fsS "$BASE/Moonfin/Web/homelab-build-manifest.json" || true

sudo -n mkdir -p "$RUN"
sudo -n chown "$(id -u):$(id -g)" "$RUN"
chmod 700 "$RUN"
OLD_FRONTEND="$RUN/frontend-before-v2"

echo
echo '=== 4. APPLY HOME LAB THEME/DESKTOP CONFIG ==='
python3 -m py_compile \
  "$SRC/tooling/home_lab_v2_moonbase.py" \
  "$SRC/tooling/home_lab_v2_runtime_gate.py" \
  "$SRC/tooling/home_lab_v2_personal_gate_all_users.py"

sudo -n env PYTHONPATH="$SRC/tooling" \
  python3 "$SRC/tooling/home_lab_v2_moonbase.py" apply \
  --backup-dir "$RUN/moonbase" \
  --theme "$SRC/tooling/themes/home_lab_streaming.json"
CONFIG_APPLIED=1

echo
echo '=== 5. MOVIES / TV / ANIME RUNTIME GATE ==='
sudo -n env PYTHONPATH="$SRC/tooling" \
  python3 "$SRC/tooling/home_lab_v2_runtime_gate.py"

echo
echo '=== 6. PERSONAL RECOMMENDATION GATE ==='
sudo -n env PYTHONPATH="$SRC/tooling" \
  python3 "$SRC/tooling/home_lab_v2_personal_gate_all_users.py"

echo
echo '=== 7. DEPLOY ALREADY-VALIDATED BUILD ==='
STAGE="$PLUGIN_DIR/.frontend-v2-postbuild-$STAMP"
OWNER="$(stat -c '%u:%g' "$FRONTEND")"
sudo -n rm -rf "$STAGE"
sudo -n mkdir -p "$STAGE"
sudo -n tar -xzf "$BUNDLE" -C "$STAGE"
sudo -n chown -R "$OWNER" "$STAGE"

"${D[@]}" stop jellyfin >/dev/null
sudo -n mv "$FRONTEND" "$OLD_FRONTEND"
DEPLOYED=1
sudo -n mv "$STAGE" "$FRONTEND"
"${D[@]}" start jellyfin >/dev/null

LIVE=''
for _ in $(seq 1 40); do
  LIVE="$(curl -fsS "$BASE/Moonfin/Web/homelab-build-manifest.json" 2>/dev/null || true)"
  if grep -Fq "\"sourceCommit\": \"$BUILD_COMMIT\"" <<<"$LIVE"; then
    break
  fi
  sleep 2
done

[[ -n "$LIVE" ]] || fail 'Moonfin did not return a live manifest after deployment.'
grep -Fq '"design": "web-desktop-v2-candidate"' <<<"$LIVE" || fail 'Live design marker mismatch.'
grep -Fq "\"sourceCommit\": \"$BUILD_COMMIT\"" <<<"$LIVE" || fail 'Live source commit mismatch.'
grep -Fq '"theme": "home_lab_streaming"' <<<"$LIVE" || fail 'Live theme marker mismatch.'

echo "$LIVE"
echo 'LIVE V2 MANIFEST PASS'

# Product validation is complete. Do not roll back a working deployment merely
# because the final Git branch update encounters a transient network problem.
CONFIG_APPLIED=0
DEPLOYED=0

echo
echo '=== 8. PROMOTE EXACT VALIDATED SOURCE ==='
git fetch origin "$MAIN_BRANCH:refs/remotes/origin/$MAIN_BRANCH"
git merge-base --is-ancestor "origin/$MAIN_BRANCH" "$BUILD_COMMIT" || \
  fail 'Validated build is not a fast-forward of the current Home Lab branch.'

git push origin "$BUILD_COMMIT:refs/heads/$MAIN_BRANCH"
git checkout -B "$MAIN_BRANCH" "$BUILD_COMMIT"
git branch --set-upstream-to="origin/$MAIN_BRANCH" "$MAIN_BRANCH" >/dev/null 2>&1 || true

stop_keepalive
trap - EXIT INT TERM

echo
echo '=================================================='
echo ' HOME LAB WEB-DESKTOP V2 VALIDATION PASS'
echo '=================================================='
echo "Commit: $BUILD_COMMIT"
echo "Bundle: $BUNDLE"
echo "Backup: $RUN"
echo "Log: $LOG"
echo 'Build/bundle: REUSED + PASS'
echo 'Home Lab theme/config: PASS'
echo 'Movies/TV/Anime runtime data gate: PASS'
echo 'Personal recommendation gate: PASS/SKIP only if no eligible history exists'
echo 'Live manifest: PASS'
echo 'Git promotion: PASS'
