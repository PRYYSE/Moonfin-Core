#!/usr/bin/env python3
"""Apply the Home Lab web-first Home visual redesign.

This intentionally limits the first redesign pass to desktop web presentation.
It does not alter Home data loading, Seerr routing, playback, focus/return
behaviour, Android/mobile sizing, or TV layout behaviour.
"""

from pathlib import Path

HOME_SCREEN = Path("lib/ui/screens/home/home_screen.dart")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"Refusing to patch {label}: expected one anchor, found {count}. "
            "Upstream Home structure changed."
        )
    return text.replace(old, new, 1)


def patch_home_screen() -> None:
    text = HOME_SCREEN.read_text(encoding="utf-8")

    old_scrim = """class _GradientScrim extends StatelessWidget {
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
    text = replace_once(text, old_scrim, new_scrim, "web cinematic scrim")

    old_desktop_hero = """    if (!PlatformDetection.useMobileUi) {
      return screenHeight;
    }
"""
    new_desktop_hero = """    if (!PlatformDetection.useMobileUi) {
      if (kIsWeb) {
        // Keep enough of the first shelf in the initial viewport to make Home
        // feel like a streaming destination rather than a full-screen splash.
        return (screenHeight * 0.72).clamp(520.0, 760.0).toDouble();
      }
      return screenHeight;
    }
"""
    text = replace_once(
        text,
        old_desktop_hero,
        new_desktop_hero,
        "web hero height",
    )

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
        "web row provenance cleanup",
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
        "web row heading mode",
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
              premiumWeb ? 14 : (isRowsV2 ? 6 : 16),
              8,
              premiumWeb ? 7 : (isRowsV2 ? 1 : 8),
            ),
"""
    text = replace_once(
        text,
        old_header_padding,
        new_header_padding,
        "web row heading spacing",
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
                              letterSpacing: premiumWeb ? -0.25 : null,
                            ),
"""
    text = replace_once(
        text,
        old_title_style,
        new_title_style,
        "web row heading typography",
    )

    HOME_SCREEN.write_text(text, encoding="utf-8")


def main() -> None:
    patch_home_screen()
    print("Home Lab web Home redesign patch applied.")


if __name__ == "__main__":
    main()
