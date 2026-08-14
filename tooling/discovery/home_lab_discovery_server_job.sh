#!/usr/bin/env bash
set -Eeuo pipefail

MODE="${1:-prepare}"
ROLLBACK_ARG="${2:-}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEV="/opt/src/moonfin-dev"
WORK="$DEV/discovery/server-work"
BACKUP_ROOT="$DEV/backups"
STATE="$DEV/state"
MOONBASE_VERSION="2.0.3.1"
MOONBASE_TAG="2.0.3"
DOTNET_IMAGE="mcr.microsoft.com/dotnet/sdk:8.0"
COMPILED="$DEV/discovery/discovery.catalogue.compiled.json"
DIAGNOSTICS="$DEV/discovery/discovery.compile.diagnostics.json"
STAMP="$(date +%Y%m%d-%H%M%S)"

case "$MODE" in
  prepare|apply|rollback) ;;
  *)
    echo "Usage: $0 [prepare|apply|rollback] [backup-dir]" >&2
    exit 2
    ;;
esac

mkdir -p "$WORK" "$BACKUP_ROOT" "$STATE" "$DEV/discovery"

if docker info >/dev/null 2>&1; then
  D=(docker)
elif sudo -n docker info >/dev/null 2>&1; then
  D=(sudo -n docker)
else
  echo "ERROR: Docker is not available to the current user or passwordless sudo." >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  P=()
elif sudo -n true >/dev/null 2>&1; then
  P=(sudo -n)
else
  P=()
fi

find_jellyfin_container() {
  local matches=()
  while IFS='|' read -r name image; do
    [[ -n "$name" ]] || continue
    if [[ "${name,,} ${image,,}" == *jellyfin* ]]; then
      matches+=("$name")
    fi
  done < <("${D[@]}" ps --format '{{.Names}}|{{.Image}}')
  if [[ "${#matches[@]}" -ne 1 ]]; then
    echo "ERROR: expected exactly one running Jellyfin container; found ${#matches[@]}." >&2
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
  done < <(find "$plugin_root" -maxdepth 4 -type f -name 'Moonfin.Server.dll' -print 2>/dev/null)
  if [[ "${#matches[@]}" -ne 1 ]]; then
    echo "ERROR: expected exactly one installed Moonfin.Server.dll under $plugin_root; found ${#matches[@]}." >&2
    return 1
  fi
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
  echo "ERROR: Jellyfin did not return after restart." >&2
  return 1
}

restore_backup() {
  local backup="$1"
  local container="$2"
  local plugin_dir="$3"
  local catalogue="$4"

  echo "Rolling back Moonbase Discovery server foundation..."
  "${D[@]}" stop "$container" >/dev/null 2>&1 || true

  if [[ -d "$backup/plugin" ]]; then
    "${P[@]}" rm -rf "$plugin_dir"
    "${P[@]}" cp -a "$backup/plugin" "$plugin_dir"
  fi

  if [[ -f "$backup/catalogue.original.json" ]]; then
    "${P[@]}" mkdir -p "$(dirname "$catalogue")"
    "${P[@]}" cp -a "$backup/catalogue.original.json" "$catalogue"
  else
    "${P[@]}" rm -f "$catalogue"
  fi

  "${D[@]}" start "$container" >/dev/null
  wait_for_jellyfin
  echo "Rollback complete: $backup"
}

if [[ "$MODE" == "rollback" ]]; then
  BACKUP="$ROLLBACK_ARG"
  if [[ -z "$BACKUP" && -f "$STATE/discovery-server-latest-backup" ]]; then
    BACKUP="$(cat "$STATE/discovery-server-latest-backup")"
  fi
  [[ -n "$BACKUP" && -d "$BACKUP" ]] || {
    echo "ERROR: rollback backup directory not found." >&2
    exit 1
  }
  JELLYFIN="$(find_jellyfin_container)"
  CONFIG_HOST="$(container_config_host "$JELLYFIN")"
  PLUGIN_ROOT="$CONFIG_HOST/data/plugins"
  PLUGIN_DLL="$(find_plugin_dll "$PLUGIN_ROOT")"
  PLUGIN_DIR="$(dirname "$PLUGIN_DLL")"
  CATALOGUE="$PLUGIN_ROOT/configurations/Moonfin/discovery.catalogue.json"
  restore_backup "$BACKUP" "$JELLYFIN" "$PLUGIN_DIR" "$CATALOGUE"
  exit 0
fi

for command in git python3 curl sha256sum find stat; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $command" >&2
    exit 1
  }
done

printf '\n[1/5] Compiling the 486-lane authoring catalogue against live Seerr metadata...\n'
python3 "$ROOT/tooling/discovery/home_lab_discovery_compile_live.py" \
  --output "$COMPILED" \
  --diagnostics "$DIAGNOSTICS"
python3 - "$COMPILED" <<'PY'
import json, sys
p = sys.argv[1]
data = json.load(open(p, encoding='utf-8'))
count = sum(len(t.get('sections') or []) for t in data.get('tabs') or [])
if data.get('schemaVersion') != 2 or count < 300:
    raise SystemExit(f'compiled catalogue failed safety gate: schema={data.get("schemaVersion")} lanes={count}')
print(f'compiled_catalogue_gate=pass lanes={count}')
PY

printf '\n[2/5] Building a DLL-only Moonbase %s candidate from exact upstream %s...\n' \
  "$MOONBASE_VERSION" "$MOONBASE_TAG"
SRC="$WORK/moonbase-$MOONBASE_TAG"
PUBLISH="$WORK/publish-$MOONBASE_VERSION"
rm -rf "$SRC" "$PUBLISH"
git clone --quiet --depth 1 --branch "$MOONBASE_TAG" \
  https://github.com/Moonfin-Client/Plugin.git "$SRC"
cp "$ROOT/tooling/discovery/moonbase/MoonfinDiscoveryController.cs" \
  "$SRC/Jellyfin/backend/Api/MoonfinDiscoveryController.cs"
mkdir -p "$PUBLISH"

"${D[@]}" run --rm \
  -v "$SRC:/src" \
  -v "$PUBLISH:/publish" \
  -w /src/Jellyfin \
  "$DOTNET_IMAGE" \
  dotnet publish backend/Moonfin.Server.csproj \
    -c Release \
    -o /publish \
    -p:AssemblyVersion="$MOONBASE_VERSION" \
    -p:FileVersion="$MOONBASE_VERSION" \
    -p:Version="$MOONBASE_VERSION"

"${D[@]}" run --rm \
  -v "$SRC:/src" \
  -v "$PUBLISH:/publish" \
  -w /src/Jellyfin \
  "$DOTNET_IMAGE" \
  dotnet run --project tools/verify-plugin/VerifyPlugin.csproj \
    -c Release -- /publish/Moonfin.Server.dll "$MOONBASE_VERSION"

CANDIDATE_DLL="$PUBLISH/Moonfin.Server.dll"
[[ -f "$CANDIDATE_DLL" ]] || {
  echo "ERROR: Moonbase candidate DLL was not produced." >&2
  exit 1
}
CANDIDATE_SHA="$(sha256sum "$CANDIDATE_DLL" | awk '{print $1}')"
echo "moonbase_candidate_sha256=$CANDIDATE_SHA"

printf '\n[3/5] Resolving the actual live Jellyfin/Moonfin paths...\n'
JELLYFIN="$(find_jellyfin_container)"
CONFIG_HOST="$(container_config_host "$JELLYFIN")"
PLUGIN_ROOT="$CONFIG_HOST/data/plugins"
[[ -d "$PLUGIN_ROOT" ]] || {
  echo "ERROR: expected Jellyfin plugin root not found at $PLUGIN_ROOT" >&2
  exit 1
}
PLUGIN_DLL="$(find_plugin_dll "$PLUGIN_ROOT")"
PLUGIN_DIR="$(dirname "$PLUGIN_DLL")"
FRONTEND="$PLUGIN_DIR/frontend"
CATALOGUE_DIR="$PLUGIN_ROOT/configurations/Moonfin"
CATALOGUE="$CATALOGUE_DIR/discovery.catalogue.json"
[[ -f "$FRONTEND/homelab-build-manifest.json" ]] || {
  echo "ERROR: accepted custom Moonfin Web manifest is not present in $FRONTEND" >&2
  exit 1
}
CURRENT_WEB_COMMIT="$(python3 - "$FRONTEND/homelab-build-manifest.json" <<'PY'
import json, sys
print(str(json.load(open(sys.argv[1], encoding='utf-8')).get('sourceCommit') or ''))
PY
)"
EXPECTED_WEB="9be74475d0ff7dfed6a573a5f8a9e5225b8331e6"
[[ "$CURRENT_WEB_COMMIT" == "$EXPECTED_WEB" ]] || {
  echo "ERROR: live custom Web baseline changed; refusing server mutation." >&2
  echo "expected_web_commit=$EXPECTED_WEB" >&2
  echo "actual_web_commit=${CURRENT_WEB_COMMIT:-missing}" >&2
  exit 1
}

echo "jellyfin_container=$JELLYFIN"
echo "moonfin_plugin_dir=$PLUGIN_DIR"
echo "catalogue_target=$CATALOGUE"
echo "web_source_commit=$CURRENT_WEB_COMMIT"

printf '\n[4/5] Creating rollback data...\n'
BACKUP="$BACKUP_ROOT/moonbase-discovery-$STAMP"
mkdir -p "$BACKUP"
"${P[@]}" cp -a "$PLUGIN_DIR" "$BACKUP/plugin"
if [[ -f "$CATALOGUE" ]]; then
  "${P[@]}" cp -a "$CATALOGUE" "$BACKUP/catalogue.original.json"
fi
cp "$COMPILED" "$BACKUP/catalogue.candidate.json"
cp "$DIAGNOSTICS" "$BACKUP/compile.diagnostics.json"
printf '%s\n' "$PLUGIN_DIR" > "$BACKUP/plugin-path.txt"
printf '%s\n' "$CATALOGUE" > "$BACKUP/catalogue-path.txt"
printf '%s\n' "$CANDIDATE_SHA" > "$BACKUP/candidate-dll.sha256"
printf '%s\n' "$BACKUP" > "$STATE/discovery-server-latest-backup"

echo "rollback_backup=$BACKUP"

if [[ "$MODE" == "prepare" ]]; then
  printf '\nDISCOVERY SERVER PREPARE PASS\n'
  echo "No live files were changed."
  echo "candidate_dll=$CANDIDATE_DLL"
  echo "compiled_catalogue=$COMPILED"
  exit 0
fi

printf '\n[5/5] Installing only Moonfin.Server.dll + Discovery catalogue...\n'
rollback_on_error() {
  local rc=$?
  trap - ERR INT TERM
  echo "ERROR: apply failed; restoring the exact pre-change plugin and catalogue." >&2
  restore_backup "$BACKUP" "$JELLYFIN" "$PLUGIN_DIR" "$CATALOGUE" || true
  exit "$rc"
}
trap rollback_on_error ERR INT TERM

DLL_OWNER="$(stat -c '%u:%g' "$PLUGIN_DLL")"
DLL_MODE="$(stat -c '%a' "$PLUGIN_DLL")"
"${D[@]}" stop "$JELLYFIN" >/dev/null

"${P[@]}" install -o "${DLL_OWNER%:*}" -g "${DLL_OWNER#*:}" -m "$DLL_MODE" \
  "$CANDIDATE_DLL" "$PLUGIN_DLL.new"
"${P[@]}" mv -f "$PLUGIN_DLL.new" "$PLUGIN_DLL"

"${P[@]}" mkdir -p "$CATALOGUE_DIR"
CAT_OWNER="$(stat -c '%u:%g' "$PLUGIN_ROOT")"
"${P[@]}" install -o "${CAT_OWNER%:*}" -g "${CAT_OWNER#*:}" -m 0644 \
  "$COMPILED" "$CATALOGUE.new"
"${P[@]}" mv -f "$CATALOGUE.new" "$CATALOGUE"

"${D[@]}" start "$JELLYFIN" >/dev/null
wait_for_jellyfin

"${P[@]}" env \
  MOONFIN_JELLYFIN_URL=http://127.0.0.1:8096 \
  MOONFIN_EXPECTED_WEB_COMMIT="$EXPECTED_WEB" \
  python3 "$ROOT/tooling/discovery/home_lab_discovery_verify_live.py"

INSTALLED_SHA="$(sha256sum "$PLUGIN_DLL" | awk '{print $1}')"
[[ "$INSTALLED_SHA" == "$CANDIDATE_SHA" ]] || {
  echo "ERROR: installed DLL checksum does not match candidate." >&2
  false
}

trap - ERR INT TERM
printf '%s\n' "$INSTALLED_SHA" > "$STATE/discovery-server-latest-dll-sha256"
printf '%s\n' "$CATALOGUE" > "$STATE/discovery-server-latest-catalogue"
printf '%s\n' "$MOONBASE_VERSION" > "$STATE/discovery-server-latest-version"

printf '\nDISCOVERY SERVER FOUNDATION APPLY PASS\n'
echo "moonbase_version=$MOONBASE_VERSION"
echo "dll_sha256=$INSTALLED_SHA"
echo "catalogue=$CATALOGUE"
echo "rollback_backup=$BACKUP"
echo "accepted_web_commit=$EXPECTED_WEB"
