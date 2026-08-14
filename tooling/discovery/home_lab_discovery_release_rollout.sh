#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_SHA="0079647902b54b78d71b048a4a7572c51cba49f2"
SHORT="0079647902b5"
OLD_WEB_SHA="9be74475d0ff7dfed6a573a5f8a9e5225b8331e6"
ARTIFACT_REF="87d40552a9f0afe6edfdd69efdc1a3224619b35a"
ARTIFACT_DIR="seerr-discovery/$SHORT"
ARTIFACT_BASE="https://raw.githubusercontent.com/PRYYSE/Moonfin-Core/$ARTIFACT_REF/$ARTIFACT_DIR"
ASSET="Moonfin_HomeLab_Seerr_Discovery_Web_${SHORT}.tar.gz"

MAIN_REPO="/opt/src/moonfin-core"
DEV="/opt/src/moonfin-dev"
CONTROL="$DEV/discovery/release-control-$SHORT"
WORKTREE="$CONTROL/source"
CANDIDATE_DIR="$CONTROL/candidate"
STABLE_SCRIPT="$CONTROL/home_lab_discovery_release_rollout.sh"
LOG_DIR="$DEV/logs"
STATE_DIR="$DEV/state"
CURRENT_LOG="$STATE_DIR/discovery-release-current.log"
PID_FILE="$STATE_DIR/discovery-release-current.pid"
LATEST_BACKUP="$STATE_DIR/discovery-release-latest-backup"
LATEST_SOURCE="$STATE_DIR/discovery-release-latest-source"
LATEST_ARTIFACT="$STATE_DIR/discovery-release-latest-artifact"
LAN_URL="http://192.168.50.12:8096/Moonfin/Web/"

SUDO_KEEPALIVE_PID=""
BACKUP=""
JELLYFIN=""
PLUGIN_DIR=""
CATALOGUE=""
ROLLBACK_ARMED=0

say() {
  printf '%s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

safe_remove_tree() {
  local path="$1"
  [[ -n "$path" ]] || die "refusing to remove an empty path"
  case "$path" in
    "$CONTROL"/*) ;;
    *) die "refusing to remove unexpected path: $path" ;;
  esac
  rm -rf -- "$path"
}

validate_manifest() {
  local manifest="$1"
  local config="$2"
  python3 - "$manifest" "$config" "$SOURCE_SHA" <<'PY'
import json
import sys

manifest_path, config_path, expected_source = sys.argv[1:]
with open(manifest_path, encoding="utf-8") as handle:
    manifest = json.load(handle)
with open(config_path, encoding="utf-8") as handle:
    config = json.load(handle)

expected = {
    "sourceCommit": expected_source,
    "design": "seerr-discovery-v1-candidate",
    "theme": "home_lab_streaming",
    "discoverySchemaVersion": 2,
    "authoringLaneCount": 486,
}
for key, value in expected.items():
    if manifest.get(key) != value:
        raise SystemExit(
            f"candidate manifest mismatch for {key}: "
            f"expected {value!r}, got {manifest.get(key)!r}"
        )

if config.get("schemaVersion") != 1:
    raise SystemExit("candidate config schemaVersion is not 1")
if config.get("pluginMode") is not True:
    raise SystemExit("candidate config is not in pluginMode")
if config.get("enableWebRtcScan") is not True:
    raise SystemExit("candidate config changed enableWebRtcScan")
for key in ("defaultServerUrl", "discoveryProxyUrl", "forcedServerUrl"):
    if config.get(key) is not None:
        raise SystemExit(f"candidate config unexpectedly sets {key}")
PY
}

validate_tar_safety() {
  local archive="$1"
  python3 - "$archive" <<'PY'
from pathlib import PurePosixPath
import sys
import tarfile

archive = sys.argv[1]
with tarfile.open(archive, "r:gz") as handle:
    members = handle.getmembers()
    if not members:
        raise SystemExit("candidate tar is empty")
    for member in members:
        name = member.name
        path = PurePosixPath(name)
        if not name or path.is_absolute() or ".." in path.parts:
            raise SystemExit(f"unsafe candidate tar path: {name!r}")
        if member.issym() or member.islnk() or member.isdev():
            raise SystemExit(f"unsupported candidate tar entry: {name!r}")
PY
}

download_file() {
  local url="$1"
  local output="$2"
  curl -fL --retry 4 --retry-delay 2 --connect-timeout 20 \
    --max-time 180 -sS "$url" -o "$output"
}

prepare_candidate() {
  local root="$1"
  local extracted="$root/extracted"
  local parts_manifest="$root/$ASSET.parts.sha256"
  local full_manifest="$root/$ASSET.sha256"
  local source_file="$root/source-sha.txt"
  local home_manifest="$root/homelab-build-manifest.json"
  local config_file="$root/config.json"
  local build_manifest="$root/build-manifest.json"
  local archive="$root/$ASSET"

  rm -rf -- "$root"
  mkdir -p "$root"

  say "Downloading immutable candidate metadata..."
  download_file "$ARTIFACT_BASE/$ASSET.parts.sha256" "$parts_manifest"
  download_file "$ARTIFACT_BASE/$ASSET.sha256" "$full_manifest"
  download_file "$ARTIFACT_BASE/source-sha.txt" "$source_file"
  download_file "$ARTIFACT_BASE/homelab-build-manifest.json" "$home_manifest"
  download_file "$ARTIFACT_BASE/config.json" "$config_file"
  download_file "$ARTIFACT_BASE/build-manifest.json" "$build_manifest"

  [[ "$(tr -d '\r\n' < "$source_file")" == "$SOURCE_SHA" ]] || \
    die "public candidate source SHA does not match $SOURCE_SHA"
  validate_manifest "$home_manifest" "$config_file"

  say "Downloading and verifying candidate parts..."
  while read -r hash filename extra; do
    [[ -n "${hash:-}" && -n "${filename:-}" && -z "${extra:-}" ]] || \
      die "invalid candidate parts checksum line"
    [[ "$hash" =~ ^[0-9a-fA-F]{64}$ ]] || die "invalid part checksum"
    case "$filename" in
      "$ASSET".part-[0-9][0-9]) ;;
      *) die "unexpected candidate part name: $filename" ;;
    esac
    download_file "$ARTIFACT_BASE/$filename" "$root/$filename"
  done < "$parts_manifest"

  (
    cd "$root"
    sha256sum -c "$(basename "$parts_manifest")"
    cat "$ASSET".part-* > "$ASSET"
    sha256sum -c "$(basename "$full_manifest")"
  )

  validate_tar_safety "$archive"
  mkdir -p "$extracted"
  tar -xzf "$archive" -C "$extracted"

  [[ -s "$extracted/index.html" ]] || die "candidate index.html is missing"
  [[ -s "$extracted/homelab-build-manifest.json" ]] || \
    die "candidate Home Lab manifest is missing"
  [[ -s "$extracted/config.json" ]] || die "candidate config.json is missing"
  [[ -f "$extracted/main.dart.wasm" || -f "$extracted/main.dart.js" ]] || \
    die "candidate Flutter runtime is missing"

  cmp -s "$home_manifest" "$extracted/homelab-build-manifest.json" || \
    die "published Home Lab manifest differs from packaged manifest"
  cmp -s "$config_file" "$extracted/config.json" || \
    die "published config differs from packaged config"
  validate_manifest \
    "$extracted/homelab-build-manifest.json" \
    "$extracted/config.json"

  say "Candidate artifact verification PASS"
}

self_test() {
  for command in curl sha256sum tar python3; do
    need "$command"
  done
  local tmp quoted_tmp
  tmp="$(mktemp -d)"
  printf -v quoted_tmp '%q' "$tmp"
  trap "rm -rf -- $quoted_tmp" EXIT
  prepare_candidate "$tmp/candidate"
  local full_sha
  full_sha="$(awk 'NR == 1 {print $1}' "$tmp/candidate/$ASSET.sha256")"
  [[ "$full_sha" =~ ^[0-9a-fA-F]{64}$ ]] || die "invalid full candidate checksum"
  say "DISCOVERY ROLLOUT SELF-TEST PASS"
  say "source_sha=$SOURCE_SHA"
  say "artifact_ref=$ARTIFACT_REF"
  say "artifact_sha256=$full_sha"
  rm -rf -- "$tmp"
  trap - EXIT
}

start_sudo_keepalive() {
  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi
  sudo -n true >/dev/null 2>&1 || \
    die "sudo authorisation expired before the detached worker started"
  (
    while true; do
      sudo -n true >/dev/null 2>&1 || exit 0
      sleep 45
    done
  ) &
  SUDO_KEEPALIVE_PID=$!
}

stop_sudo_keepalive() {
  if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
    kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
    wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    SUDO_KEEPALIVE_PID=""
  fi
}

privileged() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo -n "$@"
  fi
}

docker_cmd() {
  if docker info >/dev/null 2>&1; then
    docker "$@"
  else
    privileged docker "$@"
  fi
}

find_jellyfin_container() {
  local matches=()
  while IFS='|' read -r name image; do
    [[ -n "$name" ]] || continue
    if [[ "${name,,} ${image,,}" == *jellyfin* ]]; then
      matches+=("$name")
    fi
  done < <(docker_cmd ps --format '{{.Names}}|{{.Image}}')
  [[ "${#matches[@]}" -eq 1 ]] || \
    die "expected exactly one running Jellyfin container; found ${#matches[@]}"
  printf '%s\n' "${matches[0]}"
}

container_config_host() {
  local container="$1"
  local source
  source="$(docker_cmd inspect "$container" \
    --format '{{range .Mounts}}{{if eq .Destination "/config"}}{{.Source}}{{end}}{{end}}')"
  [[ -n "$source" ]] || die "Jellyfin container has no explicit /config mount"
  printf '%s\n' "$source"
}

find_plugin_dll() {
  local plugin_root="$1"
  local matches=()
  while IFS= read -r path; do
    [[ -n "$path" ]] && matches+=("$path")
  done < <(privileged find "$plugin_root" -maxdepth 4 -type f \
    -name 'Moonfin.Server.dll' -print 2>/dev/null)
  [[ "${#matches[@]}" -eq 1 ]] || \
    die "expected exactly one installed Moonfin.Server.dll; found ${#matches[@]}"
  printf '%s\n' "${matches[0]}"
}

wait_for_jellyfin() {
  local code=""
  for _ in $(seq 1 45); do
    code="$(curl -sS -o /dev/null -w '%{http_code}' \
      http://127.0.0.1:8096/System/Info/Public || true)"
    [[ "$code" == "200" ]] && return 0
    sleep 2
  done
  die "Jellyfin did not return after restart"
}

prepare_worktree() {
  [[ -d "$MAIN_REPO/.git" ]] || die "Moonfin source repo not found at $MAIN_REPO"
  say "Preparing exact validated Discovery source $SOURCE_SHA..."
  git -C "$MAIN_REPO" fetch -q origin homelab/seerr-discovery-v1-staging
  git -C "$MAIN_REPO" cat-file -e "$SOURCE_SHA^{commit}" || \
    die "validated Discovery source commit is unavailable locally"

  if git -C "$MAIN_REPO" worktree list --porcelain | \
      grep -Fx "worktree $WORKTREE" >/dev/null 2>&1; then
    git -C "$MAIN_REPO" worktree remove --force "$WORKTREE"
  elif [[ -e "$WORKTREE" ]]; then
    safe_remove_tree "$WORKTREE"
  fi
  git -C "$MAIN_REPO" worktree prune
  git -C "$MAIN_REPO" worktree add -q --detach "$WORKTREE" "$SOURCE_SHA"
  [[ "$(git -C "$WORKTREE" rev-parse HEAD)" == "$SOURCE_SHA" ]] || \
    die "detached release worktree is not at the validated source"

  for required in \
    tooling/discovery/home_lab_discovery_server_job.sh \
    tooling/discovery/home_lab_discovery_verify_live.py; do
    [[ -s "$WORKTREE/$required" ]] || die "validated source is missing $required"
  done
}

rollback_live() {
  [[ -n "$BACKUP" && -d "$BACKUP" ]] || return 0
  say "Rolling back the exact pre-Discovery Moonfin plugin state..."
  bash "$WORKTREE/tooling/discovery/home_lab_discovery_server_job.sh" \
    rollback "$BACKUP"
}

rollback_on_error() {
  local rc=$?
  trap - ERR INT TERM
  if [[ "$ROLLBACK_ARMED" -eq 1 ]]; then
    printf 'ERROR: Discovery candidate apply failed; automatic rollback is running.\n' >&2
    rollback_live || true
  fi
  stop_sudo_keepalive
  exit "$rc"
}

verify_live_candidate() {
  local live_manifest="$CONTROL/live-homelab-build-manifest.json"

  MOONFIN_JELLYFIN_URL=http://127.0.0.1:8096 \
  MOONFIN_EXPECTED_WEB_COMMIT="$SOURCE_SHA" \
    python3 "$WORKTREE/tooling/discovery/home_lab_discovery_verify_live.py"

  curl -fsS -o /dev/null "http://127.0.0.1:8096/Moonfin/Web/"
  curl -fsS \
    "http://127.0.0.1:8096/Moonfin/Web/homelab-build-manifest.json" \
    -o "$live_manifest"
  python3 - "$live_manifest" "$SOURCE_SHA" <<'PY'
import json
import sys

path, source = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)
checks = {
    "sourceCommit": source,
    "design": "seerr-discovery-v1-candidate",
    "theme": "home_lab_streaming",
    "discoverySchemaVersion": 2,
    "authoringLaneCount": 486,
}
for key, expected in checks.items():
    if data.get(key) != expected:
        raise SystemExit(
            f"live Web manifest mismatch for {key}: "
            f"expected {expected!r}, got {data.get(key)!r}"
        )
PY
}

worker() {
  for command in git curl tar sha256sum python3 find stat seq; do
    need "$command"
  done
  if [[ "$(id -u)" -ne 0 ]]; then
    need sudo
  fi
  start_sudo_keepalive
  trap stop_sudo_keepalive EXIT

  mkdir -p "$CONTROL"
  prepare_worktree

  say "Preparing exact immutable Web candidate before any live mutation..."
  prepare_candidate "$CANDIDATE_DIR"

  say "Applying reversible Moonbase 2.0.3.1 + live Discovery catalogue foundation..."
  bash "$WORKTREE/tooling/discovery/home_lab_discovery_server_job.sh" apply

  [[ -s "$STATE_DIR/discovery-server-latest-backup" ]] || \
    die "server foundation did not record a rollback backup"
  BACKUP="$(cat "$STATE_DIR/discovery-server-latest-backup")"
  [[ -d "$BACKUP/plugin" ]] || die "server rollback plugin backup is missing"
  printf '%s\n' "$BACKUP" > "$LATEST_BACKUP"

  ROLLBACK_ARMED=1
  trap rollback_on_error ERR INT TERM

  JELLYFIN="$(find_jellyfin_container)"
  local config_host plugin_root plugin_dll frontend stage owner
  config_host="$(container_config_host "$JELLYFIN")"
  plugin_root="$config_host/data/plugins"
  plugin_dll="$(find_plugin_dll "$plugin_root")"
  PLUGIN_DIR="$(dirname "$plugin_dll")"
  frontend="$PLUGIN_DIR/frontend"
  CATALOGUE="$plugin_root/configurations/Moonfin/discovery.catalogue.json"
  [[ -d "$frontend" ]] || die "live Moonfin frontend directory is missing"

  local old_live_source
  old_live_source="$(python3 - "$frontend/homelab-build-manifest.json" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(str(json.load(handle).get("sourceCommit") or ""))
PY
)"
  [[ "$old_live_source" == "$OLD_WEB_SHA" ]] || \
    die "live Web changed after server foundation gate; refusing frontend swap"

  stage="$PLUGIN_DIR/.frontend-discovery-stage-$SHORT"
  privileged rm -rf -- "$stage"
  privileged mkdir -p "$stage"
  privileged cp -a "$CANDIDATE_DIR/extracted/." "$stage/"
  owner="$(stat -c '%u:%g' "$frontend")"
  privileged chown -R "$owner" "$stage"

  say "Swapping only the Moonfin frontend to the exact validated candidate..."
  docker_cmd stop "$JELLYFIN" >/dev/null
  privileged rm -rf -- "$frontend"
  privileged mv "$stage" "$frontend"
  docker_cmd start "$JELLYFIN" >/dev/null
  wait_for_jellyfin

  say "Running combined server/catalogue/Web runtime gate..."
  verify_live_candidate

  local artifact_sha
  artifact_sha="$(awk 'NR == 1 {print $1}' "$CANDIDATE_DIR/$ASSET.sha256")"
  printf '%s\n' "$SOURCE_SHA" > "$LATEST_SOURCE"
  printf '%s\n' "$artifact_sha" > "$LATEST_ARTIFACT"

  ROLLBACK_ARMED=0
  trap - ERR INT TERM
  stop_sudo_keepalive
  trap - EXIT

  rm -f -- "$CANDIDATE_DIR/$ASSET" "$CANDIDATE_DIR/$ASSET".part-*

  say "DISCOVERY WEB CANDIDATE APPLY PASS"
  say "url=$LAN_URL"
  say "source_sha=$SOURCE_SHA"
  say "artifact_sha256=$artifact_sha"
  say "rollback_backup=$BACKUP"
  say "rollback_command=bash $WORKTREE/tooling/discovery/home_lab_discovery_server_job.sh rollback \"\$(cat $LATEST_BACKUP)\""
}

prepare_control_paths() {
  local uid gid
  uid="$(id -u)"
  gid="$(id -g)"
  privileged mkdir -p "$CONTROL" "$LOG_DIR" "$STATE_DIR"
  privileged chown -R "$uid:$gid" "$CONTROL"
  privileged touch "$PID_FILE" "$LATEST_BACKUP" "$LATEST_SOURCE" "$LATEST_ARTIFACT"
  privileged chown "$uid:$gid" \
    "$PID_FILE" "$LATEST_BACKUP" "$LATEST_SOURCE" "$LATEST_ARTIFACT"
}

launch() {
  need bash
  if [[ "$(id -u)" -ne 0 ]]; then
    need sudo
    sudo -v
  fi

  local uid gid stamp log old_pid=""
  uid="$(id -u)"
  gid="$(id -g)"
  stamp="$(date +%Y%m%d-%H%M%S)"
  log="$LOG_DIR/discovery-release-$stamp.log"

  prepare_control_paths
  privileged install -m 0755 "$0" "$STABLE_SCRIPT"
  privileged touch "$log"
  privileged chown "$uid:$gid" "$log"

  if [[ -s "$PID_FILE" ]]; then
    old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
      die "Discovery rollout is already running as PID $old_pid"
    fi
  fi

  privileged ln -sfn "$log" "$CURRENT_LOG"
  nohup bash "$STABLE_SCRIPT" --worker >"$log" 2>&1 </dev/null &
  local pid=$!
  printf '%s\n' "$pid" > "$PID_FILE"

  say "Discovery rollout started."
  say "pid=$pid"
  say "log=$log"
  say "Reconnect/progress:"
  say "tail -n 180 -f \"\$(readlink -f $CURRENT_LOG)\""
}

manual_rollback() {
  if [[ "$(id -u)" -ne 0 ]]; then
    need sudo
    sudo -v
  fi
  start_sudo_keepalive
  trap stop_sudo_keepalive EXIT
  prepare_control_paths

  [[ -s "$LATEST_BACKUP" ]] || die "no Discovery release rollback backup is recorded"
  BACKUP="$(cat "$LATEST_BACKUP")"
  [[ -d "$BACKUP/plugin" ]] || die "recorded rollback backup is missing"

  if [[ ! -s "$WORKTREE/tooling/discovery/home_lab_discovery_server_job.sh" ]]; then
    prepare_worktree
  fi
  rollback_live
  stop_sudo_keepalive
  trap - EXIT
  say "DISCOVERY RELEASE ROLLBACK PASS"
  say "restored_backup=$BACKUP"
}

case "${1:-}" in
  --self-test)
    self_test
    ;;
  --worker)
    worker
    ;;
  --rollback)
    manual_rollback
    ;;
  "")
    launch
    ;;
  *)
    die "usage: $0 [--self-test|--worker|--rollback]"
    ;;
esac
