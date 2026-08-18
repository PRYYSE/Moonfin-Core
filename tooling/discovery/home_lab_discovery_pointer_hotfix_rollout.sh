#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_SHA="a7489c9e6e897ad39302fc963140f01c72f94991"
SOURCE_BRANCH="homelab/seerr-discovery-final-pass-work"
PREVIOUS_WEB_SHA="a9c789fff317b41bba268d3a213439e23b8d1af5"
SHORT_SHA="${SOURCE_SHA:0:12}"
MOONBASE_VERSION="2.0.3.1"
EXPECTED_LANES="481"
BASE_URL="http://127.0.0.1:8096"
REPO="/opt/src/moonfin-core"
DEV="/opt/src/moonfin-dev"
CONTROL="$DEV/discovery/pointer-hotfix-$SHORT_SHA"
WORKTREE="$CONTROL/source"
STAGE="$CONTROL/frontend-stage"
PUB_CACHE="$DEV/pub-cache"
LOG_DIR="$DEV/logs"
STATE_DIR="$DEV/state"
BACKUP_ROOT="$DEV/backups"
IMAGE="homelab-flutter:3.44.1"
PERSISTENT_SCRIPT="$CONTROL/home_lab_discovery_pointer_hotfix_rollout.sh"
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
  [[ "$EXPECTED_LANES" == "481" ]]
  echo "DISCOVERY POINTER HOTFIX SELF-TEST PASS"
  echo "source_sha=$SOURCE_SHA"
  echo "previous_web_sha=$PREVIOUS_WEB_SHA"
  echo "expected_lanes=$EXPECTED_LANES"
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
  local expected="$1"
  local helper="$WORKTREE/tooling/discovery/home_lab_discovery_verify_live.py"
  [[ -f "$helper" ]] || {
    echo "ERROR: runtime verification helper missing from exact source." >&2
    return 1
  }
  local output
  output="$("${P[@]}" env \
    PYTHONDONTWRITEBYTECODE=1 \
    MOONFIN_JELLYFIN_URL="$BASE_URL" \
    MOONFIN_EXPECTED_WEB_COMMIT="$expected" \
    python3 "$helper")"
  printf '%s\n' "$output"
  grep -qx "moonbase_version=$MOONBASE_VERSION" <<<"$output"
  grep -qx "compiled_lanes=$EXPECTED_LANES" <<<"$output"
  grep -qx "web_source_commit=$expected" <<<"$output"
  grep -qx 'seerr_enabled=true' <<<"$output"
}

verify_runtime_after_restart() {
  local expected="$1"
  local attempt
  sleep 5
  for attempt in $(seq 1 12); do
    if verify_runtime "$expected"; then
      return 0
    fi
    if [[ "$attempt" -lt 12 ]]; then
      echo "Moonfin runtime not ready yet (attempt $attempt/12); retrying in 5s..." >&2
      sleep 5
    fi
  done
  echo "ERROR: Moonfin runtime did not stabilise after restart." >&2
  return 1
}

restore_frontend() {
  local backup="$1"
  local container="$2"
  local frontend="$3"
  local expected_old="$4"

  echo "Restoring exact pre-hotfix Moonfin frontend..."
  "${D[@]}" stop "$container" >/dev/null 2>&1 || true
  "${P[@]}" rm -rf "$frontend"
  "${P[@]}" cp -a "$backup/frontend" "$frontend"
  "${D[@]}" start "$container" >/dev/null
  wait_for_jellyfin
  verify_runtime_after_restart "$expected_old"
  echo "Pointer-hotfix rollback PASS: $backup"
}

if [[ "$MODE" == "--rollback" ]]; then
  sudo -v
  select_privilege
  BACKUP="$ROLLBACK_ARG"
  if [[ -z "$BACKUP" && -f "$STATE_DIR/discovery-pointer-hotfix-latest-backup" ]]; then
    BACKUP="$(cat "$STATE_DIR/discovery-pointer-hotfix-latest-backup")"
  fi
  [[ -n "$BACKUP" && -d "$BACKUP/frontend" && -f "$BACKUP/source-commit.txt" ]] || {
    echo "ERROR: pointer-hotfix rollback backup not found." >&2
    exit 1
  }
  JELLYFIN="$(find_jellyfin_container)"
  CONFIG_HOST="$(container_config_host "$JELLYFIN")"
  PLUGIN_ROOT="$CONFIG_HOST/data/plugins"
  PLUGIN_DLL="$(find_plugin_dll "$PLUGIN_ROOT")"
  FRONTEND="$(dirname "$PLUGIN_DLL")/frontend"
  OLD_SOURCE="$(cat "$BACKUP/source-commit.txt")"
  restore_frontend "$BACKUP" "$JELLYFIN" "$FRONTEND" "$OLD_SOURCE"
  exit 0
fi

if [[ "$MODE" != "--worker" ]]; then
  sudo -v
  uid="$(id -u)"
  gid="$(id -g)"
  sudo install -d -o "$uid" -g "$gid" -m 0755 \
    "$DEV/discovery" "$CONTROL" "$PUB_CACHE" "$LOG_DIR" "$STATE_DIR" "$BACKUP_ROOT"
  source_path="$(readlink -f "${BASH_SOURCE[0]}")"
  if [[ "$source_path" != "$PERSISTENT_SCRIPT" ]]; then
    cp "$source_path" "$PERSISTENT_SCRIPT"
  fi
  chmod +x "$PERSISTENT_SCRIPT"

  PID_FILE="$STATE_DIR/discovery-pointer-hotfix-current.pid"
  if [[ -f "$PID_FILE" ]]; then
    old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
      echo "ERROR: Discovery pointer hotfix is already running as PID $old_pid." >&2
      exit 1
    fi
  fi

  LOG="$LOG_DIR/discovery-pointer-hotfix-$STAMP.log"
  CURRENT_LOG="$STATE_DIR/discovery-pointer-hotfix-current.log"
  ln -sfn "$LOG" "$CURRENT_LOG"
  nohup bash "$PERSISTENT_SCRIPT" --worker >"$LOG" 2>&1 < /dev/null &
  pid=$!
  printf '%s\n' "$pid" > "$PID_FILE"
  cat <<EOF
Discovery pointer hotfix started.
pid=$pid
log=$LOG
Reconnect/progress:
tail -n 160 -f "\$(readlink -f $CURRENT_LOG)"
EOF
  exit 0
fi

for command in git python3 curl sha256sum find stat tar; do
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

printf '\n[1/5] Preparing exact pointer-hotfix source %s...\n' "$SOURCE_SHA"
SOURCE_REF="refs/moonfin/discovery-pointer-hotfix-source"
git -C "$REPO" fetch --quiet origin \
  "+refs/heads/$SOURCE_BRANCH:$SOURCE_REF"
[[ "$(git -C "$REPO" rev-parse "$SOURCE_REF")" == "$SOURCE_SHA" ]] || {
  echo "ERROR: pointer-hotfix source branch moved unexpectedly." >&2
  exit 1
}
if [[ -e "$WORKTREE" ]]; then
  git -C "$REPO" worktree remove --force "$WORKTREE" >/dev/null 2>&1 || "${P[@]}" rm -rf "$WORKTREE"
fi
git -C "$REPO" worktree prune
git -C "$REPO" worktree add --detach "$WORKTREE" "$SOURCE_SHA"
[[ "$(git -C "$WORKTREE" rev-parse HEAD)" == "$SOURCE_SHA" ]]
python3 "$WORKTREE/tooling/discovery/apply_final_discovery_polish.py"
python3 "$WORKTREE/tooling/discovery/apply_final_discovery_polish.py" --check
grep -Fq 'onTap: activateTab' "$WORKTREE/lib/ui/screens/seerr/seerr_discover_screen.dart"
grep -Fq 'behavior: HitTestBehavior.opaque' "$WORKTREE/lib/ui/screens/seerr/seerr_discover_screen.dart"

JELLYFIN="$(find_jellyfin_container)"
CONFIG_HOST="$(container_config_host "$JELLYFIN")"
PLUGIN_ROOT="$CONFIG_HOST/data/plugins"
PLUGIN_DLL="$(find_plugin_dll "$PLUGIN_ROOT")"
FRONTEND="$(dirname "$PLUGIN_DLL")/frontend"
[[ -d "$FRONTEND" ]] || {
  echo "ERROR: live Moonfin frontend missing at $FRONTEND" >&2
  exit 1
}

CURRENT_SOURCE="$(manifest_source)"
if [[ "$CURRENT_SOURCE" == "$SOURCE_SHA" ]]; then
  echo "Pointer hotfix is already live; running runtime gate only."
  verify_runtime "$SOURCE_SHA"
  echo "DISCOVERY POINTER HOTFIX ALREADY APPLIED"
  exit 0
fi
if [[ "$CURRENT_SOURCE" != "$PREVIOUS_WEB_SHA" ]]; then
  echo "ERROR: live Web source changed unexpectedly; refusing frontend swap." >&2
  echo "expected_current=$PREVIOUS_WEB_SHA" >&2
  echo "actual_current=${CURRENT_SOURCE:-missing}" >&2
  exit 1
fi

printf '\n[2/5] Verifying exact current 481-lane Discovery baseline...\n'
verify_runtime "$PREVIOUS_WEB_SHA"

printf '\n[3/5] Building pointer-capable frontend from exact source...\n'
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
      lib/ui/screens/seerr/seerr_discover_screen.dart
    flutter analyze \
      lib/ui/screens/seerr/seerr_discover_screen.dart \
      lib/data/viewmodels/seerr_deep_discovery_view_model.dart
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
  "design": "discovery-pointer-hotfix",
  "sourceBranch": "$SOURCE_BRANCH",
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
CANDIDATE_TAR="$CONTROL/Moonfin_HomeLab_Discovery_Pointer_$SHORT_SHA.tar.gz"
tar -czf "$CANDIDATE_TAR" -C "$STAGE" .
sha256sum "$CANDIDATE_TAR" | tee "$CANDIDATE_TAR.sha256"

[[ "$(manifest_source)" == "$PREVIOUS_WEB_SHA" ]] || {
  echo "ERROR: live frontend changed while pointer candidate was building; refusing swap." >&2
  exit 1
}

printf '\n[4/5] Backing up exact current frontend...\n'
BACKUP="$BACKUP_ROOT/discovery-pointer-hotfix-$STAMP"
"${P[@]}" mkdir -p "$BACKUP"
"${P[@]}" cp -a "$FRONTEND" "$BACKUP/frontend"
printf '%s\n' "$PREVIOUS_WEB_SHA" | "${P[@]}" tee "$BACKUP/source-commit.txt" >/dev/null
printf '%s\n' "$BACKUP" | "${P[@]}" tee "$STATE_DIR/discovery-pointer-hotfix-latest-backup" >/dev/null
FRONTEND_OWNER="$(stat -c '%u:%g' "$FRONTEND")"
FRONTEND_MODE="$(stat -c '%a' "$FRONTEND")"
HAD_ANDROID_APK=0
[[ -f "$FRONTEND/downloads/Moonfin_HomeLab_Android_v1.apk" ]] && HAD_ANDROID_APK=1
echo "frontend_backup=$BACKUP"

printf '\n[5/5] Swapping frontend only and running runtime gates...\n'
ROLLBACK_ARMED=1
rollback_on_error() {
  local rc=$?
  trap - ERR INT TERM
  if [[ "${ROLLBACK_ARMED:-0}" == "1" ]]; then
    echo "ERROR: pointer hotfix failed; restoring exact previous frontend." >&2
    restore_frontend "$BACKUP" "$JELLYFIN" "$FRONTEND" "$PREVIOUS_WEB_SHA" || true
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
"${D[@]}" start "$JELLYFIN" >/dev/null
wait_for_jellyfin
verify_runtime_after_restart "$SOURCE_SHA"
[[ "$(manifest_source)" == "$SOURCE_SHA" ]]
if [[ "$HAD_ANDROID_APK" == "1" ]]; then
  [[ -f "$FRONTEND/downloads/Moonfin_HomeLab_Android_v1.apk" ]]
fi

ROLLBACK_ARMED=0
trap - ERR INT TERM
printf '%s\n' "$SOURCE_SHA" | "${P[@]}" tee "$STATE_DIR/discovery-pointer-hotfix-latest-source" >/dev/null
printf '%s\n' "$CANDIDATE_TAR" | "${P[@]}" tee "$STATE_DIR/discovery-pointer-hotfix-latest-bundle" >/dev/null

printf '\nDISCOVERY POINTER HOTFIX APPLY PASS\n'
echo "url=http://192.168.50.12:8096/Moonfin/Web/"
echo "source_sha=$SOURCE_SHA"
echo "moonbase_unchanged=$MOONBASE_VERSION"
echo "compiled_lanes_unchanged=$EXPECTED_LANES"
echo "candidate_bundle=$CANDIDATE_TAR"
echo "frontend_backup=$BACKUP"
echo "rollback_command=bash $PERSISTENT_SCRIPT --rollback \"$BACKUP\""
