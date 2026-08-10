#!/usr/bin/env bash
set -Eeuo pipefail

SRC="/opt/src/moonfin-core"
DEV="/opt/src/moonfin-dev"
EXPECTED_HEAD="f4fe8fe1e72bfa33fd3a86b80ba88a35512eb7ee"
HUB_SOURCE_COMMIT="90bee5b30c649a93eb7c44f3ec78d0e757627844"
HUB_SOURCE_URL="https://raw.githubusercontent.com/PRYYSE/Moonfin-Core/${HUB_SOURCE_COMMIT}/lib/ui/screens/hubs/homelab_web_hub_screen.dart"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ -d "$SRC/.git" ]] || fail "$SRC is not the persistent Moonfin source tree."
[[ -x "$DEV/build.sh" ]] || fail "$DEV/build.sh is missing."
[[ "$(git -C "$SRC" rev-parse HEAD)" == "$EXPECTED_HEAD" ]] || \
  fail "Expected source commit $EXPECTED_HEAD before the full web pass."
[[ -z "$(git -C "$SRC" status --porcelain)" ]] || {
  git -C "$SRC" status --short >&2
  fail "Source has uncommitted changes. Nothing was changed."
}

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$DEV/backups/web-desktop-v1-$STAMP"
mkdir -p "$BACKUP"

FILES=(
  lib/ui/screens/home/home_view_model.dart
  lib/ui/screens/home/homelab_home_composer.dart
  lib/ui/screens/hubs/homelab_hub_screen.dart
  lib/ui/widgets/media_bar.dart
)

for file in "${FILES[@]}"; do
  mkdir -p "$BACKUP/$(dirname "$file")"
  cp -a "$SRC/$file" "$BACKUP/$file"
done
cp -a "$DEV/build.sh" "$BACKUP/build.sh"
git -C "$SRC" diff --binary > "$BACKUP/diff-before.patch"
printf '%s\n' "$EXPECTED_HEAD" > "$BACKUP/source-head-before.txt"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
curl -fL --connect-timeout 10 --max-time 60 "$HUB_SOURCE_URL" -o "$TMP"
[[ -s "$TMP" ]] || fail "Premium hub source download was empty."
mkdir -p "$SRC/lib/ui/screens/hubs"
cp "$TMP" "$SRC/lib/ui/screens/hubs/homelab_web_hub_screen.dart"

SRC="$SRC" DEV="$DEV" python3 - <<'PY'
from pathlib import Path
import os

src = Path(os.environ["SRC"])
dev = Path(os.environ["DEV"])


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text()
    if new in text:
        print(f"{label}: already applied")
        return
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"Refusing {label}: expected one anchor, found {count}")
    path.write_text(text.replace(old, new, 1))
    print(f"{label}: applied")


# The staged screen is intentionally self-contained. Keep its fallback surface
# on Flutter's active theme token rather than assuming a Moonfin design token
# that may not exist in every upstream version.
hub = src / "lib/ui/screens/hubs/homelab_web_hub_screen.dart"
hub_text = hub.read_text()
hub_text = hub_text.replace(
    "              AppColorScheme.surface,\n              AppColorScheme.background,",
    "              Theme.of(context).colorScheme.surface,\n              AppColorScheme.background,",
)
hub.write_text(hub_text)

legacy = src / "lib/ui/screens/hubs/homelab_hub_screen.dart"
replace_once(
    legacy,
    "import 'package:flutter/material.dart';\n",
    "import 'package:flutter/foundation.dart' show kIsWeb;\n"
    "import 'package:flutter/material.dart';\n",
    "web hub foundation import",
)
replace_once(
    legacy,
    "import '../../navigation/homelab_hub_routes.dart';\n",
    "import '../../navigation/homelab_hub_routes.dart';\n"
    "import 'homelab_web_hub_screen.dart';\n",
    "premium web hub import",
)
replace_once(
    legacy,
    "  @override\n"
    "  Widget build(BuildContext context) {\n"
    "    final navbarPosition = _prefs.get(UserPreferences.navbarPosition);",
    "  @override\n"
    "  Widget build(BuildContext context) {\n"
    "    if (kIsWeb && !PlatformDetection.useMobileUi) {\n"
    "      return HomelabWebHubScreen(kind: widget.kind.name);\n"
    "    }\n\n"
    "    final navbarPosition = _prefs.get(UserPreferences.navbarPosition);",
    "web-only premium hub routing",
)

view_model = src / "lib/ui/screens/home/home_view_model.dart"
replace_once(
    view_model,
    "  HomeRow? _placeholderForConfig(HomeSectionConfig cfg) {\n"
    "    if (cfg.isPluginDynamic) {",
    "  HomeRow? _placeholderForConfig(HomeSectionConfig cfg) {\n"
    "    // Premium web shelves appear only once content exists. The stock\n"
    "    // placeholder rows reserve a full poster shelf each, which produces\n"
    "    // giant empty gaps on a cold desktop-web load. Mobile/TV keep the\n"
    "    // proven placeholder behaviour.\n"
    "    if (HomelabHomeComposer.enabled) return null;\n\n"
    "    if (cfg.isPluginDynamic) {",
    "compact web cold-loading behaviour",
)

composer = src / "lib/ui/screens/home/homelab_home_composer.dart"
replace_once(
    composer,
    "      HomeSectionType.sinceYouWatched1,\n"
    "      HomeSectionType.sinceYouWatched2,\n"
    "      HomeSectionType.rewatch,",
    "      HomeSectionType.sinceYouWatched1,\n"
    "      HomeSectionType.rewatch,",
    "single Since You Watched baseline",
)

media_bar = src / "lib/ui/widgets/media_bar.dart"
replace_once(
    media_bar,
    "  @override\n"
    "  Widget build(BuildContext context) {\n"
    "    final l10n = AppLocalizations.of(context);\n"
    "    final state = widget.viewModel.state;\n"
    "    final mode = UserPreferences.normalizeMediaBarMode(\n"
    "      widget.prefs.get(UserPreferences.mediaBarMode),\n"
    "    );",
    "  @override\n"
    "  Widget build(BuildContext context) {\n"
    "    final l10n = AppLocalizations.of(context);\n"
    "    final state = widget.viewModel.state;\n"
    "    // The comprehensive web pass uses one cinematic hero language across\n"
    "    // Home, Movies, TV and Anime. Keep every other platform governed by\n"
    "    // its existing Moonbase/user media-bar preference.\n"
    "    final mode = kIsWeb && !PlatformDetection.useMobileUi\n"
    "        ? UserPreferences.mediaBarModeMakd\n"
    "        : UserPreferences.normalizeMediaBarMode(\n"
    "            widget.prefs.get(UserPreferences.mediaBarMode),\n"
    "          );",
    "cinematic desktop-web Home hero",
)

build = dev / "build.sh"
replace_once(
    build,
    "      lib/ui/screens/hubs/homelab_hub_screen.dart \\\n"
    "      lib/ui/widgets/left_sidebar.dart \\\n",
    "      lib/ui/screens/hubs/homelab_hub_screen.dart \\\n"
    "      lib/ui/screens/hubs/homelab_web_hub_screen.dart \\\n"
    "      lib/ui/widgets/left_sidebar.dart \\\n",
    "format premium hub source",
)
replace_once(
    build,
    "      lib/ui/widgets/left_sidebar.dart \\\n"
    "      lib/ui/widgets/top_toolbar.dart\n",
    "      lib/ui/widgets/left_sidebar.dart \\\n"
    "      lib/ui/widgets/media_bar.dart \\\n"
    "      lib/ui/widgets/top_toolbar.dart\n",
    "format shared web hero source",
)
replace_once(
    build,
    "flutter analyze --no-fatal-warnings --no-fatal-infos lib/ui/screens/home",
    "flutter analyze --no-fatal-warnings --no-fatal-infos lib/ui/screens/home lib/ui/screens/hubs lib/ui/widgets/media_bar.dart",
    "targeted full web analysis",
)
replace_once(
    build,
    '  "design": "home-web-comprehensive-v1",',
    '  "design": "web-desktop-comprehensive-v1",',
    "full web manifest marker",
)
PY

chmod +x "$DEV/build.sh"
git -C "$SRC" diff --check

printf '\nFULL WEB-DESKTOP SOURCE APPLIED LOCALLY\n'
printf 'Backup: %s\n' "$BACKUP"
printf 'Persistent source changes:\n'
git -C "$SRC" status --short

LOG="$DEV/logs/web-desktop-v1-$(date +%Y%m%d-%H%M%S).log"
nohup "$DEV/build.sh" >"$LOG" 2>&1 </dev/null &
PID=$!
printf '%s\n' "$PID" > "$DEV/state/build.pid"

printf '\nValidation build started detached.\n'
printf 'PID: %s\n' "$PID"
printf 'Launcher log: %s\n' "$LOG"
printf 'No running Jellyfin/Moonfin frontend was changed.\n'
