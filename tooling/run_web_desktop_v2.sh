#!/usr/bin/env bash
set -Eeuo pipefail

SRC=/opt/src/moonfin-core
DEV=/opt/src/moonfin-dev
STAGING_BRANCH=homelab/web-desktop-v2-staging
MAIN_BRANCH=homelab/hubs-v1
BAD_DESIGN=web-desktop-comprehensive-v1
GOOD_DESIGN=home-web-comprehensive-v1
V2_DESIGN=web-desktop-v2-candidate
THEME_ID=home_lab_streaming
PLUGIN_ROOT=/srv/appdata/jellyfin/data/plugins
BACKUP_ROOT=/srv/appdata/jellyfin/backups
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="$BACKUP_ROOT/web-desktop-v2-$STAMP"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  return 1
}

[[ -d "$SRC/.git" ]] || fail "$SRC is not the persistent Moonfin source tree."
command -v git >/dev/null 2>&1 || fail 'git is missing.'
command -v curl >/dev/null 2>&1 || fail 'curl is missing.'
command -v python3 >/dev/null 2>&1 || fail 'python3 is missing.'
command -v docker >/dev/null 2>&1 || fail 'docker is missing.'

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
  echo '=== V2 GATE FAILED: AUTOMATIC RESTORE ===' >&2

  if [[ "$CANDIDATE_DEPLOYED" == 1 && -n "$GOOD_LIVE" && -d "$GOOD_LIVE" ]]; then
    "${D[@]}" stop jellyfin >/dev/null 2>&1 || true
    if [[ -d "$FRONTEND" ]]; then
      sudo mv "$FRONTEND" "$RUN/failed-v2-frontend" 2>/dev/null || sudo rm -rf "$FRONTEND"
    fi
    sudo mv "$GOOD_LIVE" "$FRONTEND"
    "${D[@]}" start jellyfin >/dev/null 2>&1 || true
    wait_for_moonfin >/dev/null 2>&1 || true
    echo 'Web frontend restored to the pre-v2 usable build.' >&2
  fi

  if [[ "$CONFIG_APPLIED" == 1 ]]; then
    sudo env PYTHONPATH="$SRC/tooling" python3 "$SRC/tooling/home_lab_v2_moonbase.py" \
      restore --backup-dir "$RUN/moonbase" >/dev/null 2>&1 || true
    echo 'Moonbase user/theme configuration restored.' >&2
  fi

  echo "Failure backup: $RUN" >&2
  exit "$rc"
}
trap restore_after_failure ERR

printf '=== 1. ROLLBACK CURRENT WEB FRONTEND ONLY ===\n'
CURRENT_DESIGN=''
if [[ -f "$FRONTEND/homelab-build-manifest.json" ]]; then
  CURRENT_DESIGN="$(sudo python3 - "$FRONTEND/homelab-build-manifest.json" <<'PY'
import json, sys
try:
    print(json.load(open(sys.argv[1])).get('design',''))
except Exception:
    print('')
PY
)"
fi
printf 'Current live design: %s\n' "${CURRENT_DESIGN:-unknown}"

if [[ "$CURRENT_DESIGN" != "$GOOD_DESIGN" ]]; then
  GOOD_STAGE="$PLUGIN_DIR/.frontend-v2-good-$STAMP"
  sudo rm -rf "$GOOD_STAGE"
  sudo mkdir -p "$GOOD_STAGE"
  FOUND_GOOD=0

  while IFS= read -r manifest; do
    [[ -n "$manifest" ]] || continue
    design="$(sudo python3 - "$manifest" <<'PY'
import json, sys
try:
    print(json.load(open(sys.argv[1])).get('design',''))
except Exception:
    print('')
PY
)"
    if [[ "$design" == "$GOOD_DESIGN" ]]; then
      source_dir="$(dirname "$manifest")"
      sudo cp -a "$source_dir"/. "$GOOD_STAGE"/
      FOUND_GOOD=1
      break
    fi
  done < <(sudo find "$BACKUP_ROOT" -type f -path '*/frontend/homelab-build-manifest.json' -print 2>/dev/null | sort -r)

  if [[ "$FOUND_GOOD" == 0 ]]; then
    while IFS= read -r bundle; do
      [[ -f "$bundle" ]] || continue
      manifest="$(tar -xOf "$bundle" ./homelab-build-manifest.json 2>/dev/null || tar -xOf "$bundle" homelab-build-manifest.json 2>/dev/null || true)"
      if grep -Fq "\"design\": \"$GOOD_DESIGN\"" <<<"$manifest"; then
        sudo rm -rf "$GOOD_STAGE"
        sudo mkdir -p "$GOOD_STAGE"
        sudo tar -xzf "$bundle" -C "$GOOD_STAGE"
        FOUND_GOOD=1
        break
      fi
    done < <(ls -1t "$DEV"/output/homelab-moonfin-web-*.tar.gz 2>/dev/null || true)
  fi

  [[ "$FOUND_GOOD" == 1 && -f "$GOOD_STAGE/index.html" ]] || \
    fail "Could not locate the last known-good $GOOD_DESIGN frontend."

  OWNER="$(stat -c '%u:%g' "$FRONTEND")"
  sudo chown -R "$OWNER" "$GOOD_STAGE"
  "${D[@]}" stop jellyfin >/dev/null
  sudo mv "$FRONTEND" "$RUN/bad-v1-frontend"
  sudo mv "$GOOD_STAGE" "$FRONTEND"
  if ! "${D[@]}" start jellyfin >/dev/null || ! wait_for_moonfin; then
    "${D[@]}" stop jellyfin >/dev/null 2>&1 || true
    sudo rm -rf "$FRONTEND"
    sudo mv "$RUN/bad-v1-frontend" "$FRONTEND"
    "${D[@]}" start jellyfin >/dev/null 2>&1 || true
    fail 'Known-good frontend rollback did not start cleanly; original frontend restored.'
  fi
  ROLLED="$(served_manifest)"
  grep -Fq "\"design\": \"$GOOD_DESIGN\"" <<<"$ROLLED" || {
    "${D[@]}" stop jellyfin >/dev/null 2>&1 || true
    sudo rm -rf "$FRONTEND"
    sudo mv "$RUN/bad-v1-frontend" "$FRONTEND"
    "${D[@]}" start jellyfin >/dev/null 2>&1 || true
    fail 'Rollback served the wrong build; original frontend restored.'
  }
  echo "ROLLBACK PASS: $GOOD_DESIGN is live."
else
  echo 'Rollback already satisfied: known-good frontend is live.'
fi

printf '\n=== 2. MATERIALISE COMPLETE V2 SOURCE ===\n'
[[ -z "$(git -C "$SRC" status --porcelain)" ]] || {
  git -C "$SRC" status --short
  fail 'Persistent source is not clean; v2 runner will not overwrite local work.'
}
PRE_RUN_HEAD="$(git -C "$SRC" rev-parse HEAD)"
git -C "$SRC" branch "homelab/v2-pre-run-$STAMP" "$PRE_RUN_HEAD" 2>/dev/null || true
git -C "$SRC" fetch origin "$STAGING_BRANCH"
git -C "$SRC" checkout -B "$STAGING_BRANCH" "origin/$STAGING_BRANCH"

[[ -f "$SRC/tooling/themes/home_lab_streaming.json" ]] || fail 'Home Lab ThemeSpec is missing.'
[[ -f "$SRC/lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart" ]] || fail 'V2 destination source is missing.'
python3 -m py_compile "$SRC/tooling/home_lab_v2_moonbase.py" "$SRC/tooling/home_lab_v2_personal_gate.py"

printf '\n=== 3. FORMAT / ANALYSE / FIRST COMPILE ===\n'
bash "$SRC/tooling/build_web_desktop_v2.sh" prepare

ALLOWED_RE='^(lib/ui/screens/home/home_screen.dart|lib/ui/screens/home/home_view_model.dart|lib/ui/screens/home/homelab_home_composer.dart|lib/ui/screens/hubs/homelab_hub_screen.dart|lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart|lib/ui/widgets/media_bar.dart)$'
unexpected=0
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  path="${line:3}"
  if ! grep -Eq "$ALLOWED_RE" <<<"$path"; then
    echo "Unexpected build-time source change: $line" >&2
    unexpected=1
  fi
done < <(git -C "$SRC" status --porcelain)
[[ "$unexpected" == 0 ]] || fail 'Prepare build changed an unexpected source path.'

if [[ -n "$(git -C "$SRC" status --porcelain)" ]]; then
  git -C "$SRC" add -- \
    lib/ui/screens/home/home_screen.dart \
    lib/ui/screens/home/home_view_model.dart \
    lib/ui/screens/home/homelab_home_composer.dart \
    lib/ui/screens/hubs/homelab_hub_screen.dart \
    lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart \
    lib/ui/widgets/media_bar.dart
  git -C "$SRC" diff --cached --check
  git -C "$SRC" commit -m 'Format Home Lab web desktop v2 candidate'
  git -C "$SRC" push origin HEAD:"$STAGING_BRANCH"
fi

printf '\n=== 4. FINAL COMMITTED-SOURCE BUILD ===\n'
[[ -z "$(git -C "$SRC" status --porcelain)" ]] || fail 'Source is dirty before final build.'
bash "$SRC/tooling/build_web_desktop_v2.sh" final
[[ -z "$(git -C "$SRC" status --porcelain)" ]] || fail 'Final build changed committed source.'
COMMIT="$(git -C "$SRC" rev-parse HEAD)"
BUNDLE="$(cat "$DEV/state/web-desktop-v2-latest-bundle")"
[[ -f "$BUNDLE" && -f "$BUNDLE.sha256" ]] || fail 'Final v2 bundle or checksum is missing.'
sha256sum -c "$BUNDLE.sha256"

VERIFY_DIR="$(mktemp -d)"
trap 'rm -rf "$VERIFY_DIR"' EXIT
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

echo "COMMITTED BUILD PASS: $COMMIT"

printf '\n=== 5. SAVE/APPLY HOME LAB THEME + DESKTOP MOONBASE PROFILE ===\n'
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
sudo mv "$STAGE" "$FRONTEND"
CANDIDATE_DEPLOYED=1
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
trap - EXIT

echo
echo '=== HOME LAB WEB-DESKTOP V2 VALIDATION PASS ==='
echo "Commit: $COMMIT"
echo "Design: $V2_DESIGN"
echo "Theme: $THEME_ID"
echo "HTTP: 200"
echo "Rollback/config backup: $RUN"
echo 'Home: Moonbase-owned rows + one New & Noteworthy + 3 history recommendation rows configured'
echo 'Movies: fault-isolated discovery gate passed'
echo 'TV: fault-isolated discovery gate passed'
echo 'Anime: strict detail/keyword safety gate passed'
echo 'Open: http://192.168.50.12:8096/Moonfin/Web/'
