#!/usr/bin/env bash
set -Eeuo pipefail

SRC=/opt/src/moonfin-core
DEV=/opt/src/moonfin-dev
IMAGE=ghcr.io/gmeligio/flutter-android:3.44.1
BRANCH=homelab/android-v1-staging
WEB_REFERENCE=9be74475d0ff7dfed6a573a5f8a9e5225b8331e6
SIGN_ROOT=/srv/appdata/moonfin/android-signing
PLUGIN_ROOT=/srv/appdata/jellyfin/data/plugins
BASE=http://127.0.0.1:8096
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="/srv/appdata/jellyfin/backups/android-release-v1-$STAMP"
LOG="$DEV/logs/android-release-v1-$STAMP.log"
PUBLIC_NAME=Moonfin_HomeLab_Android_v1.apk
NDK_CACHE="$DEV/android-sdk-ndk-cache"

mkdir -p "$DEV/logs" "$DEV/state" "$DEV/output" \
  "$DEV/android-builder-home/.pub-cache" \
  "$DEV/android-builder-home/.gradle" \
  "$DEV/android-builder-home/.android" \
  "$NDK_CACHE"
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

command -v git >/dev/null 2>&1 || fail 'git is missing.'
command -v openssl >/dev/null 2>&1 || fail 'openssl is missing.'
[[ "$(git branch --show-current)" == "$BRANCH" ]] || fail "Expected branch $BRANCH."
git merge-base --is-ancestor "$WEB_REFERENCE" HEAD || fail 'Release-ready Web reference is not an ancestor.'
[[ -z "$(git status --porcelain)" ]] || {
  git status --short
  fail 'Source tree is dirty; no files were changed.'
}

COMMIT="$(git rev-parse HEAD)"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
CONFIG_APPLIED=0
DOWNLOAD_PUBLISHED=0
PLUGIN_DIR=''
DOWNLOAD_DIR=''

sudo chown -R "$HOST_UID:$HOST_GID" \
  "$DEV/android-builder-home" "$NDK_CACHE" 2>/dev/null || true
sudo mkdir -p "$RUN" "$SIGN_ROOT"
sudo chown "$HOST_UID:$HOST_GID" "$RUN" "$SIGN_ROOT"
chmod 700 "$RUN" "$SIGN_ROOT"

restore_after_failure() {
  rc=$?
  trap - EXIT
  set +e
  if [[ "$DOWNLOAD_PUBLISHED" == 1 && -n "$DOWNLOAD_DIR" ]]; then
    sudo rm -f "$DOWNLOAD_DIR/$PUBLIC_NAME" "$DOWNLOAD_DIR/$PUBLIC_NAME.sha256"
    if [[ -f "$RUN/download-before/$PUBLIC_NAME" ]]; then
      sudo cp -a "$RUN/download-before/$PUBLIC_NAME" "$DOWNLOAD_DIR/$PUBLIC_NAME"
    fi
    if [[ -f "$RUN/download-before/$PUBLIC_NAME.sha256" ]]; then
      sudo cp -a "$RUN/download-before/$PUBLIC_NAME.sha256" "$DOWNLOAD_DIR/$PUBLIC_NAME.sha256"
    fi
  fi
  if [[ "$CONFIG_APPLIED" == 1 ]]; then
    sudo env PYTHONPATH="$SRC/tooling" python3 \
      "$SRC/tooling/home_lab_android_config.py" restore \
      --backup-dir "$RUN/moonbase" >/dev/null 2>&1 || true
  fi
  rm -f "$SIGN_ROOT/release.keystore.tmp" \
    "$SIGN_ROOT/keystore.properties.tmp" 2>/dev/null || true
  sudo chown -R "$HOST_UID:$HOST_GID" \
    "$DEV/android-builder-home" "$NDK_CACHE" \
    "$SRC/.dart_tool" "$SRC/build" 2>/dev/null || true
  sudo chown "$HOST_UID:$HOST_GID" "$SRC/pubspec.lock" 2>/dev/null || true
  if [[ $rc -ne 0 ]]; then
    echo
    echo '=== ANDROID RELEASE V1 FAILED: AUTOMATIC RESTORE ===' >&2
    echo "Rollback data: $RUN" >&2
    echo "Log: $LOG" >&2
  fi
  exit "$rc"
}
trap restore_after_failure EXIT

printf '=== 1. SOURCE AND TOOLING PREFLIGHT ===\n'
python3 -m py_compile \
  tooling/home_lab_safe_auth.py \
  tooling/home_lab_web_refinement_config.py \
  tooling/home_lab_android_config.py

grep -Fq 'PlatformDetection.isAndroid && PlatformDetection.useMobileUi' \
  lib/ui/screens/hubs/homelab_hub_screen.dart || fail 'Android destination routing is missing.'
grep -Fq 'required this.compact' \
  lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart || fail 'Android responsive layout is missing.'
grep -Fq 'PlatformDetection.isAndroid && PlatformDetection.useMobileUi' \
  lib/ui/screens/home/homelab_home_composer.dart || fail 'Android Home composition is missing.'
echo "SOURCE PREFLIGHT PASS: $COMMIT"

printf '\n=== 2. VERIFY COMPLETE ANDROID BUILD TOOLCHAIN ===\n'
if ! "${D[@]}" image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Pulling pinned Android build image: $IMAGE"
  "${D[@]}" pull "$IMAGE"
fi
"${D[@]}" run --rm --entrypoint /bin/bash "$IMAGE" -c '
  set -Eeuo pipefail
  for tool in flutter java keytool sdkmanager; do
    resolved="$(command -v "$tool" || true)"
    if [[ -z "$resolved" ]]; then
      echo "ANDROID TOOLCHAIN FAILED: $tool is missing" >&2
      exit 1
    fi
    echo "TOOL PASS: $tool -> $resolved"
  done
  [[ -d "${ANDROID_HOME:?ANDROID_HOME is unset}" ]] || {
    echo "ANDROID TOOLCHAIN FAILED: ANDROID_HOME is unavailable" >&2
    exit 1
  }
  [[ -d "$ANDROID_HOME/platforms/android-36" ]] || {
    echo "ANDROID TOOLCHAIN FAILED: Android platform 36 is missing" >&2
    exit 1
  }
  [[ -d "$ANDROID_HOME/ndk/28.2.13676358" ]] || {
    echo "ANDROID TOOLCHAIN FAILED: NDK 28.2.13676358 is missing" >&2
    exit 1
  }
  apksigner="$(find "$ANDROID_HOME/build-tools" -type f -name apksigner -perm -u+x 2>/dev/null | sort -V | tail -n 1)"
  [[ -n "$apksigner" ]] || {
    echo "ANDROID TOOLCHAIN FAILED: apksigner is missing" >&2
    exit 1
  }
  echo "TOOL PASS: apksigner -> $apksigner"
  flutter --version > /tmp/flutter-version.txt
  cat /tmp/flutter-version.txt
  grep -F "Flutter 3.44.1" /tmp/flutter-version.txt >/dev/null || {
    echo "ANDROID TOOLCHAIN FAILED: wrong Flutter version" >&2
    exit 1
  }
  java -version > /tmp/java-version.txt 2>&1
  cat /tmp/java-version.txt
  grep -F "17." /tmp/java-version.txt >/dev/null || {
    echo "ANDROID TOOLCHAIN FAILED: Java 17 is required" >&2
    exit 1
  }
  printf "ANDROID TOOLCHAIN PASS: Flutter 3.44.1 + Java 17 + SDK + keytool\n"
'

printf '\n=== 3. ESTABLISH OR REUSE DURABLE ANDROID SIGNING ===\n'
KEYSTORE="$SIGN_ROOT/release.keystore"
PROPERTIES="$SIGN_ROOT/keystore.properties"
if [[ -f "$PROPERTIES" && ! -e "$KEYSTORE" ]]; then
  echo 'Removing incomplete properties file left by the failed Web-image signing attempt.'
  rm -f "$PROPERTIES"
fi
if [[ -e "$KEYSTORE" || -e "$PROPERTIES" ]]; then
  [[ -f "$KEYSTORE" && -f "$PROPERTIES" ]] || fail 'Android signing material is incomplete; the existing keystore was preserved.'
  echo 'DURABLE SIGNING: REUSED'
else
  umask 077
  STORE_PASSWORD="$(openssl rand -hex 32)"
  printf 'storePassword=%s\nkeyPassword=%s\nkeyAlias=moonfin-homelab\nstoreFile=release.keystore\n' \
    "$STORE_PASSWORD" "$STORE_PASSWORD" >"$SIGN_ROOT/keystore.properties.tmp"
  "${D[@]}" run --rm \
    --user "$HOST_UID:$HOST_GID" \
    -e HOME=/tmp \
    -v "$SIGN_ROOT:/signing" \
    --entrypoint /bin/bash \
    "$IMAGE" -c \
    'set -Eeuo pipefail; source /signing/keystore.properties.tmp; keytool -genkeypair -v -keystore /signing/release.keystore.tmp -storepass "$storePassword" -keypass "$keyPassword" -alias "$keyAlias" -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Moonfin Home Lab, O=Home Lab, C=AU" >/dev/null'
  unset STORE_PASSWORD
  mv "$SIGN_ROOT/release.keystore.tmp" "$KEYSTORE"
  mv "$SIGN_ROOT/keystore.properties.tmp" "$PROPERTIES"
  chmod 600 "$KEYSTORE" "$PROPERTIES"
  echo 'DURABLE SIGNING: CREATED'
fi

printf '\n=== 4. DEPENDENCIES, CONTROLLED FORMAT COMMIT AND ANALYSIS ===\n'
cat >"$DEV/android-builder-home/.gradle/gradle.properties" <<'GRADLE_PROPERTIES'
org.gradle.jvmargs=-Xmx1536m -XX:MaxMetaspaceSize=384m -Dfile.encoding=UTF-8
org.gradle.workers.max=1
org.gradle.parallel=false
org.gradle.daemon=false
kotlin.compiler.execution.strategy=in-process
GRADLE_PROPERTIES

COMMON_DOCKER=(
  --rm
  --user 0:0
  --memory 4g
  --memory-swap 5g
  --cpus 3
  --entrypoint /bin/bash
  -e HOME=/home/builder
  -e PUB_CACHE=/home/builder/.pub-cache
  -e GRADLE_USER_HOME=/home/builder/.gradle
  -e GIT_CONFIG_COUNT=1
  -e GIT_CONFIG_KEY_0=safe.directory
  -e GIT_CONFIG_VALUE_0=/home/flutter/sdks/flutter
  -v "$SRC:/workspace"
  -v "$DEV/android-builder-home:/home/builder"
  -v "$NDK_CACHE:/home/flutter/sdks/android-sdk/ndk"
  -v "$KEYSTORE:/workspace/android/app/release.keystore:ro"
  -v "$PROPERTIES:/workspace/android/keystore.properties:ro"
  -w /workspace
)

run_android() {
  "${D[@]}" run "${COMMON_DOCKER[@]}" "$IMAGE" \
    -c 'exec "$@"' android-builder "$@"
}

FORMAT_PATHS=(
  lib/ui/screens/hubs/homelab_hub_screen.dart
  lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart
  lib/ui/screens/home/homelab_home_composer.dart
)

run_android sdkmanager --install 'ndk;27.0.12077973'
[[ -f "$NDK_CACHE/27.0.12077973/source.properties" ]] || fail 'Persistent Android NDK 27 installation is incomplete.'
echo 'PERSISTENT NDK 27 PASS'

run_android flutter pub get
run_android dart format "${FORMAT_PATHS[@]}"
sudo chown -R "$HOST_UID:$HOST_GID" \
  "$DEV/android-builder-home" \
  "$SRC/.dart_tool" "$SRC/build" 2>/dev/null || true
sudo chown "$HOST_UID:$HOST_GID" "$SRC/pubspec.lock" 2>/dev/null || true

git diff --check
mapfile -t FORMAT_CHANGED < <(git diff --name-only)
if (( ${#FORMAT_CHANGED[@]} )); then
  for path in "${FORMAT_CHANGED[@]}"; do
    allowed=0
    for expected in "${FORMAT_PATHS[@]}"; do
      [[ "$path" == "$expected" ]] && allowed=1 && break
    done
    [[ "$allowed" == 1 ]] || fail "Formatter changed an unauthorised path: $path"
  done

  echo 'Controlled formatter changes:'
  printf '  %s\n' "${FORMAT_CHANGED[@]}"
  git add -- "${FORMAT_CHANGED[@]}"
  git commit -m 'Format Android release source'
  git push origin HEAD:"$BRANCH"
  COMMIT="$(git rev-parse HEAD)"
  echo "FORMATTING COMMIT PASS: $COMMIT"
else
  echo 'Source already formatted.'
fi

[[ -z "$(git status --porcelain)" ]] || fail 'Source is dirty after the controlled format commit.'
run_android dart format \
  --output=none --set-exit-if-changed \
  "${FORMAT_PATHS[@]}"
run_android flutter analyze \
  --no-fatal-infos --no-fatal-warnings \
  lib/ui/screens/hubs/homelab_hub_screen.dart \
  lib/ui/screens/hubs/homelab_web_hub_screen_v2_candidate.dart \
  lib/ui/screens/home/homelab_home_composer.dart
sudo chown -R "$HOST_UID:$HOST_GID" \
  "$DEV/android-builder-home" \
  "$SRC/.dart_tool" "$SRC/build" 2>/dev/null || true
sudo chown "$HOST_UID:$HOST_GID" "$SRC/pubspec.lock" 2>/dev/null || true
[[ -z "$(git status --porcelain)" ]] || fail 'Analysis changed committed source.'
echo 'FORMAT/ANALYSIS PASS'

printf '\n=== 5. BUILD SIGNED ANDROID PHONE/TABLET APK ===\n'
timeout --signal=TERM --kill-after=30s 45m \
  "${D[@]}" run "${COMMON_DOCKER[@]}" "$IMAGE" \
    -c 'exec "$@"' android-builder flutter build apk \
    --release --flavor mobile-beta \
    --target-platform android-arm64 \
    --dart-define=DISTRIBUTION_CHANNEL=apk

sudo chown -R "$HOST_UID:$HOST_GID" \
  "$DEV/android-builder-home" \
  "$SRC/.dart_tool" "$SRC/build" 2>/dev/null || true

SOURCE_APK="$SRC/build/app/outputs/flutter-apk/app-mobile-beta-release.apk"
[[ -f "$SOURCE_APK" ]] || fail 'Expected Android APK was not produced.'
OUT="$DEV/output/Moonfin_HomeLab_Android_v1-$COMMIT.apk"
install -m 644 "$SOURCE_APK" "$OUT"
(cd "$(dirname "$OUT")" && sha256sum "$(basename "$OUT")") >"$OUT.sha256"

python3 - "$OUT" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as apk:
    native = {name.split('/')[1] for name in apk.namelist() if name.startswith('lib/')}

if 'arm64-v8a' not in native:
    raise SystemExit('APK ARCHITECTURE FAILED: arm64-v8a payload is missing.')
unexpected = native - {'arm64-v8a'}
if unexpected:
    raise SystemExit(f'APK ARCHITECTURE FAILED: unexpected native ABIs: {sorted(unexpected)}')
print('APK ARCHITECTURE PASS: arm64-v8a only')
PY

"${D[@]}" run --rm \
  -v "$OUT:/candidate.apk:ro" \
  --entrypoint /bin/bash \
  "$IMAGE" -c \
  'set -Eeuo pipefail; sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/opt/android-sdk}}"; tool="$(command -v apksigner || find "$sdk" -type f -name apksigner 2>/dev/null | sort -V | tail -n 1)"; [[ -n "$tool" ]]; "$tool" verify --print-certs /candidate.apk' \
  | tee "$RUN/apksigner.txt"
grep -Fq 'Signer #1 certificate SHA-256 digest:' "$RUN/apksigner.txt" || fail 'APK signing certificate was not verified.'
SIGNING_DIGEST="$(grep -F 'Signer #1 certificate SHA-256 digest:' "$RUN/apksigner.txt" | head -n 1 | cut -d: -f2- | tr -d ' ')"
if [[ -f "$SIGN_ROOT/signing-cert.sha256" ]]; then
  [[ "$(tr -d '[:space:]' <"$SIGN_ROOT/signing-cert.sha256")" == "$SIGNING_DIGEST" ]] || fail 'APK signing identity changed.'
else
  printf '%s\n' "$SIGNING_DIGEST" >"$SIGN_ROOT/signing-cert.sha256"
  chmod 600 "$SIGN_ROOT/signing-cert.sha256"
fi
echo "APK BUILD/SIGNING PASS: $OUT"

printf '\n=== 6. APPLY AND VALIDATE SERVER-OWNED MOBILE PROFILE ===\n'
sudo env PYTHONPATH="$SRC/tooling" python3 \
  "$SRC/tooling/home_lab_android_config.py" apply \
  --backup-dir "$RUN/moonbase"
CONFIG_APPLIED=1
sudo env PYTHONPATH="$SRC/tooling" python3 \
  "$SRC/tooling/home_lab_android_config.py" validate

printf '\n=== 7. PUBLISH APK TO THE TAILNET/LAN DOWNLOAD ROUTE ===\n'
for candidate in "$PLUGIN_ROOT"/Moonbase_* "$PLUGIN_ROOT"/Moonfin*; do
  if [[ -d "$candidate" && -f "$candidate/Moonfin.Server.dll" ]]; then
    PLUGIN_DIR="$candidate"
  fi
done
[[ -n "$PLUGIN_DIR" ]] || fail 'Moonbase/Moonfin plugin directory not found.'
DOWNLOAD_DIR="$PLUGIN_DIR/frontend/downloads"
sudo mkdir -p "$DOWNLOAD_DIR" "$RUN/download-before"
for file in "$PUBLIC_NAME" "$PUBLIC_NAME.sha256"; do
  if sudo test -f "$DOWNLOAD_DIR/$file"; then
    sudo cp -a "$DOWNLOAD_DIR/$file" "$RUN/download-before/$file"
  fi
done
sudo install -m 644 "$OUT" "$DOWNLOAD_DIR/$PUBLIC_NAME"
sudo install -m 644 "$OUT.sha256" "$DOWNLOAD_DIR/$PUBLIC_NAME.sha256"
DOWNLOAD_PUBLISHED=1
VERIFY_APK="$(mktemp)"
curl -fsS "$BASE/Moonfin/Web/downloads/$PUBLIC_NAME" -o "$VERIFY_APK"
[[ "$(sha256sum "$VERIFY_APK" | awk '{print $1}')" == "$(sha256sum "$OUT" | awk '{print $1}')" ]] || fail 'Served APK checksum mismatch.'
rm -f "$VERIFY_APK"
echo 'APK DOWNLOAD ROUTE PASS'

CONFIG_APPLIED=0
DOWNLOAD_PUBLISHED=0
trap - EXIT

echo
echo '=================================================='
echo ' HOME LAB ANDROID V1 CANDIDATE PASS'
echo '=================================================='
echo "Source commit: $COMMIT"
echo "APK: $OUT"
echo "SHA256: $OUT.sha256"
echo "Signing identity: $SIGNING_DIGEST"
echo "Rollback/config backup: $RUN"
echo "Log: $LOG"
echo 'Android phone/tablet responsive UI: PASS'
echo 'Moonbase mobile rows/theme/personalisation: PASS'
echo 'Signed APK and served download: PASS'
echo "Download (Tailscale MagicDNS): http://docker01:8096/Moonfin/Web/downloads/$PUBLIC_NAME"
echo "Download (LAN): http://192.168.50.12:8096/Moonfin/Web/downloads/$PUBLIC_NAME"
