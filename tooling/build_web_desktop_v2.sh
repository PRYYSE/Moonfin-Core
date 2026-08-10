#!/usr/bin/env bash
set -Eeuo pipefail

MODE="${1:-final}"
SRC="/opt/src/moonfin-core"
DEV="/opt/src/moonfin-dev"
IMAGE="homelab-flutter:3.44.1"
FLUTTER_VERSION="3.44.1"

[[ "$MODE" == "prepare" || "$MODE" == "final" ]] || {
  echo "Usage: $0 [prepare|final]" >&2
  exit 2
}

if docker info >/dev/null 2>&1; then
  D=(docker)
else
  D=(sudo docker)
fi

mkdir -p "$DEV/logs" "$DEV/output" "$DEV/pub-cache"
LOG="$DEV/logs/web-desktop-v2-${MODE}-$(date +%Y%m%d-%H%M%S).log"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

FORMAT_CMD='dart format'
if [[ "$MODE" == "final" ]]; then
  FORMAT_CMD='dart format --output=none --set-exit-if-changed'
fi

set +e
"${D[@]}" run --rm \
  --user "$HOST_UID:$HOST_GID" \
  -e HOME=/home/builder \
  -e PUB_CACHE=/home/builder/.pub-cache \
  -e PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -v "$SRC:/workspace" \
  -v "$DEV/pub-cache:/home/builder/.pub-cache" \
  -w /workspace \
  "$IMAGE" bash -c "
    set -Eeuo pipefail
    flutter pub get
    $FORMAT_CMD \\
      lib/ui/screens/home/home_screen.dart \\
      lib/ui/screens/home/home_view_model.dart \\
      lib/ui/screens/home/homelab_home_composer.dart \\
      lib/ui/screens/hubs/homelab_hub_screen.dart \\
      lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart \\
      lib/ui/widgets/media_bar.dart
    git diff --check
    flutter analyze --no-fatal-warnings --no-fatal-infos \\
      lib/ui/screens/home \\
      lib/ui/screens/hubs \\
      lib/ui/widgets/media_bar.dart
    flutter build web --wasm --release --base-href '/Moonfin/Web/'
  " 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
set -e

if [[ "$rc" -ne 0 ]]; then
  echo "BUILD FAILED: $LOG" >&2
  tail -n 100 "$LOG" >&2
  exit "$rc"
fi

cat > "$SRC/build/web/config.json" <<'JSON'
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

commit="$(git -C "$SRC" rev-parse HEAD)"
cat > "$SRC/build/web/homelab-build-manifest.json" <<JSON
{
  "schemaVersion": 1,
  "prototype": "homelab-hubs-v1",
  "design": "web-desktop-v2-candidate",
  "sourceCommit": "$commit",
  "sourceOwned": true,
  "builder": "docker01",
  "flutterVersion": "$FLUTTER_VERSION",
  "theme": "home_lab_streaming"
}
JSON

OUT="$DEV/output/homelab-moonfin-web-v2-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$OUT" -C "$SRC/build/web" .
sha256sum "$OUT" > "$OUT.sha256"
printf '%s\n' "$OUT" > "$DEV/state/web-desktop-v2-latest-bundle"

echo
echo "V2 BUILD PASS"
echo "Mode: $MODE"
echo "Commit: $commit"
echo "Bundle: $OUT"
echo "Log: $LOG"
echo "Git status:"
git -C "$SRC" status --short
