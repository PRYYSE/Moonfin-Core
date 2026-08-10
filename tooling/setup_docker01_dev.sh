#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/PRYYSE/Moonfin-Core.git"
BRANCH="homelab/hubs-v1"
SRC="/opt/src/moonfin-core"
DEV="/opt/src/moonfin-dev"
FLUTTER_VERSION="3.44.1"
IMAGE="homelab-flutter:${FLUTTER_VERSION}"

HOST_UID="${SUDO_UID:-$(id -u)}"
HOST_GID="${SUDO_GID:-$(id -g)}"
HOST_USER="$(getent passwd "$HOST_UID" | cut -d: -f1 || true)"
HOST_USER="${HOST_USER:-$(id -un)}"

if [[ "$EUID" -eq 0 ]]; then
  SUDO=()
else
  SUDO=(sudo)
fi

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

printf 'Home Lab Moonfin docker01 development setup\n'
printf 'Source: %s\n' "$SRC"
printf 'Build tooling: %s\n' "$DEV"
printf 'Flutter: %s\n\n' "$FLUTTER_VERSION"

if ! command -v git >/dev/null 2>&1; then
  "${SUDO[@]}" apt-get update
  "${SUDO[@]}" apt-get install -y git ca-certificates
fi

command -v docker >/dev/null 2>&1 || fail "Docker is not installed on docker01."

if docker info >/dev/null 2>&1; then
  DOCKER=(docker)
elif "${SUDO[@]}" docker info >/dev/null 2>&1; then
  DOCKER=("${SUDO[@]}" docker)
else
  fail "Docker is installed but not accessible."
fi

"${SUDO[@]}" mkdir -p /opt/src "$DEV" "$DEV/backups" "$DEV/logs" "$DEV/output" "$DEV/pub-cache" "$DEV/state"
"${SUDO[@]}" chown -R "$HOST_UID:$HOST_GID" /opt/src

if [[ ! -d "$SRC/.git" ]]; then
  git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$SRC"
else
  remote_url="$(git -C "$SRC" remote get-url origin 2>/dev/null || true)"
  [[ "$remote_url" == "$REPO_URL" ]] || fail "$SRC exists but is not the expected Moonfin-Core clone."

  if [[ -z "$(git -C "$SRC" status --porcelain)" ]]; then
    git -C "$SRC" fetch origin "$BRANCH"
    git -C "$SRC" checkout "$BRANCH"
    git -C "$SRC" merge --ff-only "origin/$BRANCH"
  else
    printf 'Existing source has local edits; preserving them and skipping fetch/merge.\n'
  fi
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$DEV/backups/$STAMP"
mkdir -p "$BACKUP"
git -C "$SRC" status --short > "$BACKUP/status-before.txt"
git -C "$SRC" diff > "$BACKUP/diff-before.patch"
tar -czf "$BACKUP/home-source-before-consolidation.tar.gz" -C "$SRC" \
  lib/ui/screens/home/home_screen.dart \
  lib/ui/screens/home/home_view_model.dart \
  lib/ui/screens/home/homelab_home_composer.dart \
  lib/ui/screens/hubs/homelab_hub_screen.dart \
  lib/ui/navigation/app_router.dart \
  lib/ui/navigation/homelab_hub_routes.dart \
  lib/ui/widgets/left_sidebar.dart \
  lib/ui/widgets/top_toolbar.dart \
  tooling/apply_homelab_hubs_patch.py \
  tooling/apply_homelab_home_redesign_patch.py \
  tooling/apply_homelab_home_visual_polish_patch.py

CONSOLIDATED_MARKER="$DEV/state/source-consolidated"
if [[ ! -f "$CONSOLIDATED_MARKER" ]]; then
  printf '\nOne-time source consolidation...\n'
  cd "$SRC"

  # These recovery helpers are used only to materialise the work already designed.
  # They are not part of the normal Docker build path below.
  python3 tooling/apply_homelab_hubs_patch.py

  if grep -q 'HomelabHomeComposer.augmentConfigs' lib/ui/screens/home/home_view_model.dart; then
    printf 'Home composer wiring already materialised; structural patch skipped.\n'
  else
    python3 tooling/apply_homelab_home_redesign_patch.py
  fi

  if grep -q "homelab_web_backdrop_" lib/ui/screens/home/home_screen.dart && \
     grep -q 'if (kIsWeb && !PlatformDetection.useMobileUi) return false;' lib/ui/screens/home/home_screen.dart; then
    printf 'Home visual polish already materialised; visual recovery patch skipped.\n'
  else
    python3 tooling/apply_homelab_home_visual_polish_patch.py
  fi

  printf '%s\n' "$(git rev-parse HEAD)" > "$CONSOLIDATED_MARKER"
  printf 'One-time source consolidation complete. Future builds do not run patch scripts.\n'
fi

cat > "$DEV/Dockerfile.flutter" <<EOF
FROM debian:bookworm-slim
ARG FLUTTER_VERSION=${FLUTTER_VERSION}
ARG HOST_UID=${HOST_UID}
ARG HOST_GID=${HOST_GID}
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash ca-certificates curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*
RUN groupadd -g \${HOST_GID} builder \
    && useradd -m -u \${HOST_UID} -g \${HOST_GID} -s /bin/bash builder
RUN git clone --depth 1 --branch \${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter \
    && chown -R builder:builder /opt/flutter
ENV HOME=/home/builder
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:\${PATH}
ENV PUB_CACHE=/home/builder/.pub-cache
USER builder
RUN flutter config --no-analytics --enable-web \
    && flutter precache --web \
    && flutter --version
WORKDIR /workspace
EOF

cat > "$DEV/build.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
SRC="/opt/src/moonfin-core"
DEV="/opt/src/moonfin-dev"
FLUTTER_VERSION="3.44.1"
IMAGE="homelab-flutter:${FLUTTER_VERSION}"
HOST_UID="${SUDO_UID:-$(id -u)}"
HOST_GID="${SUDO_GID:-$(id -g)}"

if docker info >/dev/null 2>&1; then
  DOCKER=(docker)
else
  DOCKER=(sudo docker)
fi

mkdir -p "$DEV/logs" "$DEV/output" "$DEV/pub-cache"
LOG="$DEV/logs/build-$(date +%Y%m%d-%H%M%S).log"

set +e
"${DOCKER[@]}" run --rm \
  --user "$HOST_UID:$HOST_GID" \
  -e HOME=/home/builder \
  -e PUB_CACHE=/home/builder/.pub-cache \
  -v "$SRC:/workspace" \
  -v "$DEV/pub-cache:/home/builder/.pub-cache" \
  -w /workspace \
  "$IMAGE" bash -lc '
    set -Eeuo pipefail
    flutter pub get
    dart format \
      lib/ui/navigation/app_router.dart \
      lib/ui/navigation/homelab_hub_routes.dart \
      lib/ui/screens/home/home_screen.dart \
      lib/ui/screens/home/home_view_model.dart \
      lib/ui/screens/home/homelab_home_composer.dart \
      lib/ui/screens/hubs/homelab_hub_screen.dart \
      lib/ui/widgets/left_sidebar.dart \
      lib/ui/widgets/top_toolbar.dart
    git diff --check
    flutter analyze --no-fatal-warnings --no-fatal-infos
    flutter build web --wasm --release --base-href "/Moonfin/Web/"
  ' 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
set -e

if [[ "$rc" -ne 0 ]]; then
  printf '\nBUILD FAILED. Relevant tail from %s:\n' "$LOG" >&2
  tail -n 120 "$LOG" >&2
  exit "$rc"
fi

cat > "$SRC/build/web/config.json" <<'JSON'
{
  "schemaVersion": 1,
  "defaultServerUrl": null,
  "discoveryProxyUrl": null,
  "enableWebRtcScan": true,
  "brandingName": "Moonfin Home Lab",
  "pluginMode": true,
  "forcedServerUrl": null
}
JSON

commit="$(git -C "$SRC" rev-parse HEAD)"
cat > "$SRC/build/web/homelab-build-manifest.json" <<JSON
{
  "schemaVersion": 1,
  "prototype": "homelab-hubs-v1",
  "design": "home-web-comprehensive-v1",
  "sourceCommit": "$commit",
  "sourceOwned": true,
  "builder": "docker01",
  "flutterVersion": "$FLUTTER_VERSION"
}
JSON

OUT="$DEV/output/homelab-moonfin-web-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$OUT" -C "$SRC/build/web" .
sha256sum "$OUT" > "$OUT.sha256"

printf '\nBUILD PASS\n'
printf 'Source: %s\n' "$SRC"
printf 'Bundle: %s\n' "$OUT"
printf 'Git status after build:\n'
git -C "$SRC" status --short
EOF
chmod +x "$DEV/build.sh"

printf '\nBuilding pinned Flutter container (cached after first build)...\n'
"${DOCKER[@]}" build \
  --build-arg FLUTTER_VERSION="$FLUTTER_VERSION" \
  --build-arg HOST_UID="$HOST_UID" \
  --build-arg HOST_GID="$HOST_GID" \
  -t "$IMAGE" \
  -f "$DEV/Dockerfile.flutter" "$DEV"

printf '\nRunning first persistent-source web validation/build...\n'
"$DEV/build.sh"
