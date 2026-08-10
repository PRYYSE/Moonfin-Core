#!/usr/bin/env python3
"""Apply the Home Lab desktop-web visual system after the structural Home patch.

This file intentionally owns presentation only. It makes the desktop web Home
look coherent regardless of old prototype preferences while leaving mobile,
Android and TV behaviour alone for their later dedicated passes.
"""

from pathlib import Path

HOME_SCREEN = Path("lib/ui/screens/home/home_screen.dart")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"Refusing to patch {label}: expected one anchor, found {count}."
        )
    return text.replace(old, new, 1)


def replace_optional_once(text: str, old: str, new: str, label: str) -> str:
    """Apply a cosmetic cleanup when its exact source shape is available.

    Optional presentation-only edits must not block source consolidation merely
    because upstream/Dart formatting changed. Ambiguous multiple matches remain
    fatal because modifying the wrong location would be unsafe.
    """
    if new in text:
        return text
    count = text.count(old)
    if count == 0:
        print(f"Skipping optional {label}: source anchor not present.")
        return text
    if count != 1:
        raise SystemExit(
            f"Refusing optional {label}: expected at most one anchor, found {count}."
        )
    return text.replace(old, new, 1)


def main() -> None:
    text = HOME_SCREEN.read_text(encoding="utf-8")

    # The comprehensive desktop-web baseline owns its hero presentation rather
    # than inheriting the old compact banner experiment. MediaBar still owns
    # all item rotation, actions, playback routing and focus behaviour.
    old_banner = """  bool _isBannerMode() {
    final mode = UserPreferences.normalizeMediaBarMode(
      widget.prefs.get(UserPreferences.mediaBarMode),
    );
    return mode == UserPreferences.mediaBarModeBanner;
  }
"""
    new_banner = """  bool _isBannerMode() {
    if (kIsWeb && !PlatformDetection.useMobileUi) return false;
    final mode = UserPreferences.normalizeMediaBarMode(
      widget.prefs.get(UserPreferences.mediaBarMode),
    );
    return mode == UserPreferences.mediaBarModeBanner;
  }
"""
    text = replace_once(text, old_banner, new_banner, "desktop cinematic hero mode")

    # Make row geometry use the same modern-card decision as the renderer.
    # Deliberately target only row-specific checks. Do not replace the helper's
    # own preference fallback or it would recurse on non-web platforms.
    direct_v2_patterns = [
        "prefs.get(UserPreferences.homeRowsStyle) == HomeRowsStyle.v2 &&\n          !isSeerrRowOverride",
        "prefs.get(UserPreferences.homeRowsStyle) == HomeRowsStyle.v2 &&\n          !_isSeerrFilterRow(row)",
        "widget.prefs.get(UserPreferences.homeRowsStyle) == HomeRowsStyle.v2 &&\n        !_isSeerrFilterRow(row)",
    ]
    replacements = [
        "_isHomeRowsStyleV2() &&\n          !isSeerrRowOverride",
        "_isHomeRowsStyleV2() &&\n          !_isSeerrFilterRow(row)",
        "_isHomeRowsStyleV2() &&\n        !_isSeerrFilterRow(row)",
    ]
    for old, new in zip(direct_v2_patterns, replacements):
        text = text.replace(old, new)

    # Old preference-sized cards are too inconsistent for judging the first
    # visual baseline. Use one deliberate desktop density while keeping every
    # other platform preference-driven.
    old_poster_multiline = """    final posterSize =
        (_isHomeRowsStyleV2() &&
            !prefs.containsPreference(UserPreferences.posterSize))
        ? PosterSize.small
        : prefs.get(UserPreferences.posterSize);
"""
    new_poster = """    final posterSize = kIsWeb && !PlatformDetection.useMobileUi
        ? PosterSize.medium
        : (_isHomeRowsStyleV2() &&
              !prefs.containsPreference(UserPreferences.posterSize))
        ? PosterSize.small
        : prefs.get(UserPreferences.posterSize);
"""
    text = text.replace(old_poster_multiline, new_poster)

    old_poster_compact = """    final posterSize = (_isHomeRowsStyleV2() && !prefs.containsPreference(UserPreferences.posterSize))
        ? PosterSize.small
        : prefs.get(UserPreferences.posterSize);
"""
    text = text.replace(old_poster_compact, new_poster)

    # Slightly wider desktop gutters improve hierarchy and keep focused cards
    # away from the browser edge without wasting catalogue width.
    old_row_inset = """    final rowLeftInset =
        (navbarIsLeft && !PlatformDetection.useMobileUi
            ? 56.0
            : tvTopNavbarInset) +
        (!PlatformDetection.useMobileUi ? 16.0 : 0.0);
"""
    new_row_inset = """    final rowLeftInset =
        (navbarIsLeft && !PlatformDetection.useMobileUi
            ? 56.0
            : tvTopNavbarInset) +
        (!PlatformDetection.useMobileUi ? (kIsWeb ? 28.0 : 16.0) : 0.0);
"""
    text = replace_once(text, old_row_inset, new_row_inset, "desktop row gutter")

    # Consumer Home shelves should be titled by intent, not by their backing
    # API. This cleanup is deliberately optional during one-time consolidation:
    # source provenance remains harmless if upstream formatting no longer
    # exposes this exact block, and it can be consolidated directly later.
    old_custom_provenance = """    final config = widget.prefs.homeSectionsConfig.firstWhereOrNull(
      (c) => c.stableId == row.id,
    );
    if (config != null &&
        config.pluginSource == HomeSectionPluginSource.custom) {
"""
    new_custom_provenance = """    final config = widget.prefs.homeSectionsConfig.firstWhereOrNull(
      (c) => c.stableId == row.id,
    );
    if (config != null &&
        config.pluginSource == HomeSectionPluginSource.custom) {
      if (premiumWeb) return null;
"""
    text = replace_optional_once(
        text,
        old_custom_provenance,
        new_custom_provenance,
        "custom row provenance cleanup",
    )

    # Modern streaming UIs react quickly enough to feel intentional but not so
    # quickly that simply crossing a card starts video. Web remains muted until
    # the existing user-gesture logic allows audio.
    text = text.replace(
        "static const _previewStartDelay = Duration(milliseconds: 1200);",
        "static const _previewStartDelay = Duration(milliseconds: 850);",
    )

    # A restrained Ken Burns-style movement gives the hero/backdrop some life.
    # It is web-only and tiny enough to avoid visible cropping or motion fatigue.
    old_backdrop = """          if (!useMakdBackdropFx) {
            return image;
          }

          return ClipRect(
"""
    new_backdrop = """          if (!useMakdBackdropFx) {
            if (kIsWeb && !PlatformDetection.useMobileUi) {
              return ClipRect(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('homelab_web_backdrop_$imageUrl'),
                  tween: Tween(begin: 1.0, end: 1.025),
                  duration: const Duration(seconds: 14),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: child,
                  ),
                  child: image,
                ),
              );
            }
            return image;
          }

          return ClipRect(
"""
    text = replace_once(text, old_backdrop, new_backdrop, "subtle web backdrop motion")

    HOME_SCREEN.write_text(text, encoding="utf-8")
    print("Home Lab comprehensive web visual polish applied.")


if __name__ == "__main__":
    main()
