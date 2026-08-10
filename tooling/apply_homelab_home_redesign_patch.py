#!/usr/bin/env python3
"""Apply the comprehensive Home Lab web Home redesign.

The redesign is intentionally layered on Moonfin's existing Home implementation:
- Moonbase / HomeSectionConfig remain the data-source infrastructure.
- HomelabHomeComposer supplies an opinionated web-only content hierarchy.
- Existing playback, Seerr routing, focus-return, previews, ratings and theme
  plumbing remain untouched.
- Android/mobile and TV layouts remain on the proven baseline until their later
  responsive/native passes.
"""

from pathlib import Path

HOME_SCREEN = Path("lib/ui/screens/home/home_screen.dart")
HOME_VIEW_MODEL = Path("lib/ui/screens/home/home_view_model.dart")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old == new:
        return text
    if new and new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"Refusing to patch {label}: expected one anchor, found {count}. "
            "Upstream Home structure changed."
        )
    return text.replace(old, new, 1)


def patch_home_view_model() -> None:
    text = HOME_VIEW_MODEL.read_text(encoding="utf-8")

    text = replace_once(
        text,
        "import 'home_view_model.dart';\n" if False else "import '../../../data/models/home_row.dart';\n",
        "import '../../../data/models/home_row.dart';\nimport 'homelab_home_composer.dart';\n",
        "Home composer import",
    )

    old_effective = """      final effectiveConfigs = visibleConfigs
          .where(
            (c) => !(c.isBuiltin && merge && c.type == HomeSectionType.nextUp),
          )
          .toList();
"""
    new_effective = """      final effectiveConfigs = HomelabHomeComposer.augmentConfigs(
        visibleConfigs
            .where(
              (c) => !(c.isBuiltin && merge && c.type == HomeSectionType.nextUp),
            )
            .toList(),
      );
"""
    text = replace_once(
        text,
        old_effective,
        new_effective,
        "Home content composition configs",
    )

    replacements = [
        ("          _rows = cached;\n", "          _rows = HomelabHomeComposer.compose(cached);\n", "cached Home composition"),
        ("        _rows = placeholders;\n", "        _rows = HomelabHomeComposer.compose(placeholders);\n", "placeholder Home composition"),
        ("          _rows = reconciledRows;\n", "          _rows = HomelabHomeComposer.compose(reconciledRows);\n", "reconciled Home composition"),
        ("        _rows = newRows;\n", "        _rows = HomelabHomeComposer.compose(newRows);\n", "loaded Home composition"),
    ]
    for old, new, label in replacements:
        text = replace_once(text, old, new, label)

    HOME_VIEW_MODEL.write_text(text, encoding="utf-8")


def patch_home_screen() -> None:
    text = HOME_SCREEN.read_text(encoding="utf-8")

    # The previous home-web-v1 experiment may already be generated into the
    # branch. Replace that exact spike with the final baseline treatment.
    old_scrim = """class _GradientScrim extends StatelessWidget {
  const _GradientScrim();

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || PlatformDetection.useMobileUi) {
      return RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColorScheme.scrim.withValues(alpha: 0.8),
                AppColorScheme.scrim.withValues(alpha: 0.4),
                AppColorScheme.scrim.withValues(alpha: 0.8),
              ],
              stops: [0.0, 0.3, 1.0],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      );
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColorScheme.scrim.withValues(alpha: 0.34),
                  AppColorScheme.scrim.withValues(alpha: 0.08),
                  AppColorScheme.scrim.withValues(alpha: 0.3),
                  AppColorScheme.scrim.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.28, 0.62, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColorScheme.scrim.withValues(alpha: 0.74),
                  AppColorScheme.scrim.withValues(alpha: 0.18),
                  AppColorScheme.scrim.withValues(alpha: 0.06),
                  AppColorScheme.scrim.withValues(alpha: 0.18),
                ],
                stops: const [0.0, 0.32, 0.68, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}
"""
    # Also support a branch where the old spike has not yet been generated.
    stock_scrim = """class _GradientScrim extends StatelessWidget {
  const _GradientScrim();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColorScheme.scrim.withValues(alpha: 0.8),
              AppColorScheme.scrim.withValues(alpha: 0.4),
              AppColorScheme.scrim.withValues(alpha: 0.8),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}
"""
    new_scrim = """class _GradientScrim extends StatelessWidget {
  const _GradientScrim();

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || PlatformDetection.useMobileUi) {
      return RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColorScheme.scrim.withValues(alpha: 0.8),
                AppColorScheme.scrim.withValues(alpha: 0.4),
                AppColorScheme.scrim.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      );
    }

    // Three restrained layers keep hero copy legible, preserve central
    // artwork, and resolve into the active theme's background. OLED themes
    // therefore reach true black without hard-coding black into other themes.
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColorScheme.scrim.withValues(alpha: 0.28),
                  AppColorScheme.scrim.withValues(alpha: 0.04),
                  AppColorScheme.scrim.withValues(alpha: 0.18),
                  AppColorScheme.background.withValues(alpha: 0.82),
                  AppColorScheme.background,
                ],
                stops: const [0.0, 0.3, 0.58, 0.82, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColorScheme.scrim.withValues(alpha: 0.78),
                  AppColorScheme.scrim.withValues(alpha: 0.36),
                  AppColorScheme.scrim.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.24, 0.52, 0.78],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.28, -0.18),
                radius: 0.86,
                colors: [
                  Colors.transparent,
                  AppColorScheme.scrim.withValues(alpha: 0.12),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}
"""
    if new_scrim not in text:
        anchor = old_scrim if old_scrim in text else stock_scrim
        text = replace_once(text, anchor, new_scrim, "premium Home scrim")

    old_experiment_hero = """    if (!PlatformDetection.useMobileUi) {
      if (kIsWeb) {
        // Keep enough of the first shelf in the initial viewport to make Home
        // feel like a streaming destination rather than a full-screen splash.
        return (screenHeight * 0.72).clamp(520.0, 760.0).toDouble();
      }
      return screenHeight;
    }
"""
    stock_hero = """    if (!PlatformDetection.useMobileUi) {
      return screenHeight;
    }
"""
    new_hero = """    if (!PlatformDetection.useMobileUi) {
      if (kIsWeb) {
        // Responsive cinematic hero: broad displays can show more artwork and
        // still reveal the first shelf; taller desktop windows retain a little
        // more hero presence. This is composition, not a fixed-height splash.
        final aspect = screenWidth / screenHeight;
        final factor = aspect >= 1.75 ? 0.66 : (aspect >= 1.45 ? 0.7 : 0.74);
        return (screenHeight * factor).clamp(500.0, 780.0).toDouble();
      }
      return screenHeight;
    }
"""
    if new_hero not in text:
        anchor = old_experiment_hero if old_experiment_hero in text else stock_hero
        text = replace_once(text, anchor, new_hero, "responsive web hero")

    # Web gets the existing modern V2 poster -> landscape focus treatment,
    # metadata expansion, ratings and preview behaviour. Other platforms keep
    # their saved setting until the later responsive/native pass.
    old_v2 = """  bool _isHomeRowsStyleV2() {
    return widget.prefs.get(UserPreferences.homeRowsStyle) == HomeRowsStyle.v2;
  }
"""
    new_v2 = """  bool _isHomeRowsStyleV2() {
    if (kIsWeb && !PlatformDetection.useMobileUi) return true;
    return widget.prefs.get(UserPreferences.homeRowsStyle) == HomeRowsStyle.v2;
  }
"""
    text = replace_once(text, old_v2, new_v2, "premium web card system")

    # The experiment already introduced source-label cleanup and stronger row
    # headings. Apply them only if they are not generated yet.
    old_provenance = """    if (row.id.startsWith('seerr_')) return l10n.seerrDiscoveryRows;
    if (row.id.startsWith('tmdb_')) return 'TMDB Lists';
    if (row.id.startsWith('imdb_')) return 'IMDb List';
"""
    new_provenance = """    final premiumWeb = kIsWeb && !PlatformDetection.useMobileUi;
    if (!premiumWeb && row.id.startsWith('seerr_')) {
      return l10n.seerrDiscoveryRows;
    }
    if (!premiumWeb && row.id.startsWith('tmdb_')) return 'TMDB Lists';
    if (!premiumWeb && row.id.startsWith('imdb_')) return 'IMDb List';
"""
    text = replace_once(
        text,
        old_provenance,
        new_provenance,
        "consumer-facing row labels",
    )

    old_header_start = """  }) {
    final isRowsV2 = _isHomeRowsStyleV2();
    final showHeaderControls =
        hasItems && PlatformDetection.useDesktopUi && !PlatformDetection.isTV;
"""
    new_header_start = """  }) {
    final isRowsV2 = _isHomeRowsStyleV2();
    final premiumWeb = kIsWeb && !PlatformDetection.useMobileUi;
    final showHeaderControls =
        hasItems && PlatformDetection.useDesktopUi && !PlatformDetection.isTV;
"""
    text = replace_once(
        text,
        old_header_start,
        new_header_start,
        "premium row heading mode",
    )

    old_header_padding = """            padding: EdgeInsets.fromLTRB(
              _kHomeRowLabelInset,
              isRowsV2 ? 6 : 16,
              8,
              isRowsV2 ? 1 : 8,
            ),
"""
    new_header_padding = """            padding: EdgeInsets.fromLTRB(
              _kHomeRowLabelInset,
              premiumWeb ? 18 : (isRowsV2 ? 6 : 16),
              8,
              premiumWeb ? 8 : (isRowsV2 ? 1 : 8),
            ),
"""
    text = replace_once(
        text,
        old_header_padding,
        new_header_padding,
        "premium shelf rhythm",
    )

    old_title_style = """                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
"""
    new_title_style = """                        style: (premiumWeb
                                ? Theme.of(context).textTheme.titleLarge
                                : Theme.of(context).textTheme.titleMedium)
                            ?.copyWith(
                              color: AppColorScheme.onSurface,
                              fontWeight: premiumWeb
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              letterSpacing: premiumWeb ? -0.35 : null,
                            ),
"""
    text = replace_once(
        text,
        old_title_style,
        new_title_style,
        "premium shelf typography",
    )

    # If the experiment is already generated, refine its 14/7 spacing to the
    # final 18/8 rhythm without depending on the stock anchor above.
    text = text.replace(
        "premiumWeb ? 14 : (isRowsV2 ? 6 : 16)",
        "premiumWeb ? 18 : (isRowsV2 ? 6 : 16)",
    ).replace(
        "premiumWeb ? 7 : (isRowsV2 ? 1 : 8)",
        "premiumWeb ? 8 : (isRowsV2 ? 1 : 8)",
    ).replace(
        "letterSpacing: premiumWeb ? -0.25 : null",
        "letterSpacing: premiumWeb ? -0.35 : null",
    )

    # Medium web posters create a denser catalogue than the giant TV-style
    # cards while leaving enough room for V2's landscape expansion on hover.
    old_poster = """    final posterSize =
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
    count = text.count(old_poster)
    if count:
        text = text.replace(old_poster, new_poster)

    HOME_SCREEN.write_text(text, encoding="utf-8")


def main() -> None:
    patch_home_view_model()
    patch_home_screen()
    print("Home Lab comprehensive web Home redesign patch applied.")


if __name__ == "__main__":
    main()
