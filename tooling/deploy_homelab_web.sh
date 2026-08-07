#!/usr/bin/env bash
set -euo pipefail

REPO="PRYYSE/Moonfin-Core"
TAG="homelab-hubs-v1-latest"
BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
APPDATA="/srv/appdata/jellyfin"
PLUGIN_ROOT="${APPDATA}/data/plugins"
BACKUP_ROOT="${APPDATA}/backups"

for cmd in curl tar sha256sum docker grep stat; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $cmd"
    exit 1
  }
done

PLUGIN_DIR=""
for candidate in "${PLUGIN_ROOT}"/Moonbase_* "${PLUGIN_ROOT}"/Moonfin*; do
  if [ -d "$candidate" ] && [ -f "$candidate/Moonfin.Server.dll" ]; then
    PLUGIN_DIR="$candidate"
  fi
done

if [ -z "$PLUGIN_DIR" ]; then
  echo "ERROR: could not find the installed Moonbase/Moonfin plugin directory."
  exit 1
fi

FRONTEND="${PLUGIN_DIR}/frontend"
if [ ! -f "${FRONTEND}/index.html" ]; then
  echo "ERROR: expected Moonfin frontend not found at ${FRONTEND}."
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
TMP="$(mktemp -d)"
STAGE="${PLUGIN_DIR}/.frontend-homelab-stage-${STAMP}"
BACKUP="${BACKUP_ROOT}/moonfin-web-${STAMP}"
TARBALL="${TMP}/homelab-moonfin-web.tar.gz"
SHA_FILE="${TMP}/homelab-moonfin-web.tar.gz.sha256"

cleanup() {
  rm -rf "$TMP" "$STAGE" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$BACKUP_ROOT"

echo "Moonfin plugin: $PLUGIN_DIR"
echo "Waiting for the latest Home Lab web bundle..."

READY=0
for attempt in $(seq 1 45); do
  if curl -fL --connect-timeout 10 --max-time 120 \
      "${BASE_URL}/homelab-moonfin-web.tar.gz" -o "$TARBALL" 2>/dev/null && \
     curl -fL --connect-timeout 10 --max-time 60 \
      "${BASE_URL}/homelab-moonfin-web.tar.gz.sha256" -o "$SHA_FILE" 2>/dev/null; then
    READY=1
    break
  fi
  rm -f "$TARBALL" "$SHA_FILE"
  if [ "$attempt" -eq 45 ]; then
    break
  fi
  printf '  build not published yet; retrying in 20 seconds (%s/45)\n' "$attempt"
  sleep 20
done

if [ "$READY" -ne 1 ]; then
  echo "ERROR: prototype bundle was not published within 15 minutes."
  exit 1
fi

(
  cd "$TMP"
  sha256sum -c "$(basename "$SHA_FILE")"
)

CONTENTS="$(tar -tzf "$TARBALL" | sed 's#^\./##')"
printf '%s\n' "$CONTENTS" | grep -qx 'index.html' || {
  echo "ERROR: bundle does not contain index.html."
  exit 1
}
printf '%s\n' "$CONTENTS" | grep -qx 'homelab-build-manifest.json' || {
  echo "ERROR: bundle does not contain the Home Lab build manifest."
  exit 1
}

mkdir -p "$STAGE"
tar -xzf "$TARBALL" -C "$STAGE"
grep -q '"prototype": "homelab-hubs-v1"' \
  "$STAGE/homelab-build-manifest.json" || {
  echo "ERROR: bundle manifest is not the Home Lab hubs prototype."
  exit 1
}

OWNER="$(stat -c '%u:%g' "$FRONTEND")"
chown -R "$OWNER" "$STAGE"

mkdir -p "$BACKUP"
cp "$STAGE/homelab-build-manifest.json" "$BACKUP/new-build-manifest.json"

rollback() {
  echo "Validation failed. Rolling back the original Moonfin Web frontend..."
  docker stop jellyfin >/dev/null 2>&1 || true
  if [ -d "$FRONTEND" ]; then
    mv "$FRONTEND" "$BACKUP/failed-frontend" 2>/dev/null || rm -rf "$FRONTEND"
  fi
  if [ -d "$BACKUP/frontend" ]; then
    mv "$BACKUP/frontend" "$FRONTEND"
  fi
  docker start jellyfin >/dev/null
  sleep 8
  echo "Rollback complete."
  exit 1
}

printf '\nDeploying prototype...\n'
docker stop jellyfin >/dev/null
mv "$FRONTEND" "$BACKUP/frontend"
mv "$STAGE" "$FRONTEND"
docker start jellyfin >/dev/null

HTTP_CODE=""
for _ in $(seq 1 30); do
  HTTP_CODE="$(curl -sS -o /dev/null -w '%{http_code}' \
    http://127.0.0.1:8096/Moonfin/Web/ || true)"
  [ "$HTTP_CODE" = "200" ] && break
  sleep 2
done

[ "$HTTP_CODE" = "200" ] || rollback

SERVED_MANIFEST="$(curl -fsS \
  http://127.0.0.1:8096/Moonfin/Web/homelab-build-manifest.json || true)"
printf '%s' "$SERVED_MANIFEST" | grep -q '"prototype": "homelab-hubs-v1"' || rollback

printf '\nMOONFIN HUB PROTOTYPE DEPLOYED\n'
echo "Moonfin Web: HTTP 200"
echo "Prototype manifest: confirmed"
echo "Rollback backup: $BACKUP"
echo "Open: http://192.168.50.12:8096/Moonfin/Web/"
