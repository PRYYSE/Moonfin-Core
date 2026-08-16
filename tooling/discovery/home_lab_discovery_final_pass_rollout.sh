#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_SHA="a9c789fff317b41bba268d3a213439e23b8d1af5"
PREVIOUS_WEB_SHA="f38ee3fc2968b1d540300198e66c4a7edab64c9a"
SHORT_SHA="${SOURCE_SHA:0:12}"
MOONBASE_VERSION="2.0.3.1"
MIN_COMPILED_LANES=468
BASE_URL="http://127.0.0.1:8096"
REPO="/opt/src/moonfin-core"
DEV="/opt/src/moonfin-dev"
CONTROL="$DEV/discovery/final-pass-$SHORT_SHA"
WORKTREE="$CONTROL/source"
STAGE="$CONTROL/frontend-stage"
PUB_CACHE="$DEV/pub-cache"
LOG_DIR="$DEV/logs"
STATE_DIR="$DEV/state"
BACKUP_ROOT="$DEV/backups"
IMAGE="homelab-flutter:3.44.1"
PERSISTENT_SCRIPT="$CONTROL/home_lab_discovery_final_pass_rollout.sh"
MODE="${1:-start}"
ROLLBACK_ARG="${2:-}"
STAMP="$(date +%Y%m%d-%H%M%S)"
SUDO_KEEPALIVE=""

case "$MODE" in
  start|--worker|--rollback|--self-test) ;;
  *)
    echo "Usage: $0 [--self-test|--rollback BACKUP_DIR]" >&2
    exit 2
    ;;
esac

if [[ "$MODE" == "--self-test" ]]; then
  [[ "$SOURCE_SHA" =~ ^[0-9a-f]{40}$ ]]
  [[ "$PREVIOUS_WEB_SHA" =~ ^[0-9a-f]{40}$ ]]
  [[ "$SOURCE_SHA" != "$PREVIOUS_WEB_SHA" ]]
  [[ "$MIN_COMPILED_LANES" -ge 300 ]]
  echo "DISCOVERY FINAL PASS ROLLOUT SELF-TEST PASS"
  echo "source_sha=$SOURCE_SHA"
  echo "previous_web_sha=$PREVIOUS_WEB_SHA"
  echo "minimum_compiled_lanes=$MIN_COMPILED_LANES"
  exit 0
fi

D=()
P=()

select_privilege() {
  if docker info >/dev/null 2>&1; then
    D=(docker)
  elif sudo -n docker info >/dev/null 2>&1; then
    D=(sudo -n docker)
  else
    echo "ERROR: Docker is unavailable." >&2
    return 1
  fi
  if [[ "$(id -u)" -ne 0 ]]; then
    P=(sudo -n)
  fi
}

find_jellyfin_container() {
  local matches=()
  while IFS='|' read -r name image; do
    [[ -n "$name" ]] || continue
    if [[ "${name,,} ${image,,}" == *jellyfin* ]]; then
      matches+=("$name")
    fi
  done < <("${D[@]}" ps -a --format '{{.Names}}|{{.Image}}')
  if [[ "${#matches[@]}" -ne 1 ]]; then
    echo "ERROR: expected exactly one Jellyfin container; found ${#matches[@]}." >&2
    return 1
  fi
  printf '%s\n' "${matches[0]}"
}

container_config_host() {
  local container="$1"
  local source
  source="$("${D[@]}" inspect "$container" --format '{{range .Mounts}}{{if eq .Destination "/config"}}{{.Source}}{{end}}{{end}}')"
  [[ -n "$source" ]] || {
    echo "ERROR: Jellyfin container has no explicit /config mount." >&2
    return 1
  }
  printf '%s\n' "$source"
}

find_plugin_dll() {
  local plugin_root="$1"
  local matches=()
  while IFS= read -r path; do
    [[ -n "$path" ]] && matches+=("$path")
  done < <("${P[@]}" find "$plugin_root" -maxdepth 4 -type f -name 'Moonfin.Server.dll' -print 2>/dev/null)
  if [[ "${#matches[@]}" -ne 1 ]]; then
    echo "ERROR: expected exactly one Moonfin.Server.dll; found ${#matches[@]}." >&2
    return 1
  fi
  printf '%s\n' "${matches[0]}"
}

wait_for_jellyfin() {
  for _ in $(seq 1 60); do
    if curl -fsS -o /dev/null "$BASE_URL/System/Info/Public" 2>/dev/null; then
      return 0
    fi
    sleep 2
  done
  echo "ERROR: Jellyfin did not return after restart." >&2
  return 1
}

manifest_source() {
  curl -fsS "$BASE_URL/Moonfin/Web/homelab-build-manifest.json" \
    | python3 -c 'import json,sys; print(str(json.load(sys.stdin).get("sourceCommit") or ""))'
}

verify_runtime() {
  local expected_source="$1"
  local expected_lanes="${2:-0}"
  local helper="$WORKTREE/tooling/discovery/home_lab_discovery_verify_live.py"
  [[ -f "$helper" ]] || {
    echo "ERROR: runtime verification helper missing from exact source." >&2
    return 1
  }
  local output lanes
  output="$("${P[@]}" env \
    PYTHONDONTWRITEBYTECODE=1 \
    MOONFIN_JELLYFIN_URL="$BASE_URL" \
    MOONFIN_EXPECTED_WEB_COMMIT="$expected_source" \
    python3 "$helper")"
  printf '%s\n' "$output"
  grep -qx "moonbase_version=$MOONBASE_VERSION" <<<"$output"
  grep -qx "web_source_commit=$expected_source" <<<"$output"
  grep -qx 'seerr_enabled=true' <<<"$output"
  lanes="$(awk -F= '$1 == "compiled_lanes" {print $2}' <<<"$output")"
  [[ "$lanes" =~ ^[0-9]+$ && "$lanes" -ge "$MIN_COMPILED_LANES" ]]
  if [[ "$expected_lanes" -gt 0 ]]; then
    [[ "$lanes" -eq "$expected_lanes" ]]
  fi
}

restore_state() {
  local backup="$1"
  local jellyfin="$2"
  local frontend="$3"
  local catalogue="$4"
  local old_source old_lanes
  old_source="$(cat "$backup/source-commit.txt")"
  old_lanes="$(cat "$backup/lane-count.txt")"

  echo "Restoring the exact pre-final-pass frontend and Discovery catalogue..."
  "${D[@]}" stop "$jellyfin" >/dev/null 2>&1 || true
  "${P[@]}" rm -rf "$frontend"
  "${P[@]}" cp -a "$backup/frontend" "$frontend"
  if [[ -f "$backup/discovery.catalogue.json" ]]; then
    "${P[@]}" mkdir -p "$(dirname "$catalogue")"
    "${P[@]}" cp -a "$backup/discovery.catalogue.json" "$catalogue"
  else
    "${P[@]}" rm -f "$catalogue"
  fi
  "${D[@]}" start "$jellyfin" >/dev/null
  wait_for_jellyfin
  verify_runtime "$old_source" "$old_lanes"
  echo "Final-pass rollback PASS: $backup"
}

if [[ "$MODE" == "--rollback" ]]; then
  sudo -v
  select_privilege
  BACKUP="$ROLLBACK_ARG"
  if [[ -z "$BACKUP" && -f "$STATE_DIR/discovery-final-pass-latest-backup" ]]; then
    BACKUP="$(cat "$STATE_DIR/discovery-final-pass-latest-backup")"
  fi
  [[ -n "$BACKUP" && -d "$BACKUP/frontend" && -f "$BACKUP/source-commit.txt" ]] || {
    echo "ERROR: final-pass rollback backup not found." >&2
    exit 1
  }
  JELLYFIN="$(find_jellyfin_container)"
  CONFIG_HOST="$(container_config_host "$JELLYFIN")"
  PLUGIN_ROOT="$CONFIG_HOST/data/plugins"
  PLUGIN_DLL="$(find_plugin_dll "$PLUGIN_ROOT")"
  FRONTEND="$(dirname "$PLUGIN_DLL")/frontend"
  CATALOGUE="$PLUGIN_ROOT/configurations/Moonfin/discovery.catalogue.json"
  restore_state "$BACKUP" "$JELLYFIN" "$FRONTEND" "$CATALOGUE"
  exit 0
fi

if [[ "$MODE" != "--worker" ]]; then
  sudo -v
  uid="$(id -u)"
  gid="$(id -g)"
  sudo install -d -o "$uid" -g "$gid" -m 0755 \
    "$DEV/discovery" "$CONTROL" "$PUB_CACHE" "$LOG_DIR" "$STATE_DIR" "$BACKUP_ROOT"
  cp "$(readlink -f "${BASH_SOURCE[0]}")" "$PERSISTENT_SCRIPT"
  chmod +x "$PERSISTENT_SCRIPT"

  PID_FILE="$STATE_DIR/discovery-final-pass-current.pid"
  if [[ -f "$PID_FILE" ]]; then
    old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
      echo "ERROR: Discovery final-pass rollout is already running as PID $old_pid." >&2
      exit 1
    fi
  fi

  LOG="$LOG_DIR/discovery-final-pass-$STAMP.log"
  CURRENT_LOG="$STATE_DIR/discovery-final-pass-current.log"
  ln -sfn "$LOG" "$CURRENT_LOG"
  nohup bash "$PERSISTENT_SCRIPT" --worker >"$LOG" 2>&1 < /dev/null &
  pid=$!
  printf '%s\n' "$pid" > "$PID_FILE"
  cat <<EOF
Discovery final-pass rollout started.
pid=$pid
log=$LOG
Reconnect/progress:
tail -n 180 -f "\$(readlink -f $CURRENT_LOG)"
EOF
  exit 0
fi

for command in git python3 curl sha256sum find stat tar awk; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $command" >&2
    exit 1
  }
done

if [[ "$(id -u)" -ne 0 ]]; then
  sudo -n true || {
    echo "ERROR: sudo authorisation expired before detached worker started." >&2
    exit 1
  }
  (
    while true; do
      sudo -n true >/dev/null 2>&1 || exit 0
      sleep 45
    done
  ) &
  SUDO_KEEPALIVE=$!
  trap '[[ -n "${SUDO_KEEPALIVE:-}" ]] && kill "$SUDO_KEEPALIVE" >/dev/null 2>&1 || true' EXIT
fi

select_privilege
"${D[@]}" info >/dev/null
"${D[@]}" image inspect "$IMAGE" >/dev/null 2>&1 || {
  echo "ERROR: required Flutter build image is missing: $IMAGE" >&2
  exit 1
}
[[ -d "$REPO/.git" ]] || {
  echo "ERROR: persistent Moonfin source repo missing at $REPO" >&2
  exit 1
}

printf '\n[1/6] Preparing exact final-pass source %s...\n' "$SOURCE_SHA"
git -C "$REPO" fetch --quiet origin homelab/seerr-discovery-final-pass-work
git -C "$REPO" cat-file -e "$SOURCE_SHA^{commit}"
if [[ -e "$WORKTREE" ]]; then
  git -C "$REPO" worktree remove --force "$WORKTREE" >/dev/null 2>&1 || "${P[@]}" rm -rf "$WORKTREE"
fi
git -C "$REPO" worktree prune
git -C "$REPO" worktree add --detach "$WORKTREE" "$SOURCE_SHA"
[[ "$(git -C "$WORKTREE" rev-parse HEAD)" == "$SOURCE_SHA" ]]
python3 "$WORKTREE/tooling/discovery/apply_final_discovery_polish.py"
python3 "$WORKTREE/tooling/discovery/apply_final_discovery_polish.py" --check

JELLYFIN="$(find_jellyfin_container)"
CONFIG_HOST="$(container_config_host "$JELLYFIN")"
PLUGIN_ROOT="$CONFIG_HOST/data/plugins"
PLUGIN_DLL="$(find_plugin_dll "$PLUGIN_ROOT")"
PLUGIN_DIR="$(dirname "$PLUGIN_DLL")"
FRONTEND="$PLUGIN_DIR/frontend"
CATALOGUE="$PLUGIN_ROOT/configurations/Moonfin/discovery.catalogue.json"
[[ -d "$FRONTEND" && -f "$CATALOGUE" ]] || {
  echo "ERROR: live Moonfin frontend/catalogue foundation is incomplete." >&2
  exit 1
}

CURRENT_SOURCE="$(manifest_source)"
if [[ "$CURRENT_SOURCE" == "$SOURCE_SHA" ]]; then
  echo "Final pass is already live; running runtime gate only."
  expected_lanes=0
  if [[ -f "$STATE_DIR/discovery-final-pass-latest-lanes" ]]; then
    expected_lanes="$(cat "$STATE_DIR/discovery-final-pass-latest-lanes")"
  fi
  verify_runtime "$SOURCE_SHA" "$expected_lanes"
  echo "DISCOVERY FINAL PASS ALREADY APPLIED"
  exit 0
fi
if [[ "$CURRENT_SOURCE" != "$PREVIOUS_WEB_SHA" ]]; then
  echo "ERROR: live Web source changed unexpectedly; refusing final-pass mutation." >&2
  echo "expected_current=$PREVIOUS_WEB_SHA" >&2
  echo "actual_current=${CURRENT_SOURCE:-missing}" >&2
  exit 1
fi

printf '\n[2/6] Verifying current accepted Web/server/catalogue baseline...\n'
verify_runtime "$PREVIOUS_WEB_SHA" 468

printf '\n[3/6] Recompiling Discovery against live Seerr metadata with safe semantic aliases...\n'
CANDIDATE_CATALOGUE="$CONTROL/discovery.catalogue.compiled.json"
DIAGNOSTICS="$CONTROL/discovery.compile.diagnostics.json"
"${P[@]}" env \
  PYTHONDONTWRITEBYTECODE=1 \
  MOONFIN_JELLYFIN_URL="$BASE_URL" \
  python3 "$WORKTREE/tooling/discovery/home_lab_discovery_compile_live.py" \
    --output "$CANDIDATE_CATALOGUE" \
    --diagnostics "$DIAGNOSTICS"
"${P[@]}" chown "$(id -u):$(id -g)" "$CANDIDATE_CATALOGUE" "$DIAGNOSTICS"
CANDIDATE_LANES="$(python3 - "$CANDIDATE_CATALOGUE" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    data = json.load(handle)
print(sum(len(tab.get('sections') or []) for tab in data.get('tabs') or []))
PY
)"
[[ "$CANDIDATE_LANES" =~ ^[0-9]+$ && "$CANDIDATE_LANES" -ge "$MIN_COMPILED_LANES" ]] || {
  echo "ERROR: final compiled catalogue regressed below $MIN_COMPILED_LANES lanes: $CANDIDATE_LANES" >&2
  exit 1
}
echo "candidate_compiled_lanes=$CANDIDATE_LANES"
python3 - "$DIAGNOSTICS" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    data = json.load(handle)
print('unresolved_keyword_names=' + str(len(data.get('unresolvedKeywordNames') or [])))
print('semantic_drops=' + str(len(data.get('semanticDrops') or [])))
print('provider_drops=' + str(len(data.get('providerAvailabilityDrops') or [])))
PY

printf '\n[4/6] Building final Web frontend from the validated source...\n'
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
"${D[@]}" run --rm \
  --user "$HOST_UID:$HOST_GID" \
  -e HOME=/home/builder \
  -e PUB_CACHE=/home/builder/.pub-cache \
  -e PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -v "$WORKTREE:/workspace" \
  -v "$PUB_CACHE:/home/builder/.pub-cache" \
  -w /workspace \
  "$IMAGE" bash -c '
    set -Eeuo pipefail
    flutter pub get
    dart format --output=none --set-exit-if-changed \
      lib/data/services/seerr/seerr_discovery_composer.dart \
      lib/data/services/seerr/seerr_discovery_personal_presentation.dart \
      lib/data/viewmodels/seerr_deep_discovery_view_model.dart \
      lib/ui/screens/seerr/seerr_discover_screen.dart \
      test/data/seerr_discovery_composer_test.dart \
      test/data/seerr_discovery_personal_presentation_test.dart
    flutter analyze \
      lib/data/services/seerr/seerr_discovery_composer.dart \
      lib/data/services/seerr/seerr_discovery_personal_presentation.dart \
      lib/data/viewmodels/seerr_deep_discovery_view_model.dart \
      lib/ui/screens/seerr/seerr_discover_screen.dart
    flutter test \
      test/data/seerr_discovery_composer_test.dart \
      test/data/seerr_discovery_personal_presentation_test.dart \
      test/data/seerr_deep_discovery_view_model_test.dart
    flutter build web --wasm --release --base-href "/Moonfin/Web/"
  '

cat > "$WORKTREE/build/web/config.json" <<'JSON'
{
  "schemaVersion": 1,
  "defaultServerUrl": null,
  "discoveryProxyUrl": null,
  "enableWebRtcScan": true,
  "brandingName": "Home Lab",
  "pluginMode": true,
  "forcedServerUrl": null
}
JSON
cat > "$WORKTREE/build/web/homelab-build-manifest.json" <<JSON
{
  "schemaVersion": 1,
  "prototype": "homelab-seerr-discovery-v1",
  "design": "discovery-final-pass",
  "sourceBranch": "homelab/seerr-discovery-final-pass-work",
  "sourceCommit": "$SOURCE_SHA",
  "sourceOwned": true,
  "builder": "docker01",
  "flutterVersion": "3.44.1",
  "theme": "home_lab_streaming",
  "discoverySchemaVersion": 2,
  "authoringLaneCount": 486
}
JSON

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -a "$WORKTREE/build/web/." "$STAGE/"
if [[ -d "$FRONTEND/downloads" ]]; then
  rm -rf "$STAGE/downloads"
  cp -a "$FRONTEND/downloads" "$STAGE/downloads"
fi
CANDIDATE_TAR="$CONTROL/Moonfin_HomeLab_Discovery_Final_$SHORT_SHA.tar.gz"
tar -czf "$CANDIDATE_TAR" -C "$STAGE" .
sha256sum "$CANDIDATE_TAR" | tee "$CANDIDATE_TAR.sha256"

[[ "$(manifest_source)" == "$PREVIOUS_WEB_SHA" ]] || {
  echo "ERROR: live frontend changed while final candidate was building; refusing swap." >&2
  exit 1
}

printf '\n[5/6] Creating exact frontend + catalogue rollback data...\n'
BACKUP="$BACKUP_ROOT/discovery-final-pass-$STAMP"
"${P[@]}" mkdir -p "$BACKUP"
"${P[@]}" cp -a "$FRONTEND" "$BACKUP/frontend"
"${P[@]}" cp -a "$CATALOGUE" "$BACKUP/discovery.catalogue.json"
printf '%s\n' "$PREVIOUS_WEB_SHA" | "${P[@]}" tee "$BACKUP/source-commit.txt" >/dev/null
printf '%s\n' 468 | "${P[@]}" tee "$BACKUP/lane-count.txt" >/dev/null
printf '%s\n' "$BACKUP" | "${P[@]}" tee "$STATE_DIR/discovery-final-pass-latest-backup" >/dev/null
FRONTEND_OWNER="$(stat -c '%u:%g' "$FRONTEND")"
FRONTEND_MODE="$(stat -c '%a' "$FRONTEND")"
CAT_OWNER="$(stat -c '%u:%g' "$CATALOGUE")"
CAT_MODE="$(stat -c '%a' "$CATALOGUE")"
HAD_ANDROID_APK=0
[[ -f "$FRONTEND/downloads/Moonfin_HomeLab_Android_v1.apk" ]] && HAD_ANDROID_APK=1
echo "rollback_backup=$BACKUP"

printf '\n[6/6] Swapping only frontend + Discovery catalogue and running runtime gates...\n'
ROLLBACK_ARMED=1
rollback_on_error() {
  local rc=$?
  trap - ERR INT TERM
  if [[ "${ROLLBACK_ARMED:-0}" == "1" ]]; then
    echo "ERROR: Discovery final pass failed; restoring exact previous state." >&2
    restore_state "$BACKUP" "$JELLYFIN" "$FRONTEND" "$CATALOGUE" || true
  fi
  exit "$rc"
}
trap rollback_on_error ERR INT TERM

"${D[@]}" stop "$JELLYFIN" >/dev/null
"${P[@]}" rm -rf "$FRONTEND"
"${P[@]}" install -d \
  -o "${FRONTEND_OWNER%:*}" -g "${FRONTEND_OWNER#*:}" -m "$FRONTEND_MODE" \
  "$FRONTEND"
"${P[@]}" cp -a "$STAGE/." "$FRONTEND/"
"${P[@]}" chown -R "$FRONTEND_OWNER" "$FRONTEND"
"${P[@]}" install \
  -o "${CAT_OWNER%:*}" -g "${CAT_OWNER#*:}" -m "$CAT_MODE" \
  "$CANDIDATE_CATALOGUE" "$CATALOGUE"
"${D[@]}" start "$JELLYFIN" >/dev/null
wait_for_jellyfin
verify_runtime "$SOURCE_SHA" "$CANDIDATE_LANES"
[[ "$(manifest_source)" == "$SOURCE_SHA" ]]
if [[ "$HAD_ANDROID_APK" == "1" ]]; then
  [[ -f "$FRONTEND/downloads/Moonfin_HomeLab_Android_v1.apk" ]]
fi

ROLLBACK_ARMED=0
trap - ERR INT TERM
printf '%s\n' "$SOURCE_SHA" | "${P[@]}" tee "$STATE_DIR/discovery-final-pass-latest-source" >/dev/null
printf '%s\n' "$CANDIDATE_LANES" | "${P[@]}" tee "$STATE_DIR/discovery-final-pass-latest-lanes" >/dev/null
printf '%s\n' "$CANDIDATE_TAR" | "${P[@]}" tee "$STATE_DIR/discovery-final-pass-latest-bundle" >/dev/null

printf '\nDISCOVERY FINAL PASS APPLY PASS\n'
echo "url=http://192.168.50.12:8096/Moonfin/Web/"
echo "source_sha=$SOURCE_SHA"
echo "moonbase_unchanged=$MOONBASE_VERSION"
echo "compiled_lanes=$CANDIDATE_LANES"
echo "candidate_bundle=$CANDIDATE_TAR"
echo "rollback_backup=$BACKUP"
echo "rollback_command=bash $PERSISTENT_SCRIPT --rollback \"$BACKUP\""
