#!/usr/bin/env bash
set -Eeuo pipefail

SRC=/opt/src/moonfin-core
DEV=/opt/src/moonfin-dev
IMAGE=ghcr.io/gmeligio/flutter-android:3.44.1
BRANCH=homelab/android-v1-staging
PRODUCT_COMMIT=e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86
SIGN_ROOT=/srv/appdata/moonfin/android-signing
PLUGIN_ROOT=/srv/appdata/jellyfin/data/plugins
BASE=http://127.0.0.1:8096
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="/srv/appdata/jellyfin/backups/android-release-v1-postbuild-$STAMP"
PUBLIC_NAME=Moonfin_HomeLab_Android_v1.apk
SOURCE_APK="$SRC/build/app/outputs/flutter-apk/app-mobile-beta-release.apk"

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

[[ "$(git branch --show-current)" == "$BRANCH" ]] || fail "Expected branch $BRANCH."
git merge-base --is-ancestor "$PRODUCT_COMMIT" HEAD || fail 'Built Android product commit is not an ancestor.'
[[ -z "$(git status --porcelain)" ]] || {
  git status --short
  fail 'Source tree is dirty; post-build finalisation stopped.'
}

mapfile -t AFTER_PRODUCT < <(git diff --name-only "$PRODUCT_COMMIT..HEAD")
for path in "${AFTER_PRODUCT[@]}"; do
  case "$path" in
    tooling/build_android_release_v1.sh|tooling/finalise_android_release_v1_postbuild.sh) ;;
    *) fail "Non-tooling source changed after the built product: $path" ;;
  esac
done

HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
CONFIG_APPLIED=0
DOWNLOAD_PUBLISHED=0
PLUGIN_DIR=''
DOWNLOAD_DIR=''

sudo mkdir -p "$RUN"
sudo chown "$HOST_UID:$HOST_GID" "$RUN"
chmod 700 "$RUN"

restore_after_failure() {
  rc=$?
  trap - EXIT
  set +e
  if [[ "$DOWNLOAD_PUBLISHED" == 1 && -n "$DOWNLOAD_DIR" ]]; then
    sudo rm -f "$DOWNLOAD_DIR/$PUBLIC_NAME" "$DOWNLOAD_DIR/$PUBLIC_NAME.sha256"
    for file in "$PUBLIC_NAME" "$PUBLIC_NAME.sha256"; do
      if [[ -f "$RUN/download-before/$file" ]]; then
        sudo cp -a "$RUN/download-before/$file" "$DOWNLOAD_DIR/$file"
      fi
    done
  fi
  if [[ "$CONFIG_APPLIED" == 1 ]]; then
    sudo env PYTHONPATH="$SRC/tooling" python3 \
      "$SRC/tooling/home_lab_android_config.py" restore \
      --backup-dir "$RUN/moonbase" >/dev/null 2>&1 || true
  fi
  if [[ $rc -ne 0 ]]; then
    echo
    echo '=== ANDROID POST-BUILD FINALISATION FAILED: AUTOMATIC RESTORE ===' >&2
    echo "Rollback data: $RUN" >&2
  fi
  exit "$rc"
}
trap restore_after_failure EXIT

printf '=== 1. VERIFY EXISTING BUILT APK ===\n'
[[ -f "$SOURCE_APK" ]] || fail 'Completed Android APK is missing; no rebuild was started.'
APK_SIZE="$(stat -c '%s' "$SOURCE_APK")"
(( APK_SIZE >= 50000000 )) || fail "Existing APK is unexpectedly small: $APK_SIZE bytes."
echo "BUILT APK REUSED: $SOURCE_APK ($APK_SIZE bytes)"

OUT="$DEV/output/Moonfin_HomeLab_Android_v1-$PRODUCT_COMMIT.apk"
install -m 644 "$SOURCE_APK" "$OUT"
(cd "$(dirname "$OUT")" && sha256sum "$(basename "$OUT")") >"$OUT.sha256"

python3 - "$OUT" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as apk:
    names = set(apk.namelist())
    app_abis = {
        name.split('/')[1]
        for name in names
        if name.startswith('lib/') and name.endswith('/libapp.so')
    }
    packaged_abis = {
        name.split('/')[1]
        for name in names
        if name.startswith('lib/') and len(name.split('/')) >= 3
    }

if app_abis != {'arm64-v8a'}:
    raise SystemExit(f'APK ARCHITECTURE FAILED: Flutter app ABIs are {sorted(app_abis)}')
print('APK ARCHITECTURE PASS: Flutter AOT is arm64-v8a only')
print(f'Dependency native ABIs retained: {sorted(packaged_abis)}')
PY

printf '\n=== 2. VERIFY DURABLE APK SIGNING ===\n'
KEYSTORE="$SIGN_ROOT/release.keystore"
PROPERTIES="$SIGN_ROOT/keystore.properties"
[[ -f "$KEYSTORE" && -f "$PROPERTIES" ]] || fail 'Durable Android signing material is missing.'
"${D[@]}" image inspect "$IMAGE" >/dev/null 2>&1 || fail 'Pinned Android build image is unavailable.'
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
echo 'APK SIGNING PASS'

printf '\n=== 3. APPLY AND VALIDATE SERVER-OWNED MOBILE PROFILE ===\n'
python3 -m py_compile \
  tooling/home_lab_safe_auth.py \
  tooling/home_lab_web_refinement_config.py \
  tooling/home_lab_android_config.py
sudo env PYTHONPATH="$SRC/tooling" python3 \
  "$SRC/tooling/home_lab_android_config.py" apply \
  --backup-dir "$RUN/moonbase"
CONFIG_APPLIED=1
sudo env PYTHONPATH="$SRC/tooling" python3 \
  "$SRC/tooling/home_lab_android_config.py" validate

printf '\n=== 4. PUBLISH APK TO THE TAILNET/LAN DOWNLOAD ROUTE ===\n'
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
echo "Built product commit: $PRODUCT_COMMIT"
echo "Validation tooling: $(git rev-parse HEAD)"
echo "APK: $OUT"
echo "SHA256: $OUT.sha256"
echo "Signing identity: $SIGNING_DIGEST"
echo "Rollback/config backup: $RUN"
echo 'Build: REUSED + PASS'
echo 'Flutter AOT architecture: ARM64 + PASS'
echo 'Moonbase mobile rows/theme/personalisation: PASS'
echo 'Signed APK and served download: PASS'
echo "Download (Tailscale MagicDNS): http://docker01:8096/Moonfin/Web/downloads/$PUBLIC_NAME"
echo "Download (LAN): http://192.168.50.12:8096/Moonfin/Web/downloads/$PUBLIC_NAME"
