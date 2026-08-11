#!/usr/bin/env bash
set -Eeuo pipefail

SRC=/opt/src/moonfin-core
DEV=/opt/src/moonfin-dev
STAGING_BRANCH=homelab/web-desktop-v2-staging
MAIN_BRANCH=homelab/hubs-v1
GOOD_DESIGN=home-web-comprehensive-v1
V2_DESIGN=web-desktop-v2-candidate
THEME_ID=home_lab_streaming
PLUGIN_ROOT=/srv/appdata/jellyfin/data/plugins
BACKUP_ROOT=/srv/appdata/jellyfin/backups
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="$BACKUP_ROOT/web-desktop-v2-resume-$STAMP"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  return 1
}

[[ -d "$SRC/.git" ]] || fail "$SRC is not the persistent Moonfin source tree."
command -v git >/dev/null 2>&1 || fail 'git is missing.'
command -v curl >/dev/null 2>&1 || fail 'curl is missing.'
command -v python3 >/dev/null 2>&1 || fail 'python3 is missing.'
command -v docker >/dev/null 2>&1 || fail 'docker is missing.'
command -v timeout >/dev/null 2>&1 || fail 'timeout is missing.'

if docker info >/dev/null 2>&1; then
  D=(docker)
else
  D=(sudo docker)
fi

PLUGIN_DIR=''
for candidate in "$PLUGIN_ROOT"/Moonbase_* "$PLUGIN_ROOT"/Moonfin*; do
  if [[ -d "$candidate" && -f "$candidate/Moonfin.Server.dll" ]]; then
    PLUGIN_DIR="$candidate"
  fi
done
[[ -n "$PLUGIN_DIR" ]] || fail 'Moonbase/Moonfin plugin directory not found.'
FRONTEND="$PLUGIN_DIR/frontend"
[[ -f "$FRONTEND/index.html" ]] || fail "Moonfin frontend missing at $FRONTEND"

sudo mkdir -p "$RUN"
sudo chmod 700 "$RUN"

CONFIG_APPLIED=0
CANDIDATE_DEPLOYED=0
GOOD_LIVE=''
VERIFY_DIR=''

wait_for_moonfin() {
  local code=''
  for _ in $(seq 1 40); do
    code="$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8096/Moonfin/Web/ || true)"
    [[ "$code" == 200 ]] && return 0
    sleep 2
  done
  return 1
}

served_manifest() {
  curl -fsS http://127.0.0.1:8096/Moonfin/Web/homelab-build-manifest.json
}

restore_after_failure() {
  local rc=$?
  trap - ERR
  set +e
  echo
  echo '=== V2 RESUME FAILED: AUTOMATIC RESTORE ===' >&2

  if [[ "$CANDIDATE_DEPLOYED" == 1 && -n "$GOOD_LIVE" && -d "$GOOD_LIVE" ]]; then
    "${D[@]}" stop jellyfin >/dev/null 2>&1 || true
    if [[ -d "$FRONTEND" ]]; then
      sudo mv "$FRONTEND" "$RUN/failed-v2-frontend" 2>/dev/null || sudo rm -rf "$FRONTEND"
    fi
    sudo mv "$GOOD_LIVE" "$FRONTEND"
    "${D[@]}" start jellyfin >/dev/null 2>&1 || true
    wait_for_moonfin >/dev/null 2>&1 || true
    echo 'Web frontend restored to the known-good build.' >&2
  fi

  if [[ "$CONFIG_APPLIED" == 1 ]]; then
    sudo env PYTHONPATH="$SRC/tooling" python3 "$SRC/tooling/home_lab_v2_moonbase.py" \
      restore --backup-dir "$RUN/moonbase" >/dev/null 2>&1 || true
    echo 'Moonbase user/theme configuration restored.' >&2
  fi

  [[ -z "$VERIFY_DIR" ]] || rm -rf "$VERIFY_DIR"
  echo "Failure backup: $RUN" >&2
  exit "$rc"
}
trap restore_after_failure ERR

printf '=== 1. CONFIRM KNOWN-GOOD LIVE FRONTEND ===\n'
LIVE="$(served_manifest)"
grep -Fq "\"design\": \"$GOOD_DESIGN\"" <<<"$LIVE" || \
  fail "Live frontend is not the expected $GOOD_DESIGN rollback build."
echo "LIVE SAFE: $GOOD_DESIGN"

printf '\n=== 2. STOP ONLY THE STALE V2 BUILD ===\n'
mapfile -t BUILD_CIDS < <("${D[@]}" ps --filter ancestor=homelab-flutter:3.44.1 -q)
if (( ${#BUILD_CIDS[@]} )); then
  echo "Stopping stale Flutter build container(s): ${BUILD_CIDS[*]}"
  "${D[@]}" stop -t 10 "${BUILD_CIDS[@]}" >/dev/null || true
else
  echo 'No running Home Lab Flutter build container found.'
fi

# Give the old wrapper/runner time to observe the stopped container and exit.
sleep 3
for pid in $(pgrep -f 'build_web_desktop_v2.sh final' || true); do
  [[ "$pid" == "$$" ]] || kill "$pid" 2>/dev/null || true
done
sleep 2

echo 'Stale final build cleared.'

printf '\n=== 3. FAST-FORWARD TO LATEST V2 STAGING TOOLING ===\n'
[[ -z "$(git -C "$SRC" status --porcelain)" ]] || {
  git -C "$SRC" status --short
  fail 'Persistent source is dirty; recovery will not overwrite local work.'
}

git -C "$SRC" fetch origin \
  "$STAGING_BRANCH:refs/remotes/origin/$STAGING_BRANCH"
git -C "$SRC" checkout "$STAGING_BRANCH"
git -C "$SRC" merge --ff-only "origin/$STAGING_BRANCH"

[[ -f "$SRC/tooling/build_web_desktop_v2.sh" ]] || fail 'V2 build helper missing.'
[[ -f "$SRC/tooling/home_lab_v2_moonbase.py" ]] || fail 'Moonbase v2 helper missing.'
[[ -f "$SRC/tooling/home_lab_v2_personal_gate.py" ]] || fail 'Personalisation gate missing.'
[[ -f "$SRC/tooling/themes/home_lab_streaming.json" ]] || fail 'Home Lab ThemeSpec missing.'
python3 -m py_compile "$SRC/tooling/home_lab_v2_moonbase.py" "$SRC/tooling/home_lab_v2_personal_gate.py"

COMMIT="$(git -C "$SRC" rev-parse HEAD)"
echo "Candidate source: $COMMIT"

printf '\n=== 4. FINAL COMMITTED-SOURCE BUILD (30 MIN MAX) ===\n'
[[ -z "$(git -C "$SRC" status --porcelain)" ]] || fail 'Source is dirty before final build.'
if ! timeout --signal=TERM --kill-after=30s 30m \
  bash "$SRC/tooling/build_web_desktop_v2.sh" final; then
  rc=$?
  if [[ "$rc" == 124 || "$rc" == 137 ]]; then
    fail 'Final Flutter build exceeded 30 minutes and was terminated.'
  fi
  fail "Final Flutter build failed with exit code $rc."
fi
[[ -z "$(git -C "$SRC" status --porcelain)" ]] || fail 'Final build changed committed source.'

BUNDLE="$(cat "$DEV/state/web-desktop-v2-latest-bundle")"
[[ -f "$BUNDLE" && -f "$BUNDLE.sha256" ]] || fail 'Final v2 bundle or checksum is missing.'
sha256sum -c "$BUNDLE.sha256"

VERIFY_DIR="$(mktemp -d)"
tar -xzf "$BUNDLE" -C "$VERIFY_DIR"
[[ -f "$VERIFY_DIR/index.html" && -f "$VERIFY_DIR/homelab-build-manifest.json" ]] || fail 'Final bundle is incomplete.'
grep -Fq "\"design\": \"$V2_DESIGN\"" "$VERIFY_DIR/homelab-build-manifest.json" || fail 'Wrong v2 design marker.'
grep -Fq "\"sourceCommit\": \"$COMMIT\"" "$VERIFY_DIR/homelab-build-manifest.json" || fail 'Bundle commit does not match source.'
grep -Fq "\"theme\": \"$THEME_ID\"" "$VERIFY_DIR/homelab-build-manifest.json" || fail 'Bundle theme marker is wrong.'

grep -Fq 'return configured;' "$SRC/lib/ui/screens/home/homelab_home_composer.dart" || fail 'Home is not preserving Moonbase configuration.'
[[ "$(grep -Fc "title: 'New & Noteworthy'" "$SRC/lib/ui/screens/home/homelab_home_composer.dart")" == 1 ]] || fail 'Home does not have exactly one New & Noteworthy composition.'
! grep -Fq 'copyWith(enabled: true)' "$SRC/lib/ui/screens/home/homelab_home_composer.dart" || fail 'Home still force-enables Moonbase rows.'
grep -Fq '_verifyAnime' "$SRC/lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart" || fail 'Anime detail verification is missing.'
grep -Fq 'getMovieDetails' "$SRC/lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart" || fail 'Anime movie detail verification is missing.'
grep -Fq 'getTvDetails' "$SRC/lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart" || fail 'Anime TV detail verification is missing.'

echo "FINAL BUILD PASS: $COMMIT"

printf '\n=== 5. BACK UP + APPLY HOME LAB THEME / DESKTOP PROFILE ===\n'
sudo env PYTHONPATH="$SRC/tooling" python3 "$SRC/tooling/home_lab_v2_moonbase.py" \
  apply --backup-dir "$RUN/moonbase" --theme "$SRC/tooling/themes/home_lab_streaming.json"
CONFIG_APPLIED=1

printf '\n=== 6. DEPLOY COMPLETE V2 CANDIDATE ===\n'
OWNER="$(stat -c '%u:%g' "$FRONTEND")"
STAGE="$PLUGIN_DIR/.frontend-v2-stage-$STAMP"
sudo rm -rf "$STAGE"
sudo mkdir -p "$STAGE"
sudo tar -xzf "$BUNDLE" -C "$STAGE"
sudo chown -R "$OWNER" "$STAGE"
GOOD_LIVE="$RUN/live-good-before-v2"
"${D[@]}" stop jellyfin >/dev/null
sudo mv "$FRONTEND" "$GOOD_LIVE"
CANDIDATE_DEPLOYED=1
sudo mv "$STAGE" "$FRONTEND"
"${D[@]}" start jellyfin >/dev/null
wait_for_moonfin || fail 'Jellyfin did not serve Moonfin after v2 deployment.'
SERVED="$(served_manifest)"
grep -Fq "\"design\": \"$V2_DESIGN\"" <<<"$SERVED" || fail 'Served frontend is not the v2 candidate.'
grep -Fq "\"sourceCommit\": \"$COMMIT\"" <<<"$SERVED" || fail 'Served frontend commit mismatch.'

printf '\n=== 7. RUNTIME DATA / SAFETY / PERSONALISATION GATES ===\n'
sudo env PYTHONPATH="$SRC/tooling" python3 "$SRC/tooling/home_lab_v2_moonbase.py" validate
sudo env PYTHONPATH="$SRC/tooling" python3 "$SRC/tooling/home_lab_v2_personal_gate.py"

printf '\n=== 8. PROMOTE EXACT VALIDATED SOURCE ===\n'
git -C "$SRC" push origin HEAD:"$MAIN_BRANCH"
git -C "$SRC" checkout -B "$MAIN_BRANCH" HEAD
git -C "$SRC" branch --set-upstream-to="origin/$MAIN_BRANCH" "$MAIN_BRANCH" >/dev/null 2>&1 || true

trap - ERR
rm -rf "$VERIFY_DIR"
VERIFY_DIR=''

echo
echo '=== HOME LAB WEB-DESKTOP V2 VALIDATION PASS ==='
echo "Commit: $COMMIT"
echo "Design: $V2_DESIGN"
echo "Theme: $THEME_ID"
echo 'HTTP: 200'
echo "Rollback/config backup: $RUN"
echo 'Home: Moonbase-owned rows + one New & Noteworthy + 3 history recommendation rows configured'
echo 'Movies: fault-isolated discovery gate passed'
echo 'TV: fault-isolated discovery gate passed'
echo 'Anime: strict detail/keyword safety gate passed'
echo 'Open: http://192.168.50.12:8096/Moonfin/Web/'
